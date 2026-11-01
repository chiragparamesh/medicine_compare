import 'dart:typed_data';

/// A picked prescription photo.
class PrescriptionImage {
  const PrescriptionImage({required this.bytes, this.path});

  /// Encoded image (JPEG/PNG), used for preview and as OCR fallback input.
  final Uint8List bytes;

  /// Local file path when the platform has one (Android). Null on web.
  final String? path;
}

/// What the scan screen should read: a real photo, or one of the built-in
/// sample prescriptions (for demos and the web preview).
class ScanRequest {
  const ScanRequest.photo(PrescriptionImage this.image) : sampleIndex = null;
  const ScanRequest.sample(int this.sampleIndex) : image = null;

  final PrescriptionImage? image;
  final int? sampleIndex;

  bool get isSample => sampleIndex != null;
}
