import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_compare/app.dart';
import 'package:medicine_compare/features/ocr/data/placeholder_ocr_service.dart';
import 'package:medicine_compare/features/ocr/presentation/ocr_providers.dart';
import 'package:medicine_compare/features/prescription_scan/data/prescription_image_source.dart';
import 'package:medicine_compare/features/prescription_scan/domain/prescription_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSource implements PrescriptionImageSource {
  @override
  Future<PrescriptionImage?> pick(PrescriptionSource source) async => PrescriptionImage(
      // Smallest valid PNG (1x1 transparent pixel).
      bytes: Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44,
        0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F,
        0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00,
        0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]));
}

Widget _app() => ProviderScope(
      overrides: [
        prescriptionImageSourceProvider.overrideWithValue(_FakeSource()),
        ocrServiceProvider.overrideWithValue(PlaceholderOcrService(delay: Duration.zero)),
      ],
      child: const App(),
    );

/// Lets real async work (asset loading, JSON parsing) and fake timers run
/// until no loading spinner is left, then settles animations.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 200));
    if (i >= 2 && find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // rootBundle caches asset futures; a future cached in a previous test's
    // fake-async zone never completes in the next one.
    rootBundle.clear();
  });

  testWidgets('home shows the main actions', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('MediCompare'), findsOneWidget);
    expect(find.text('Scan prescription'), findsOneWidget);
    expect(find.text('Upload from gallery'), findsOneWidget);
    expect(find.text('Try a sample prescription'), findsOneWidget);
  });

  testWidgets('sample prescription finds its medicines', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('try-sample')));
    await _settle(tester);
    expect(find.textContaining('Found 4 medicines'), findsOneWidget);
    expect(find.text('Add 4 to cart'), findsOneWidget);
  });

  testWidgets('scan -> confirm -> cart -> compare -> results', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan-gallery')));
    await _settle(tester);

    expect(find.text('Check medicines'), findsOneWidget);
    expect(find.textContaining('Found '), findsOneWidget);
    // Doctor name, "Rx" and advice lines go to the collapsible "Other text" card.
    await tester.scrollUntilVisible(find.textContaining('Other text'), 300);
    expect(find.textContaining('Other text'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-to-cart')));
    await tester.pumpAndSettle();

    expect(find.text('Your cart'), findsOneWidget);
    expect(find.byKey(const Key('compare')), findsOneWidget);

    await tester.tap(find.byKey(const Key('compare')));
    await _settle(tester);

    expect(find.text('Best prices'), findsOneWidget);
    expect(find.byKey(const Key('best-total')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('All platforms'), 300);
    expect(find.text('All platforms'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('quote-truemeds')), 300);
    expect(find.byKey(const ValueKey('quote-truemeds')), findsOneWidget);
  });
}
