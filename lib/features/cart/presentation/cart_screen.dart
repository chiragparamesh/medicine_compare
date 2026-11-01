import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/medicine_search_sheet.dart';
import '../domain/cart_item.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final med = await showMedicineSearch(context);
    if (med != null) ref.read(cartProvider.notifier).add(med);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final mrpTotal = cart.fold(0.0, (s, c) => s + c.medicine.mrp * c.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => ref.read(cartProvider.notifier).clear(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('cart-add'),
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
      body: cart.isEmpty
          ? const _EmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final item in cart) _CartTile(item: item),
                const SizedBox(height: 8),
                Text(
                  '${cart.length} medicine${cart.length == 1 ? '' : 's'} · MRP total ${formatInr(mrpTotal)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  key: const Key('compare'),
                  onPressed: () => context.push(AppRoutes.results),
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare prices on 5 apps'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
            ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    final med = item.medicine;
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('cart-${med.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final replacement = await showMedicineSearch(context,
                      initialQuery: med.name, title: 'Replace ${med.name}');
                  if (replacement != null) cart.replace(med.id, replacement);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(med.name, style: theme.textTheme.titleMedium)),
                      if (med.isGeneric) ...[
                        const SizedBox(width: 6),
                        const Chip(label: Text('Generic'), visualDensity: VisualDensity.compact),
                      ],
                    ]),
                    Text('${med.salt} · ${med.strength}', style: theme.textTheme.bodySmall),
                    Text('${med.pack} · MRP ${formatInr(med.mrp)}', style: theme.textTheme.bodySmall),
                    Text('Tap to change', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Decrease',
              icon: Icon(item.quantity == 1 ? Icons.delete_outline : Icons.remove),
              onPressed: () => cart.setQuantity(med.id, item.quantity - 1),
            ),
            Text('${item.quantity}', style: theme.textTheme.titleMedium),
            IconButton(
              tooltip: 'Increase',
              icon: const Icon(Icons.add),
              onPressed: item.quantity >= CartController.maxQuantity
                  ? null
                  : () => cart.setQuantity(med.id, item.quantity + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64),
              SizedBox(height: 12),
              Text('Your cart is empty', textAlign: TextAlign.center),
              SizedBox(height: 4),
              Text('Scan a prescription or add medicines by name.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
