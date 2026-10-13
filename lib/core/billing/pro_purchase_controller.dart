import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../config/app_security_config.dart';
import 'pro_store.dart';

enum ProPurchaseStatus {
  /// Store not queried yet or not reachable (no Play Store, offline, emulator).
  unavailable,
  idle,

  /// Google Play purchase sheet is open.
  purchasing,

  /// Paid by a delayed method (e.g. Indomaret/Alfamart cash): unlocks when
  /// Google confirms, possibly after the app was closed.
  pending,
  owned,
}

@immutable
class ProPurchaseState {
  final ProPurchaseStatus status;

  /// Localised price from Google Play (e.g. "Rp 69.000"), null until loaded.
  final String? price;

  /// Last user-facing problem (purchase failed, store unreachable).
  final String? message;

  const ProPurchaseState({
    this.status = ProPurchaseStatus.unavailable,
    this.price,
    this.message,
  });

  bool get isOwned => status == ProPurchaseStatus.owned;
  bool get isBusy => status == ProPurchaseStatus.purchasing || status == ProPurchaseStatus.pending;

  ProPurchaseState copyWith({ProPurchaseStatus? status, String? price, String? message, bool clearMessage = false}) {
    return ProPurchaseState(
      status: status ?? this.status,
      price: price ?? this.price,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Studio PRO ownership, verified with Google Play on every launch.
///
/// Ownership is not trusted from local storage: release builds start locked
/// (see `DeskPreferencesController.init`) and unlock only when Play reports
/// the purchase (`restored` at launch or `purchased` after buying). Play
/// caches owned purchases on the device, so this also works offline. A
/// refunded purchase simply stops being restored.
///
/// In simulation builds (`ENABLE_PRO_SIMULATION`, debug) the store is never
/// touched and the developer switch keeps controlling PRO.
class ProPurchaseController extends StateNotifier<ProPurchaseState> {
  final ProStore? _store;
  final Future<void> Function(bool owned) _onEntitlement;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  ProPurchaseController(
    this._store,
    this._onEntitlement, {
    this.restoreSettle = const Duration(milliseconds: 800),
    this.resumeRetryEvery = const Duration(minutes: 5),
  }) : super(const ProPurchaseState());

  /// How long a user-asked restore waits for Play's answer before saying nothing was found.
  final Duration restoreSettle;

  /// At most one silent ownership check per this interval when the app comes back to the foreground.
  final Duration resumeRetryEvery;
  DateTime? _lastResumeCheck;

  Future<void> init() async {
    final store = _store;
    if (store == null) return;
    _sub = store.purchaseStream.listen(_onPurchases, onError: (Object e) {
      debugPrint('ZYKL billing: purchase stream error: $e');
    });
    await _connect();
  }

  /// Availability, product and a silent restore: at launch, and again when Play was unreachable then.
  Future<void> _connect() async {
    final store = _store;
    if (store == null) return;
    try {
      if (!await store.isAvailable()) {
        if (mounted) state = state.copyWith(status: ProPurchaseStatus.unavailable);
        return;
      }
      _product = await store.queryProduct(kStudioProProductId);
      if (!mounted) return;
      state = state.copyWith(
        status: state.isOwned ? ProPurchaseStatus.owned : ProPurchaseStatus.idle,
        price: _product?.price,
      );
      await store.restore();
    } catch (e) {
      debugPrint('ZYKL billing: init failed: $e');
      if (mounted) state = state.copyWith(status: ProPurchaseStatus.unavailable);
    }
  }

  /// Opens the Google Play purchase sheet. The result arrives via the stream.
  Future<void> buy() async {
    final store = _store;
    final product = _product;
    if (store == null || state.isOwned || state.isBusy) return;
    if (product == null) {
      state = state.copyWith(
        message: 'Google Play is not reachable right now. Check your connection and try again.',
      );
      return;
    }
    state = state.copyWith(status: ProPurchaseStatus.purchasing, clearMessage: true);
    try {
      final started = await store.buy(product);
      if (!started && mounted && state.status == ProPurchaseStatus.purchasing) {
        state = state.copyWith(status: ProPurchaseStatus.idle);
      }
    } catch (e) {
      debugPrint('ZYKL billing: buy failed: $e');
      if (mounted) {
        state = state.copyWith(status: ProPurchaseStatus.idle, message: 'The purchase could not be started.');
      }
    }
  }

  /// "Restore purchase": asks Play again (new phone, reinstall). Says so when Play has no purchase for this account.
  Future<void> restore() async {
    final store = _store;
    if (store == null) return;
    state = state.copyWith(clearMessage: true);
    try {
      await store.restore();
    } catch (e) {
      debugPrint('ZYKL billing: restore failed: $e');
      if (mounted) state = state.copyWith(message: 'Google Play is not reachable right now.');
      return;
    }
    await Future<void>.delayed(restoreSettle);
    if (mounted && !state.isOwned && state.status != ProPurchaseStatus.pending && state.message == null) {
      state = state.copyWith(message: 'No Studio PRO purchase found on this Google account.');
    }
  }

  /// Back in the foreground and not PRO: check again quietly (Play unreachable at launch, a purchase made on
  /// another device, a pending payment that cleared). Throttled.
  Future<void> recheckOnResume() async {
    final store = _store;
    if (store == null || !mounted || state.isOwned || state.status == ProPurchaseStatus.purchasing) return;
    final now = DateTime.now();
    final last = _lastResumeCheck;
    if (last != null && now.difference(last) < resumeRetryEvery) return;
    _lastResumeCheck = now;
    if (state.status == ProPurchaseStatus.unavailable) {
      await _connect();
      return;
    }
    try {
      await store.restore();
    } catch (e) {
      debugPrint('ZYKL billing: resume check failed: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID.isEmpty) {
        // in_app_purchase_android reports a cancelled, failed or "already owned" purchase flow with no product at
        // all; skipping it left the dialog stuck in `purchasing` with BUY and RESTORE disabled.
        _onFlowEndedWithoutPurchase(p);
        continue;
      }
      if (p.productID != kStudioProProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!isPaidPurchase(p)) {
            // An unpaid delayed payment comes back as `restored` at launch.
            // Stay pending (and don't acknowledge: Play rejects that for a
            // pending order) until Google reports it paid.
            if (mounted) state = state.copyWith(status: ProPurchaseStatus.pending, clearMessage: true);
            continue;
          }
          if (mounted) state = state.copyWith(status: ProPurchaseStatus.owned, clearMessage: true);
          await _onEntitlement(true);
        case PurchaseStatus.pending:
          if (mounted) state = state.copyWith(status: ProPurchaseStatus.pending, clearMessage: true);
        case PurchaseStatus.error:
          debugPrint('ZYKL billing: purchase error: ${p.error}');
          if (mounted) {
            state = state.copyWith(status: ProPurchaseStatus.idle, message: 'The payment did not go through.');
          }
        case PurchaseStatus.canceled:
          if (mounted) state = state.copyWith(status: ProPurchaseStatus.idle);
      }
      // Acknowledge, or Google refunds the order after 3 days.
      if (p.pendingCompletePurchase) {
        try {
          await _store?.complete(p);
        } catch (e) {
          debugPrint('ZYKL billing: completePurchase failed: $e');
        }
      }
    }
  }

  void _onFlowEndedWithoutPurchase(PurchaseDetails p) {
    if (!mounted || state.status != ProPurchaseStatus.purchasing) return;
    if (p.status == PurchaseStatus.canceled) {
      state = state.copyWith(status: ProPurchaseStatus.idle);
      return;
    }
    if ((p.error?.message ?? '').contains('itemAlreadyOwned')) {
      // Bought before (other phone, reinstall): fetch it instead of failing.
      state = state.copyWith(status: ProPurchaseStatus.idle, message: 'You already own Studio PRO. Restoring it…');
      restore();
      return;
    }
    debugPrint('ZYKL billing: purchase flow ended without a purchase: ${p.status} ${p.error}');
    state = state.copyWith(status: ProPurchaseStatus.idle, message: 'The payment did not go through.');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final proStoreProvider = Provider<ProStore?>((ref) {
  return AppSecurityConfig.isProSimulationEnabled ? null : PlayProStore();
});

final proPurchaseProvider = StateNotifierProvider<ProPurchaseController, ProPurchaseState>((ref) {
  final prefs = ref.watch(deskPreferencesControllerProvider.notifier);
  final controller = ProPurchaseController(ref.watch(proStoreProvider), (owned) async {
    // Saved preferences start release builds locked; apply after they load
    // so that load can't overwrite the unlock.
    await prefs.ready.catchError((_) {});
    if (owned && !ref.read(deskPreferencesControllerProvider).isProSimulated) {
      await prefs.setProSimulated(true);
    }
  });
  controller.init();
  try {
    final lifecycle = AppLifecycleListener(onResume: controller.recheckOnResume);
    ref.onDispose(lifecycle.dispose);
  } catch (_) {
    // No widgets binding (plain unit tests).
  }
  return controller;
});
