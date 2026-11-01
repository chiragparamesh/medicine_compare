import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/medicine.dart';

/// Source of the medicine database.
abstract class CatalogRepository {
  Future<List<Medicine>> loadMedicines();
}

/// Reads the bundled `assets/data/medicines.json`.
class AssetCatalogRepository implements CatalogRepository {
  AssetCatalogRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  static const path = 'assets/data/medicines.json';

  @override
  Future<List<Medicine>> loadMedicines() async {
    final json = jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;
    return [
      for (final m in json['medicines'] as List) Medicine.fromJson(m as Map<String, dynamic>),
    ];
  }
}
