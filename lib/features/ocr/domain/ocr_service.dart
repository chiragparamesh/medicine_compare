import '../../prescription_scan/domain/prescription_image.dart';

/// Reads text lines from a prescription image.
///
/// Implementations:
/// - `MlKitOcrService`: Google ML Kit on-device text recognition (Android).
/// - `PlaceholderOcrService`: sample prescriptions (web preview, tests).
/// - Later: fine-tuned TrOCR exported to TFLite (see docs/architecture.md).
abstract class OcrService {
  /// Human-readable name shown in the UI.
  String get name;

  /// True when results are canned/sample data rather than real recognition.
  bool get isDemo;

  /// Returns one string per text line, roughly in reading order.
  Future<List<String>> readLines(PrescriptionImage image);
}
