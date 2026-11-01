import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/cart_controller.dart';
import '../router/app_router.dart';

/// App bar cart icon with an item-count badge.
class CartButton extends ConsumerWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider).length;
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.push(AppRoutes.cart),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
