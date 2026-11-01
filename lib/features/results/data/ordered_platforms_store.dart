import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which platforms the user has ordered from before, so
/// "first order" coupons are only offered where they apply.
class OrderedPlatformsController extends AsyncNotifier<Set<String>> {
  static const _key = 'ordered_platforms';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<void> setOrderedBefore(String platformId, bool ordered) async {
    final current = {...?state.value};
    ordered ? current.add(platformId) : current.remove(platformId);
    state = AsyncData(current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, current.toList()..sort());
  }
}

final orderedPlatformsProvider =
    AsyncNotifierProvider<OrderedPlatformsController, Set<String>>(OrderedPlatformsController.new);
