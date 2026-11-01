import '../../cart/domain/cart_item.dart';
import '../../catalog/domain/medicine.dart';
import '../../pricing/domain/pharmacy_platform.dart';

/// A cheaper medicine with the same composition, on a given platform.
class GenericSuggestion {
  const GenericSuggestion({
    required this.original,
    required this.alternative,
    required this.quantity,
    required this.originalPrice,
    required this.alternativePrice,
  });

  final Medicine original;
  final Medicine alternative;
  final int quantity;
  final double originalPrice;
  final double alternativePrice;

  double get savings => (originalPrice - alternativePrice) * quantity;
}

/// Finds the cheapest same-salt, same-strength, same-form alternative for each
/// cart item on [platform].
class GenericFinder {
  const GenericFinder();

  List<GenericSuggestion> find(
    List<CartItem> cart,
    List<Medicine> catalog,
    PharmacyPlatform platform,
  ) {
    final out = <GenericSuggestion>[];
    for (final item in cart) {
      final original = item.medicine;
      final originalPrice = platform.priceOf(original.id);
      if (originalPrice == null) continue;

      Medicine? bestAlt;
      double? bestPrice;
      for (final m in catalog) {
        if (m.id == original.id || m.compositionKey != original.compositionKey) continue;
        final p = platform.priceOf(m.id);
        if (p == null || p >= originalPrice) continue;
        if (bestPrice == null || p < bestPrice) {
          bestAlt = m;
          bestPrice = p;
        }
      }
      if (bestAlt != null) {
        out.add(GenericSuggestion(
          original: original,
          alternative: bestAlt,
          quantity: item.quantity,
          originalPrice: originalPrice,
          alternativePrice: bestPrice!,
        ));
      }
    }
    out.sort((a, b) => b.savings.compareTo(a.savings));
    return out;
  }
}
