import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_constants.dart';
import '../../../core/utils/money.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/ordered_platforms_store.dart';
import '../domain/generic_finder.dart';
import '../domain/platform_quote.dart';
import 'results_providers.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quotesProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Best prices')),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : quotes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load prices: $e')),
              data: (list) => _ResultsBody(quotes: list),
            ),
    );
  }
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({required this.quotes});

  final List<PlatformQuote> quotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final best = quotes.first;
    final complete = quotes.where((q) => q.isComplete).toList();
    final worst = complete.isNotEmpty ? complete.last : null;
    final savings = worst != null && best.isComplete ? worst.total - best.total : 0.0;
    final generics = ref.watch(genericSuggestionsProvider).value ?? const <GenericSuggestion>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BestCard(quote: best, savings: savings),
        const SizedBox(height: 8),
        Text(AppConstants.demoPricesNote,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        if (generics.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Cheaper generics on ${best.platform.name}', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(AppConstants.genericDisclaimer, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final g in generics) _GenericTile(suggestion: g),
        ],
        const SizedBox(height: 20),
        Text('All platforms', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < quotes.length; i++) _QuoteCard(rank: i + 1, quote: quotes[i]),
      ],
    );
  }
}

Future<void> _open(BuildContext context, PlatformQuote q) async {
  final query = q.lines.first.item.medicine.name;
  final ok = await launchUrl(q.platform.searchUri(query), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not open ${q.platform.name}')));
  }
}

class _BestCard extends StatelessWidget {
  const _BestCard({required this.quote, required this.savings});

  final PlatformQuote quote;
  final double savings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(quote.platform.color);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.emoji_events_outlined),
              const SizedBox(width: 8),
              Text(quote.isComplete ? 'Cheapest' : 'Best available', style: theme.textTheme.labelLarge),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(radius: 8, backgroundColor: color),
                const SizedBox(width: 8),
                Expanded(child: Text(quote.platform.name, style: theme.textTheme.headlineSmall)),
                Text(formatInr(quote.total),
                    key: const Key('best-total'), style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 8),
            if (quote.bestCoupon != null)
              Text('Includes coupon ${quote.bestCoupon!.coupon.code} (-${formatInr(quote.discount)})'),
            Text(quote.deliveryFee == 0 ? 'Free delivery' : 'Delivery ${formatInr(quote.deliveryFee)}'),
            if (savings > 0)
              Text('You save ${formatInr(savings)} vs the most expensive app',
                  style: theme.textTheme.titleSmall),
            if (!quote.isComplete)
              Text('${quote.missingCount} item(s) not available on any single app',
                  style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('open-best'),
              onPressed: () => _open(context, quote),
              icon: const Icon(Icons.open_in_new),
              label: Text('Open ${quote.platform.name}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenericTile extends ConsumerWidget {
  const _GenericTile({required this.suggestion});

  final GenericSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = suggestion;
    return Card(
      child: ListTile(
        title: Text('${s.original.name} → ${s.alternative.name}'),
        subtitle: Text('${formatInr(s.originalPrice)} → ${formatInr(s.alternativePrice)} per pack · '
            'save ${formatInr(s.savings)}'),
        trailing: TextButton(
          onPressed: () {
            ref.read(cartProvider.notifier).replace(s.original.id, s.alternative);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Swapped to ${s.alternative.name}')));
          },
          child: const Text('Swap'),
        ),
      ),
    );
  }
}

class _QuoteCard extends ConsumerWidget {
  const _QuoteCard({required this.rank, required this.quote});

  final int rank;
  final PlatformQuote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final q = quote;
    final ordered = !q.isFirstOrder;
    return Card(
      key: ValueKey('quote-${q.platform.id}'),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(q.platform.color),
          foregroundColor: Colors.white,
          child: Text('$rank'),
        ),
        title: Text(q.platform.name),
        subtitle: Text(q.isComplete
            ? (q.bestCoupon != null ? 'With ${q.bestCoupon!.coupon.code}' : 'No coupon applies')
            : '${q.missingCount} item(s) unavailable'),
        trailing: Text(formatInr(q.total), style: theme.textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final l in q.lines)
            _row(
              '${l.item.medicine.name} × ${l.item.quantity}',
              l.available ? formatInr(l.lineTotal) : 'Not available',
              muted: !l.available,
              theme: theme,
            ),
          const Divider(),
          _row('Subtotal', formatInr(q.subtotal), theme: theme),
          _row(
            'Delivery',
            q.deliveryFee == 0 ? 'Free' : formatInr(q.deliveryFee),
            theme: theme,
            note: q.deliveryFee == 0 ? null : 'Free above ${formatInr(q.platform.freeDeliveryAbove)}',
          ),
          _row(
            q.bestCoupon != null ? 'Coupon ${q.bestCoupon!.coupon.code}' : 'Coupon',
            q.bestCoupon != null ? '-${formatInr(q.discount)}' : '-',
            theme: theme,
          ),
          const Divider(),
          _row('Total', formatInr(q.total), theme: theme, bold: true),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Coupons on ${q.platform.name}', style: theme.textTheme.labelLarge),
          ),
          for (final c in q.coupons)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                c.eligible ? Icons.check_circle_outline : Icons.block,
                color: c.eligible ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              title: Text('${c.coupon.code}: ${c.coupon.description}'),
              subtitle: Text(c.eligible ? 'Saves ${formatInr(c.discount)}' : c.reason ?? ''),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("I've ordered here before"),
            subtitle: const Text('Turns off first-order coupons'),
            value: ordered,
            onChanged: (v) =>
                ref.read(orderedPlatformsProvider.notifier).setOrderedBefore(q.platform.id, v),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _open(context, q),
              icon: const Icon(Icons.open_in_new),
              label: Text('Open ${q.platform.name}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {required ThemeData theme, bool muted = false, bool bold = false, String? note}) {
    final style = bold
        ? theme.textTheme.titleSmall
        : theme.textTheme.bodyMedium?.copyWith(color: muted ? theme.colorScheme.outline : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (note != null) Text(note, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}
