import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_compare/core/utils/fuzzy.dart';
import 'package:medicine_compare/core/utils/money.dart';
import 'package:medicine_compare/features/catalog/domain/medicine.dart';
import 'package:medicine_compare/features/catalog/domain/medicine_matcher.dart';
import 'package:medicine_compare/features/ocr/data/placeholder_ocr_service.dart';

void main() {
  final json = jsonDecode(File('assets/data/medicines.json').readAsStringSync()) as Map<String, dynamic>;
  final medicines = [
    for (final m in json['medicines'] as List) Medicine.fromJson(m as Map<String, dynamic>),
  ];
  final matcher = MedicineMatcher(medicines);

  group('tokens', () {
    test('strips form prefix, units and dosage schedule', () {
      expect(matcher.tokens('Tab. Dolo 650 mg  1-0-1 x 5 days'), ['dolo', '650']);
      expect(matcher.tokens('Tab Amlokind 5mg  1-0-0'), ['amlokind', '5']);
      expect(matcher.tokens('Syp Ascoril LS  5ml TDS'), ['ascoril', 'ls']);
      expect(matcher.tokens('Montair LC  1 HS x 10 days'), ['montair', 'lc', '1']);
    });
  });

  group('match', () {
    final expected = {
      'Tab. Dolo 650 mg  1-0-1 x 5 days': 'dolo_650',
      'Tab Azithrl 500  OD x 3d': 'azithral_500', // OCR typo
      'Cap. Pan-D  1-0-0 before food': 'pan_d',
      'Syp Ascoril LS  5ml TDS': 'ascoril_ls',
      'Tab Telrna 40  0-0-1': 'telma_40', // "rn" read instead of "m"
      'Tab Amlokind 5mg  1-0-0': 'amlokind_5',
      'Montair LC  1 HS x 10 days': 'montair_lc',
      'Tab Allegra 120  SOS': 'allegra_120',
    };
    expected.forEach((line, id) {
      test('"$line" -> $id', () {
        final m = matcher.match(line);
        expect(m.medicine?.id, id, reason: 'score ${m.score}');
      });
    });

    test('non-medicine lines are not matched', () {
      expect(matcher.match('Adv: plenty of fluids, rest').isMatched, isFalse);
    });

    test('every line in the demo OCR samples is either a known medicine or advice', () {
      for (final sample in PlaceholderOcrService.samples) {
        for (final line in sample) {
          if (line.startsWith('Adv')) continue;
          expect(matcher.match(line).isMatched, isTrue, reason: line);
        }
      }
    });
  });

  test('search finds by brand or salt', () {
    expect(matcher.search('dolo').first.id, 'dolo_650');
    expect(matcher.search('pantoprazole').map((m) => m.id), contains('pan_40'));
    expect(matcher.search('allegr').first.id, 'allegra_120');
  });

  test('levenshtein / similarity', () {
    expect(levenshtein('kitten', 'sitting'), 3);
    expect(similarity('abc', 'abc'), 1);
  });

  test('formatInr uses Indian grouping', () {
    expect(formatInr(0), '₹0.00');
    expect(formatInr(999.5), '₹999.50');
    expect(formatInr(123456.78), '₹1,23,456.78');
    expect(formatInr(-1500), '-₹1,500.00');
  });
}
