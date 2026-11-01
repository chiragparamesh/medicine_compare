import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_compare/app.dart';
import 'package:medicine_compare/features/ocr/data/placeholder_ocr_service.dart';
import 'package:medicine_compare/features/ocr/presentation/ocr_providers.dart';
import 'package:medicine_compare/features/prescription_scan/data/prescription_image_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSource implements PrescriptionImageSource {
  @override
  Future<Uint8List?> pick(PrescriptionSource source) async =>
      // Smallest valid PNG (1x1 transparent pixel).
      Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44,
        0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F,
        0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00,
        0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);
}

Widget _app() => ProviderScope(
      overrides: [
        prescriptionImageSourceProvider.overrideWithValue(_FakeSource()),
        ocrServiceProvider.overrideWithValue(PlaceholderOcrService(delay: Duration.zero)),
      ],
      child: const App(),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home shows the main actions', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('MediCompare'), findsOneWidget);
    expect(find.text('Scan prescription'), findsOneWidget);
    expect(find.text('Upload from gallery'), findsOneWidget);
  });

  testWidgets('scan -> confirm -> cart -> compare -> results', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-gallery')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Check medicines'), findsOneWidget);
    expect(find.textContaining('Found '), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-to-cart')));
    await tester.pumpAndSettle();

    expect(find.text('Your cart'), findsOneWidget);
    expect(find.byKey(const Key('compare')), findsOneWidget);

    await tester.tap(find.byKey(const Key('compare')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Best prices'), findsOneWidget);
    expect(find.byKey(const Key('best-total')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('All platforms'), 300);
    expect(find.text('All platforms'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('quote-truemeds')), 300);
    expect(find.byKey(const ValueKey('quote-truemeds')), findsOneWidget);
  });
}
