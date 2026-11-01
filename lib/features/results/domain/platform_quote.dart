import '../../cart/domain/cart_item.dart';
import '../../coupons/domain/coupon_engine.dart';
import '../../pricing/domain/pharmacy_platform.dart';

/// Price of one cart line on one platform.
class QuoteLine {
  const QuoteLine({required this.item, required this.unitPrice});

  final CartItem item;

  /// Null when the platform doesn't sell this medicine.
  final double? unitPrice;

  bool get available => unitPrice != null;
  double get lineTotal => (unitPrice ?? 0) * item.quantity;
}

/// The full bill for the cart on one platform.
class PlatformQuote {
  const PlatformQuote({
    required this.platform,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.bestCoupon,
    required this.coupons,
    required this.isFirstOrder,
  });

  final PharmacyPlatform platform;
  final List<QuoteLine> lines;

  /// Sum of available lines (before delivery and coupon).
  final double subtotal;
  final double deliveryFee;

  /// The coupon applied (best eligible one), or null.
  final CouponEvaluation? bestCoupon;

  /// Every coupon evaluated, best first (for the breakdown UI).
  final List<CouponEvaluation> coupons;
  final bool isFirstOrder;

  double get discount => bestCoupon?.discount ?? 0;
  double get total => subtotal + deliveryFee - discount;
  int get missingCount => lines.where((l) => !l.available).length;
  bool get isComplete => missingCount == 0;
}
