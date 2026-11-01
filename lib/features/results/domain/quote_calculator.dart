import '../../../core/utils/money.dart';
import '../../cart/domain/cart_item.dart';
import '../../coupons/domain/coupon_engine.dart';
import '../../pricing/domain/pharmacy_platform.dart';
import 'platform_quote.dart';

/// Builds a bill per platform and ranks them.
///
/// final = subtotal + delivery(subtotal) - best coupon(subtotal)
/// Ranking: platforms that have every item first, then by final total,
/// then by fewer missing items, then by name.
class QuoteCalculator {
  const QuoteCalculator({this.engine = const CouponEngine()});

  final CouponEngine engine;

  PlatformQuote quote(
    List<CartItem> cart,
    PharmacyPlatform platform, {
    required bool isFirstOrder,
  }) {
    final lines = [
      for (final item in cart)
        QuoteLine(item: item, unitPrice: platform.priceOf(item.medicine.id)),
    ];
    final subtotal = roundMoney(
      lines.where((l) => l.available).fold(0.0, (sum, l) => sum + l.lineTotal),
    );
    final delivery = subtotal > 0 ? platform.deliveryFor(subtotal) : 0.0;
    final coupons = engine.evaluateAll(
      platform.coupons,
      subtotal: subtotal,
      isFirstOrder: isFirstOrder,
    );
    final best = coupons.isNotEmpty && coupons.first.eligible && coupons.first.discount > 0
        ? coupons.first
        : null;
    return PlatformQuote(
      platform: platform,
      lines: lines,
      subtotal: subtotal,
      deliveryFee: delivery,
      bestCoupon: best,
      coupons: coupons,
      isFirstOrder: isFirstOrder,
    );
  }

  List<PlatformQuote> rank(
    List<CartItem> cart,
    List<PharmacyPlatform> platforms, {
    Set<String> orderedBefore = const {},
  }) {
    final quotes = [
      for (final p in platforms)
        quote(cart, p, isFirstOrder: !orderedBefore.contains(p.id)),
    ];
    quotes.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? -1 : 1;
      final byTotal = a.total.compareTo(b.total);
      if (byTotal != 0) return byTotal;
      final byMissing = a.missingCount.compareTo(b.missingCount);
      if (byMissing != 0) return byMissing;
      return a.platform.name.compareTo(b.platform.name);
    });
    return quotes;
  }
}
