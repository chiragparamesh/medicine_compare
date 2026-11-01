import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_compare/features/coupons/domain/coupon.dart';
import 'package:medicine_compare/features/coupons/domain/coupon_engine.dart';

void main() {
  const engine = CouponEngine();

  const percent25cap150min300first = Coupon(
    code: 'NEW25', description: '', type: CouponType.percent,
    value: 25, maxCap: 150, minOrder: 300, firstOrderOnly: true,
  );
  const flat50min599 = Coupon(
    code: 'FLAT50', description: '', type: CouponType.flat, value: 50, minOrder: 599,
  );
  const percent10 = Coupon(code: 'P10', description: '', type: CouponType.percent, value: 10);

  group('evaluate', () {
    test('percent discount below the cap', () {
      final r = engine.evaluate(percent25cap150min300first, subtotal: 400, isFirstOrder: true);
      expect(r.eligible, isTrue);
      expect(r.discount, 100); // 25% of 400
    });

    test('percent discount is capped', () {
      final r = engine.evaluate(percent25cap150min300first, subtotal: 1000, isFirstOrder: true);
      expect(r.discount, 150);
    });

    test('min order is inclusive at the boundary', () {
      expect(engine.evaluate(percent25cap150min300first, subtotal: 300, isFirstOrder: true).eligible, isTrue);
      final below = engine.evaluate(percent25cap150min300first, subtotal: 299.5, isFirstOrder: true);
      expect(below.eligible, isFalse);
      expect(below.reason, 'Add ₹0.50 more');
    });

    test('first-order coupon rejected for returning users', () {
      final r = engine.evaluate(percent25cap150min300first, subtotal: 1000, isFirstOrder: false);
      expect(r.eligible, isFalse);
      expect(r.reason, 'First order only');
    });

    test('flat discount needs min order', () {
      expect(engine.evaluate(flat50min599, subtotal: 598.99, isFirstOrder: false).eligible, isFalse);
      expect(engine.evaluate(flat50min599, subtotal: 599, isFirstOrder: false).discount, 50);
    });

    test('flat discount never exceeds the subtotal', () {
      const flat100 = Coupon(code: 'F100', description: '', type: CouponType.flat, value: 100);
      expect(engine.evaluate(flat100, subtotal: 60, isFirstOrder: false).discount, 60);
    });

    test('uncapped percent rounds to paise', () {
      expect(engine.evaluate(percent10, subtotal: 123.45, isFirstOrder: false).discount, 12.35);
    });

    test('empty cart gets nothing', () {
      expect(engine.evaluate(percent10, subtotal: 0, isFirstOrder: true).eligible, isFalse);
    });
  });

  group('best', () {
    final coupons = [percent25cap150min300first, flat50min599, percent10];

    test('picks the largest discount', () {
      // 700: NEW25 -> 150 (capped), FLAT50 -> 50, P10 -> 70
      final b = engine.best(coupons, subtotal: 700, isFirstOrder: true)!;
      expect(b.coupon.code, 'NEW25');
      expect(b.discount, 150);
    });

    test('falls back when first-order coupon is not allowed', () {
      // 700, returning: FLAT50 -> 50, P10 -> 70
      expect(engine.best(coupons, subtotal: 700, isFirstOrder: false)!.coupon.code, 'P10');
    });

    test('returns null when nothing applies', () {
      expect(engine.best([flat50min599], subtotal: 100, isFirstOrder: true), isNull);
    });

    test('evaluateAll lists eligible first, best first', () {
      final all = engine.evaluateAll(coupons, subtotal: 200, isFirstOrder: true);
      expect(all.first.coupon.code, 'P10');
      expect(all.skip(1).every((e) => !e.eligible), isTrue);
    });
  });
}
