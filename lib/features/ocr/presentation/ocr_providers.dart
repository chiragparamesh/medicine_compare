import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ocr_factory.dart';
import '../domain/ocr_service.dart';

/// Real OCR on Android (ML Kit), samples on web. Swap for TrOCR/TFLite later.
final ocrServiceProvider = Provider<OcrService>((ref) => createDefaultOcrService());
