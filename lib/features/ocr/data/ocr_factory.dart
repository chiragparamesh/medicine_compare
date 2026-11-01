// Picks the OCR implementation for the current platform without importing
// ML Kit (dart:io + platform channels) into the web build.
export 'ocr_factory_stub.dart' if (dart.library.io) 'ocr_factory_io.dart';
