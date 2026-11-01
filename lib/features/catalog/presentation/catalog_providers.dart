import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../domain/medicine.dart';
import '../domain/medicine_matcher.dart';

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => AssetCatalogRepository());

final catalogProvider = FutureProvider<List<Medicine>>(
  (ref) => ref.watch(catalogRepositoryProvider).loadMedicines(),
);

final matcherProvider = FutureProvider<MedicineMatcher>(
  (ref) async => MedicineMatcher(await ref.watch(catalogProvider.future)),
);
