import 'dart:typed_data';

/// Reads text lines from a prescription image.
///
/// Implementations: [PlaceholderOcrService] today (works on web and Android);
/// a TFLite TrOCR implementation later (Android only, see docs/architecture.md).
abstract class OcrService {
  /// Human-readable name shown in the UI, e.g. "Demo OCR".
  String get name;

  /// True when results are canned/sample data rather than real recognition.
  bool get isDemo;

  /// Returns one string per prescription line, in reading order.
  Future<List<String>> readLines(Uint8List imageBytes);
}
