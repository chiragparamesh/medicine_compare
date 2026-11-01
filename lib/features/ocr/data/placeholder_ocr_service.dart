import 'dart:typed_data';

import '../domain/ocr_service.dart';

/// Stand-in for the TrOCR model until it is trained in Colab.
///
/// Returns one of a few realistic, deliberately noisy prescriptions (picked
/// from the image bytes, so the same photo always gives the same result).
/// The noise ("Azithrl", "Telrna") exercises the fuzzy medicine matcher.
class PlaceholderOcrService implements OcrService {
  PlaceholderOcrService({this.delay = const Duration(milliseconds: 1200)});

  final Duration delay;

  static const samples = <List<String>>[
    [
      'Tab. Dolo 650 mg  1-0-1 x 5 days',
      'Tab Azithrl 500  OD x 3d',
      'Cap. Pan-D  1-0-0 before food',
      'Syp Ascoril LS  5ml TDS',
      'Adv: plenty of fluids, rest',
    ],
    [
      'Tab Telrna 40  0-0-1',
      'Tab Amlokind 5mg  1-0-0',
      'Tab Atorva 10  HS',
      'Tab Shelcal 500  1-0-1 after food',
    ],
    [
      'Montair LC  1 HS x 10 days',
      'Tab Allegra 120  SOS',
      'Tab Limcee  1-0-0',
      'Cap Becosules  0-1-0',
    ],
  ];

  @override
  String get name => 'Demo OCR';

  @override
  bool get isDemo => true;

  @override
  Future<List<String>> readLines(Uint8List imageBytes) async {
    await Future<void>.delayed(delay);
    var hash = imageBytes.length;
    final step = imageBytes.length < 64 ? 1 : imageBytes.length ~/ 64;
    for (var i = 0; i < imageBytes.length; i += step) {
      hash = (hash * 31 + imageBytes[i]) & 0x7fffffff;
    }
    return List.unmodifiable(samples[hash % samples.length]);
  }
}
