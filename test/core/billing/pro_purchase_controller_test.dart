import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:takt_desk/core/billing/pro_purchase_controller.dart';
import 'package:takt_desk/core/billing/pro_store.dart';

/// What Play's restorePurchases delivers: status `restored` whatever the real
/// purchase state is.
GooglePlayPurchaseDetails _playRestored(PurchaseStateWrapper state) {
  return GooglePlayPurchaseDetails.fromPurchase(PurchaseWrapper(
    orderId: 'GPA.2',
    packageName: 'com.zykl.app',
    purchaseTime: 0,
    purchaseToken: 'token',
    signature: '',
    products: const [kStudioProProductId],
    isAutoRenewing: false,
    originalJson: '{}',
    isAcknowledged: false,
    purchaseState: state,
  )).single
    ..status = PurchaseStatus.restored;
}

class _FakeStore implements ProStore {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  bool ownedOnRestore = false;
  bool genuine = true;
  int buys = 0;
  final completed = <String>[];

  final product = ProductDetails(
    id: kStudioProProductId,
    title: 'Studio PRO',
    description: '',
    price: 'Rp 69.000',
    rawPrice: 69000,
    currencyCode: 'IDR',
  );

  PurchaseDetails purchase(PurchaseStatus status, {bool pendingComplete = true}) {
    return PurchaseDetails(
      productID: kStudioProProductId,
      purchaseID: 'GPA.1',
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'test'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = pendingComplete;
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetails?> queryProduct(String productId) async => product;
  @override
  Future<bool> buy(ProductDetails product) async {
    buys++;
    return true;
  }

  @override
  Future<void> restore() async {
    if (ownedOnRestore) controller.add([purchase(PurchaseStatus.restored, pendingComplete: false)]);
  }

  @override
  Future<void> complete(PurchaseDetails purchase) async => completed.add(purchase.status.name);

  @override
  Future<bool> verify(PurchaseDetails purchase) async => genuine;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeStore store;
  late List<bool> entitlements;
  late ProPurchaseController controller;

  setUp(() {
    store = _FakeStore();
    entitlements = [];
    controller = ProPurchaseController(store, (owned) async => entitlements.add(owned));
  });

  tearDown(() => controller.dispose());

  test('loads the Play price and stays locked when nothing is owned', () async {
    await controller.init();
    await _settle();
    expect(controller.state.status, ProPurchaseStatus.idle);
    expect(controller.state.price, 'Rp 69.000');
    expect(entitlements, isEmpty);
  });

  test('restores ownership at launch', () async {
    store.ownedOnRestore = true;
    await controller.init();
    await _settle();
    expect(controller.state.isOwned, isTrue);
    expect(entitlements, [true]);
  });

  test('a successful purchase unlocks and is acknowledged', () async {
    await controller.init();
    await controller.buy();
    expect(controller.state.status, ProPurchaseStatus.purchasing);
    store.controller.add([store.purchase(PurchaseStatus.purchased)]);
    await _settle();
    expect(controller.state.isOwned, isTrue);
    expect(entitlements, [true]);
    expect(store.completed, ['purchased']);
  });

  test('a purchase Google Play did not sign does not unlock (still acknowledged)', () async {
    store.genuine = false;
    await controller.init();
    await controller.buy();
    store.controller.add([store.purchase(PurchaseStatus.purchased)]);
    await _settle();
    expect(controller.state.isOwned, isFalse);
    expect(controller.state.message, contains('could not confirm'));
    expect(entitlements, isEmpty);
    expect(store.completed, ['purchased'], reason: 'a real purchase that failed the check must not be refunded');
  });

  group('verifyPlayPurchase', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('test/billing');
    final calls = <MethodCall>[];
    bool nativeAnswer = true;
    setUp(() {
      calls.clear();
      nativeAnswer = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
        calls.add(c);
        return nativeAnswer;
      });
    });

    GooglePlayPurchaseDetails signed(String json) => GooglePlayPurchaseDetails.fromPurchase(PurchaseWrapper(
          orderId: 'GPA.3',
          packageName: 'com.zykl.app',
          purchaseTime: 0,
          purchaseToken: 'token',
          signature: 'c2ln',
          products: const [kStudioProProductId],
          isAutoRenewing: false,
          originalJson: json,
          isAcknowledged: true,
          purchaseState: PurchaseStateWrapper.purchased,
        )).single;

    const proJson = '{"packageName":"com.zykl.app","productId":"studio_pro_lifetime","purchaseState":0}';

    test('asks native to check the signature of the signed JSON', () async {
      expect(await verifyPlayPurchase(signed(proJson), channel: channel), isTrue);
      expect(calls.single.arguments, {'signedData': proJson, 'signature': 'c2ln'});
      nativeAnswer = false;
      expect(await verifyPlayPurchase(signed(proJson), channel: channel), isFalse);
    });

    test('a signed purchase of another app or product never counts', () async {
      expect(await verifyPlayPurchase(signed('{"packageName":"com.other","productId":"studio_pro_lifetime"}'), channel: channel),
          isFalse);
      expect(await verifyPlayPurchase(signed('{"packageName":"com.zykl.app","productId":"coins"}'), channel: channel), isFalse);
      expect(await verifyPlayPurchase(signed('not json'), channel: channel), isFalse);
      expect(calls, isEmpty);
      expect(isStudioProPurchaseJson('{"packageName":"com.zykl.app","productIds":["studio_pro_lifetime"]}'), isTrue);
    });

    test('a purchase that is not from Google Play is not trusted', () async {
      final fake = PurchaseDetails(
        productID: kStudioProProductId,
        verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'x'),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      );
      expect(await verifyPlayPurchase(fake, channel: channel), isFalse);
    });
  });

  test('pending cash payment does not unlock until confirmed', () async {
    await controller.init();
    await controller.buy();
    store.controller.add([store.purchase(PurchaseStatus.pending, pendingComplete: false)]);
    await _settle();
    expect(controller.state.status, ProPurchaseStatus.pending);
    expect(entitlements, isEmpty);
    await controller.buy(); // busy: ignored
    expect(store.buys, 1);
  });

  test('an unpaid delayed payment restored at launch stays locked and is not acknowledged', () async {
    await controller.init();
    store.controller.add([_playRestored(PurchaseStateWrapper.pending)]);
    await _settle();
    expect(controller.state.status, ProPurchaseStatus.pending);
    expect(entitlements, isEmpty);
    expect(store.completed, isEmpty);
  });

  test('a paid Play purchase restored at launch unlocks and is acknowledged', () async {
    await controller.init();
    store.controller.add([_playRestored(PurchaseStateWrapper.purchased)]);
    await _settle();
    expect(controller.state.isOwned, isTrue);
    expect(entitlements, [true]);
    expect(store.completed, ['restored']);
  });

  test('cancel returns to idle without unlocking', () async {
    await controller.init();
    await controller.buy();
    store.controller.add([store.purchase(PurchaseStatus.canceled, pendingComplete: false)]);
    await _settle();
    expect(controller.state.status, ProPurchaseStatus.idle);
    expect(entitlements, isEmpty);
  });

  PurchaseDetails productless(PurchaseStatus status, {String? errorMessage}) {
    // What in_app_purchase_android sends when the purchase flow ends without a purchase.
    return PurchaseDetails(
      productID: '',
      purchaseID: '',
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'test'),
      transactionDate: null,
      status: status,
    )..error = errorMessage == null
        ? null
        : IAPError(source: 'google_play', code: 'purchase_error', message: errorMessage);
  }

  test('a cancel reported without a product (real Play) returns to idle', () async {
    await controller.init();
    await controller.buy();
    expect(controller.state.isBusy, isTrue);
    store.controller.add([productless(PurchaseStatus.canceled)]);
    await _settle();
    expect(controller.state.status, ProPurchaseStatus.idle);
    expect(controller.state.isBusy, isFalse);
  });

  test('a failed purchase without a product returns to idle with a message', () async {
    await controller.init();
    await controller.buy();
    store.controller.add([productless(PurchaseStatus.error, errorMessage: 'BillingResponse.error')]);
    await _settle();
    expect(controller.state.status, ProPurchaseStatus.idle);
    expect(controller.state.message, 'The payment did not go through.');
  });

  test('"already owned" restores the purchase instead of failing', () async {
    store.ownedOnRestore = true;
    await controller.init();
    await controller.buy();
    store.controller.add([productless(PurchaseStatus.error, errorMessage: 'BillingResponse.itemAlreadyOwned')]);
    await _settle();
    await _settle();
    expect(controller.state.isOwned, isTrue);
    expect(entitlements, [true]);
  });

  test('store unavailable shows a message on buy', () async {
    store.available = false;
    await controller.init();
    await controller.buy();
    expect(controller.state.status, ProPurchaseStatus.unavailable);
    expect(controller.state.message, isNotNull);
    expect(store.buys, 0);
  });

  test('simulation builds never touch the store', () async {
    final sim = ProPurchaseController(null, (owned) async => entitlements.add(owned));
    await sim.init();
    await sim.buy();
    expect(sim.state.status, ProPurchaseStatus.unavailable);
    sim.dispose();
  });

  group('restore feedback and resume recheck', () {
    late _FakeStore s;
    late List<bool> owned;
    late ProPurchaseController c;

    setUp(() {
      s = _FakeStore();
      owned = [];
      c = ProPurchaseController(s, (o) async => owned.add(o),
          restoreSettle: Duration.zero, resumeRetryEvery: const Duration(minutes: 5));
    });

    tearDown(() => c.dispose());

    test('RESTORE says so when Play has no purchase for this account', () async {
      await c.init();
      await c.restore();
      expect(c.state.isOwned, isFalse);
      expect(c.state.message, 'No Studio PRO purchase found on this Google account.');
    });

    test('RESTORE that finds the purchase unlocks without the "not found" message', () async {
      s.ownedOnRestore = true;
      await c.init();
      await c.restore();
      expect(c.state.isOwned, isTrue);
      expect(c.state.message, isNull);
    });

    test('Play unreachable at launch: coming back to the app retries and unlocks a paid purchase', () async {
      s.available = false;
      await c.init();
      expect(c.state.status, ProPurchaseStatus.unavailable);
      s.available = true;
      s.ownedOnRestore = true;
      await c.recheckOnResume();
      await _settle();
      expect(c.state.isOwned, isTrue);
      expect(owned, [true]);
    });

    test('the resume recheck is throttled', () async {
      s.available = false;
      await c.init();
      await c.recheckOnResume();
      s.available = true;
      await c.recheckOnResume(); // within 5 minutes: skipped
      expect(c.state.status, ProPurchaseStatus.unavailable);
    });
  });
}
