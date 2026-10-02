import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:takt_desk/core/billing/pro_purchase_controller.dart';
import 'package:takt_desk/core/billing/pro_store.dart';

class _FakeStore implements ProStore {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  bool ownedOnRestore = false;
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

  test('cancel returns to idle without unlocking', () async {
    await controller.init();
    await controller.buy();
    store.controller.add([store.purchase(PurchaseStatus.canceled, pendingComplete: false)]);
    await _settle();
    expect(controller.state.status, ProPurchaseStatus.idle);
    expect(entitlements, isEmpty);
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
}
