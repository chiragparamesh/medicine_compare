import '../../coupons/domain/coupon.dart';

/// One pharmacy app (Tata 1mg, PharmEasy, ...) with its prices and rules.
class PharmacyPlatform {
  const PharmacyPlatform({
    required this.id,
    required this.name,
    required this.color,
    required this.deliveryFee,
    required this.freeDeliveryAbove,
    required this.searchUrl,
    required this.coupons,
    required this.prices,
  });

  final String id;
  final String name;

  /// ARGB brand-ish color for the UI.
  final int color;
  final double deliveryFee;

  /// Delivery is free when the subtotal is at least this amount.
  final double freeDeliveryAbove;

  /// Search URL template with a `{query}` placeholder (deep link target).
  final String searchUrl;
  final List<Coupon> coupons;

  /// Selling price per pack, keyed by medicine id. Missing = not available.
  final Map<String, double> prices;

  double? priceOf(String medicineId) => prices[medicineId];

  double deliveryFor(double subtotal) =>
      subtotal >= freeDeliveryAbove ? 0 : deliveryFee;

  Uri searchUri(String query) =>
      Uri.parse(searchUrl.replaceAll('{query}', Uri.encodeComponent(query)));

  factory PharmacyPlatform.fromJson(Map<String, dynamic> json) => PharmacyPlatform(
        id: json['id'] as String,
        name: json['name'] as String,
        color: int.parse(json['color'] as String),
        deliveryFee: (json['deliveryFee'] as num).toDouble(),
        freeDeliveryAbove: (json['freeDeliveryAbove'] as num).toDouble(),
        searchUrl: json['searchUrl'] as String,
        coupons: [
          for (final c in json['coupons'] as List)
            Coupon.fromJson(c as Map<String, dynamic>),
        ],
        prices: {
          for (final e in (json['prices'] as Map<String, dynamic>).entries)
            e.key: (e.value as num).toDouble(),
        },
      );
}
