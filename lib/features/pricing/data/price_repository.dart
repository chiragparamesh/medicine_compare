import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pharmacy_platform.dart';

/// Source of platform prices, delivery rules and coupons.
/// Mock today; a live implementation can replace it later.
abstract class PriceRepository {
  Future<List<PharmacyPlatform>> loadPlatforms();
}

/// Reads the bundled `assets/data/prices_mock.json` (illustrative prices).
class MockPriceRepository implements PriceRepository {
  MockPriceRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  static const path = 'assets/data/prices_mock.json';

  @override
  Future<List<PharmacyPlatform>> loadPlatforms() async {
    final json = jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;
    return [
      for (final p in json['platforms'] as List)
        PharmacyPlatform.fromJson(p as Map<String, dynamic>),
    ];
  }
}

final priceRepositoryProvider = Provider<PriceRepository>((ref) => MockPriceRepository());

final platformsProvider = FutureProvider<List<PharmacyPlatform>>(
  (ref) => ref.watch(priceRepositoryProvider).loadPlatforms(),
);
