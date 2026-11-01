import '../domain/ocr_service.dart';
import 'placeholder_ocr_service.dart';

/// Web: ML Kit is not available, use the sample prescriptions.
OcrService createDefaultOcrService() => PlaceholderOcrService();
