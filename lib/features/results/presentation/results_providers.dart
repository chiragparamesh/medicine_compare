import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/presentation/cart_controller.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../pricing/data/price_repository.dart';
import '../data/ordered_platforms_store.dart';
import '../domain/generic_finder.dart';
import '../domain/platform_quote.dart';
import '../domain/quote_calculator.dart';

/// Ranked bills for the current cart, cheapest complete cart first.
final quotesProvider = FutureProvider<List<PlatformQuote>>((ref) async {
  final cart = ref.watch(cartProvider);
  final platforms = await ref.watch(platformsProvider.future);
  final ordered = await ref.watch(orderedPlatformsProvider.future);
  return const QuoteCalculator().rank(cart, platforms, orderedBefore: ordered);
});

/// Cheaper same-composition alternatives on the winning platform.
final genericSuggestionsProvider = FutureProvider<List<GenericSuggestion>>((ref) async {
  final quotes = await ref.watch(quotesProvider.future);
  if (quotes.isEmpty) return const [];
  final catalog = await ref.watch(catalogProvider.future);
  return const GenericFinder().find(ref.watch(cartProvider), catalog, quotes.first.platform);
});
