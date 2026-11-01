import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PrescriptionSource { camera, gallery }

/// Gets a prescription photo. Wrapped so tests (and web) can swap it.
abstract class PrescriptionImageSource {
  /// Returns the image bytes, or null if the user cancelled.
  Future<Uint8List?> pick(PrescriptionSource source);
}

class ImagePickerSource implements PrescriptionImageSource {
  ImagePickerSource([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PrescriptionSource source) async {
    final file = await _picker.pickImage(
      source: source == PrescriptionSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  }
}

final prescriptionImageSourceProvider =
    Provider<PrescriptionImageSource>((ref) => ImagePickerSource());
