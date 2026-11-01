/// Formats rupees with Indian digit grouping: 123456.5 -> "₹1,23,456.50".
String formatInr(num value, {bool showPaise = true}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(showPaise ? 2 : 0);
  final parts = fixed.split('.');
  final digits = parts[0];

  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final pairs = <String>[];
    while (rest.length > 2) {
      pairs.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) pairs.insert(0, rest);
    grouped = '${pairs.join(',')},$last3';
  }
  final paise = parts.length > 1 ? '.${parts[1]}' : '';
  return '${negative ? '-' : ''}₹$grouped$paise';
}

/// Rounds to 2 decimals to avoid floating point noise in money maths.
double roundMoney(double value) => (value * 100).roundToDouble() / 100;
