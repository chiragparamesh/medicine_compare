import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/prescription_image.dart';

enum PrescriptionSource { camera, gallery }

/// Gets a prescription photo. Wrapped so tests (and web) can swap it.
abstract class PrescriptionImageSource {
  /// Returns the image, or null if the user cancelled.
  Future<PrescriptionImage?> pick(PrescriptionSource source);
}

class ImagePickerSource implements PrescriptionImageSource {
  ImagePickerSource([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PrescriptionImage?> pick(PrescriptionSource source) async {
    final file = await _picker.pickImage(
      source: source == PrescriptionSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 90,
    );
    if (file == null) return null;
    return PrescriptionImage(bytes: await file.readAsBytes(), path: kIsWeb ? null : file.path);
  }
}

final prescriptionImageSourceProvider =
    Provider<PrescriptionImageSource>((ref) => ImagePickerSource());
