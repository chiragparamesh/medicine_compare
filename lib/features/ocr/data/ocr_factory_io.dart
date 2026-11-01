import 'dart:io' show Platform;

import '../domain/ocr_service.dart';
import 'mlkit_ocr_service.dart';
import 'placeholder_ocr_service.dart';

/// Android/iOS: ML Kit. Desktop / test VM: sample prescriptions.
OcrService createDefaultOcrService() =>
    Platform.isAndroid || Platform.isIOS ? MlKitOcrService() : PlaceholderOcrService();
