import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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
}
