import '../../prescription_scan/domain/prescription_image.dart';
import '../domain/ocr_service.dart';

/// Sample prescriptions, used for the "Try a sample" demo, the web preview
/// (ML Kit has no web support) and tests.
///
/// The noise ("Azithrl", "Telrna") is deliberate: it exercises the fuzzy
/// medicine matcher the same way real handwriting OCR errors do.
class PlaceholderOcrService implements OcrService {
  PlaceholderOcrService({this.delay = const Duration(milliseconds: 1200)});

  final Duration delay;

  static const samples = <List<String>>[
    [
      'Dr. A. Sharma, MBBS, MD',
      'Rx',
      'Tab. Dolo 650 mg  1-0-1 x 5 days',
      'Tab Azithrl 500  OD x 3d',
      'Cap. Pan-D  1-0-0 before food',
      'Syp Ascoril LS  5ml TDS',
      'Adv: plenty of fluids, rest',
    ],
    [
      'Dr. R. Iyer, MD (Medicine)',
      'Rx',
      'Tab Telrna 40  0-0-1',
      'Tab Amlokind 5mg  1-0-0',
      'Tab Atorva 10  HS',
      'Tab Ecosprin 75  0-1-0 after food',
      'Review after 1 month',
    ],
    [
      'Dr. S. Khan, MBBS',
      'Rx',
      'Montair LC  1 HS x 10 days',
      'Tab Allegra 120  SOS',
      'Tab Limcee  1-0-0',
      'Cap Becosules  0-1-0',
    ],
  ];

  /// Lines for sample [index] (wraps around).
  static List<String> sample(int index) => samples[index % samples.length];

  @override
  String get name => 'Sample prescription';

  @override
  bool get isDemo => true;

  @override
  Future<List<String>> readLines(PrescriptionImage image) async {
    await Future<void>.delayed(delay);
    final bytes = image.bytes;
    var hash = bytes.length;
    final step = bytes.length < 64 ? 1 : bytes.length ~/ 64;
    for (var i = 0; i < bytes.length; i += step) {
      hash = (hash * 31 + bytes[i]) & 0x7fffffff;
    }
    return List.unmodifiable(sample(hash));
  }
}
