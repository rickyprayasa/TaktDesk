import 'dart:convert';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'play_signature.dart';

/// Google Play one-time product for Studio PRO. Must match the Product ID
/// created in Play Console (Monetize with Play > Products > One-time products).
/// Play never lets an ID be reused, so never rename it.
const String kStudioProProductId = 'studio_pro_lifetime';

/// Whether Google has actually been paid for [purchase].
///
/// `restorePurchases` re-delivers every purchase Play knows with status
/// `restored`, including PENDING ones (e.g. Indomaret/Alfamart cash not paid
/// yet), so the status alone must never unlock PRO. Non-Play purchases (tests,
/// other stores) carry no such state and count as paid.
bool isPaidPurchase(PurchaseDetails purchase) {
  if (purchase is GooglePlayPurchaseDetails) {
    return purchase.billingClientPurchase.purchaseState == PurchaseStateWrapper.purchased;
  }
  return true;
}

/// Thin seam over the store so the purchase logic can be unit-tested
/// without Google Play.
abstract class ProStore {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetails?> queryProduct(String productId);
  Future<bool> buy(ProductDetails product);

  /// Re-delivers owned purchases through [purchaseStream] (status `restored`).
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);

  /// Whether [purchase] really comes from the store (Google Play's signature), so a faked "purchased" answer
  /// doesn't unlock PRO.
  Future<bool> verify(PurchaseDetails purchase);
}

/// The signed JSON must also be about this app and Studio PRO (a signature alone says nothing about which product).
bool isStudioProPurchaseJson(String json) {
  try {
    final data = jsonDecode(json);
    if (data is! Map || data['packageName'] != 'com.zykl.app') return false;
    final ids = data['productIds'];
    return data['productId'] == kStudioProProductId || (ids is List && ids.contains(kStudioProProductId));
  } catch (_) {
    return false;
  }
}

/// Google Play signed [purchase] with ZYKL's key (checked in Dart, see [PlaySignature]) and it is Studio PRO.
bool verifyPlayPurchase(PurchaseDetails purchase, {PlaySignature? key}) {
  if (purchase is! GooglePlayPurchaseDetails) return false;
  final signed = purchase.billingClientPurchase;
  if (!isStudioProPurchaseJson(signed.originalJson)) return false;
  try {
    return (key ?? PlaySignature.zykl).verify(signed.originalJson, signed.signature);
  } catch (_) {
    return false;
  }
}

class PlayProStore implements ProStore {
  final InAppPurchase _iap;

  PlayProStore([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetails?> queryProduct(String productId) async {
    final res = await _iap.queryProductDetails({productId});
    return res.productDetails.isEmpty ? null : res.productDetails.first;
  }

  @override
  Future<bool> buy(ProductDetails product) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> complete(PurchaseDetails purchase) => _iap.completePurchase(purchase);

  @override
  Future<bool> verify(PurchaseDetails purchase) async => verifyPlayPurchase(purchase);
}
