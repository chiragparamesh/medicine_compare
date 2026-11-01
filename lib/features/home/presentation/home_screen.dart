import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/widgets/cart_button.dart';
import '../../../core/widgets/medicine_search_sheet.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../prescription_scan/data/prescription_image_source.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref, PrescriptionSource source) async {
    try {
      final bytes = await ref.read(prescriptionImageSourceProvider).pick(source);
      if (bytes != null && context.mounted) context.push(AppRoutes.scan, extra: bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open the ${source.name}: $e')));
      }
    }
  }

  Future<void> _addManually(BuildContext context, WidgetRef ref) async {
    final med = await showMedicineSearch(context);
    if (med == null || !context.mounted) return;
    ref.read(cartProvider.notifier).add(med);
    context.push(AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName), actions: const [CartButton()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.receipt_long, size: 40, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(height: 12),
                    Text(AppConstants.tagline,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                    const SizedBox(height: 8),
                    Text(
                      'Read your prescription, confirm the medicines, and see the final price '
                      '(after delivery and the best coupon) on 5 pharmacy apps.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('scan-camera'),
              onPressed: () => _pick(context, ref, PrescriptionSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Scan prescription'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('scan-gallery'),
              onPressed: () => _pick(context, ref, PrescriptionSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Upload from gallery'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              key: const Key('add-manually'),
              onPressed: () => _addManually(context, ref),
              icon: const Icon(Icons.search),
              label: const Text('Search and add medicines manually'),
            ),
            const SizedBox(height: 24),
            Text('How it works', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Step(icon: Icons.document_scanner_outlined, text: 'Photograph the prescription'),
            const _Step(icon: Icons.edit_note, text: 'Check and edit the medicines we found'),
            const _Step(icon: Icons.compare_arrows, text: 'Compare final prices, pick the cheapest app'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final p in AppConstants.platformNames) Chip(label: Text(p))],
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(text),
      );
}
