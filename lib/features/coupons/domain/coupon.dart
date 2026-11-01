enum CouponType { percent, flat }

/// A platform coupon. Rules supported: percent, flat, max cap, min order,
/// first order only.
class Coupon {
  const Coupon({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.maxCap,
    this.minOrder = 0,
    this.firstOrderOnly = false,
  });

  final String code;
  final String description;
  final CouponType type;

  /// Percent (0-100) for [CouponType.percent], rupees for [CouponType.flat].
  final double value;

  /// Maximum discount in rupees (percent coupons), or null for no cap.
  final double? maxCap;

  /// Minimum cart subtotal in rupees.
  final double minOrder;
  final bool firstOrderOnly;

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code'] as String,
        description: json['description'] as String? ?? '',
        type: json['type'] == 'percent' ? CouponType.percent : CouponType.flat,
        value: (json['value'] as num).toDouble(),
        maxCap: (json['maxCap'] as num?)?.toDouble(),
        minOrder: (json['minOrder'] as num?)?.toDouble() ?? 0,
        firstOrderOnly: json['firstOrderOnly'] as bool? ?? false,
      );
}
