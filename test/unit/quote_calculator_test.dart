import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_compare/features/cart/domain/cart_item.dart';
import 'package:medicine_compare/features/catalog/domain/medicine.dart';
import 'package:medicine_compare/features/coupons/domain/coupon.dart';
import 'package:medicine_compare/features/pricing/domain/pharmacy_platform.dart';
import 'package:medicine_compare/features/results/domain/generic_finder.dart';
import 'package:medicine_compare/features/results/domain/quote_calculator.dart';

Medicine med(String id, {String salt = 'X', bool generic = false}) => Medicine(
      id: id, name: id, salt: salt, strength: '10 mg', form: 'Tablet',
      pack: 'Strip of 10', manufacturer: 'M', mrp: 100, isGeneric: generic,
    );

PharmacyPlatform platform(
  String id,
  Map<String, double> prices, {
  double fee = 50,
  double freeAbove = 500,
  List<Coupon> coupons = const [],
}) =>
    PharmacyPlatform(
      id: id, name: id, color: 0xFF000000, deliveryFee: fee, freeDeliveryAbove: freeAbove,
      searchUrl: 'https://example.com/?q={query}', coupons: coupons, prices: prices,
    );

void main() {
  const calc = QuoteCalculator();
  final a = med('a');
  final b = med('b');
  final cart = [CartItem(medicine: a, quantity: 2), CartItem(medicine: b)];

  test('bill = subtotal + delivery - best coupon', () {
    final p = platform('p', {'a': 100, 'b': 150}, coupons: const [
      Coupon(code: 'F30', description: '', type: CouponType.flat, value: 30),
    ]);
    final q = calc.quote(cart, p, isFirstOrder: true);
    expect(q.subtotal, 350); // 2*100 + 150
    expect(q.deliveryFee, 50); // below 500
    expect(q.discount, 30);
    expect(q.total, 370);
    expect(q.isComplete, isTrue);
  });

  test('free delivery at the threshold', () {
    final p = platform('p', {'a': 200, 'b': 100}, freeAbove: 500);
    expect(calc.quote(cart, p, isFirstOrder: true).deliveryFee, 0); // exactly 500
  });

  test('missing items are excluded and flagged', () {
    final p = platform('p', {'a': 100});
    final q = calc.quote(cart, p, isFirstOrder: true);
    expect(q.subtotal, 200);
    expect(q.missingCount, 1);
    expect(q.isComplete, isFalse);
  });

  test('ranking: complete carts first, then cheapest total', () {
    final cheapButIncomplete = platform('incomplete', {'a': 10});
    final expensive = platform('expensive', {'a': 150, 'b': 200});
    final cheap = platform('cheap', {'a': 120, 'b': 160});
    final ranked = calc.rank(cart, [cheapButIncomplete, expensive, cheap]);
    expect(ranked.map((q) => q.platform.id), ['cheap', 'expensive', 'incomplete']);
  });

  test('orderedBefore disables first-order coupons for that platform only', () {
    const first = Coupon(
        code: 'NEW', description: '', type: CouponType.flat, value: 100, firstOrderOnly: true);
    final p1 = platform('p1', {'a': 100, 'b': 100}, coupons: const [first]);
    final p2 = platform('p2', {'a': 100, 'b': 100}, coupons: const [first]);
    final ranked = calc.rank(cart, [p1, p2], orderedBefore: {'p1'});
    final byId = {for (final q in ranked) q.platform.id: q};
    expect(byId['p1']!.discount, 0);
    expect(byId['p2']!.discount, 100);
    expect(ranked.first.platform.id, 'p2');
  });

  group('GenericFinder', () {
    final brand = med('brand', salt: 'Paracetamol');
    final gen = med('gen', salt: 'Paracetamol', generic: true);
    final other = med('other', salt: 'Ibuprofen', generic: true);

    test('suggests the cheaper same-composition medicine', () {
      final p = platform('p', {'brand': 30, 'gen': 12, 'other': 5});
      final s = const GenericFinder().find([CartItem(medicine: brand, quantity: 3)], [brand, gen, other], p);
      expect(s, hasLength(1));
      expect(s.single.alternative.id, 'gen');
      expect(s.single.savings, 54); // (30-12)*3
    });

    test('no suggestion when the alternative is not cheaper or not sold', () {
      expect(
        const GenericFinder().find([CartItem(medicine: brand)], [brand, gen], platform('p', {'brand': 10, 'gen': 12})),
        isEmpty,
      );
      expect(
        const GenericFinder().find([CartItem(medicine: brand)], [brand, gen], platform('p', {'brand': 10})),
        isEmpty,
      );
    });
  });
}
