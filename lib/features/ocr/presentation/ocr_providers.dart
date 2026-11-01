import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/placeholder_ocr_service.dart';
import '../domain/ocr_service.dart';

/// Swap this for the TFLite implementation once the model exists.
final ocrServiceProvider = Provider<OcrService>((ref) => PlaceholderOcrService());
