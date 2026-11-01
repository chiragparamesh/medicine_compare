import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../prescription_scan/domain/prescription_image.dart';
import '../domain/ocr_service.dart';

/// Google ML Kit on-device text recognition (Latin script). Free, offline.
///
/// Reads printed text very well and neat handwriting reasonably; messy
/// doctor handwriting is what the fine-tuned TrOCR model is for (later).
/// Only imported on io platforms (see ocr_factory.dart).
class MlKitOcrService implements OcrService {
  @override
  String get name => 'On-device text recognition';

  @override
  bool get isDemo => false;

  @override
  Future<List<String>> readLines(PrescriptionImage image) async {
    var path = image.path;
    File? temp;
    if (path == null || !File(path).existsSync()) {
      temp = File('${Directory.systemTemp.path}/rx_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await temp.writeAsBytes(image.bytes, flush: true);
      path = temp.path;
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return [
        for (final block in result.blocks)
          for (final line in block.lines)
            if (line.text.trim().isNotEmpty) line.text.trim(),
      ];
    } finally {
      await recognizer.close();
      if (temp != null && temp.existsSync()) await temp.delete();
    }
  }
}
