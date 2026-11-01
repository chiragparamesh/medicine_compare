import 'dart:math' as math;

import '../../../core/utils/money.dart';
import 'coupon.dart';

/// Outcome of applying one coupon to a cart.
class CouponEvaluation {
  const CouponEvaluation._(this.coupon, this.eligible, this.discount, this.reason);

  factory CouponEvaluation.eligible(Coupon c, double discount) =>
      CouponEvaluation._(c, true, discount, null);

  factory CouponEvaluation.ineligible(Coupon c, String reason) =>
      CouponEvaluation._(c, false, 0, reason);

  final Coupon coupon;
  final bool eligible;
  final double discount;

  /// Why it can't be used, e.g. "Add ₹120.00 more" or "First order only".
  final String? reason;
}

/// Pure coupon rule engine. One coupon applies per platform: the best one.
class CouponEngine {
  const CouponEngine();

  CouponEvaluation evaluate(
    Coupon coupon, {
    required double subtotal,
    required bool isFirstOrder,
  }) {
    if (coupon.firstOrderOnly && !isFirstOrder) {
      return CouponEvaluation.ineligible(coupon, 'First order only');
    }
    if (subtotal <= 0) {
      return CouponEvaluation.ineligible(coupon, 'Cart is empty');
    }
    if (subtotal < coupon.minOrder) {
      final short = roundMoney(coupon.minOrder - subtotal);
      return CouponEvaluation.ineligible(coupon, 'Add ${formatInr(short)} more');
    }

    var discount = switch (coupon.type) {
      CouponType.percent => subtotal * coupon.value.clamp(0, 100) / 100,
      CouponType.flat => coupon.value,
    };
    if (coupon.maxCap != null) discount = math.min(discount, coupon.maxCap!);
    discount = math.min(discount, subtotal); // never more than the cart
    return CouponEvaluation.eligible(coupon, roundMoney(math.max(discount, 0)));
  }

  /// All coupons evaluated, best eligible first, then ineligible ones.
  List<CouponEvaluation> evaluateAll(
    List<Coupon> coupons, {
    required double subtotal,
    required bool isFirstOrder,
  }) {
    final all = [
      for (final c in coupons)
        evaluate(c, subtotal: subtotal, isFirstOrder: isFirstOrder),
    ];
    // Stable sort: eligible by discount desc; ties keep original order.
    final indexed = all.asMap().entries.toList()
      ..sort((a, b) {
        if (a.value.eligible != b.value.eligible) return a.value.eligible ? -1 : 1;
        final byDiscount = b.value.discount.compareTo(a.value.discount);
        return byDiscount != 0 ? byDiscount : a.key.compareTo(b.key);
      });
    return [for (final e in indexed) e.value];
  }

  /// The single best eligible coupon, or null if none applies.
  CouponEvaluation? best(
    List<Coupon> coupons, {
    required double subtotal,
    required bool isFirstOrder,
  }) {
    final all = evaluateAll(coupons, subtotal: subtotal, isFirstOrder: isFirstOrder);
    return all.isNotEmpty && all.first.eligible && all.first.discount > 0
        ? all.first
        : null;
  }
}
