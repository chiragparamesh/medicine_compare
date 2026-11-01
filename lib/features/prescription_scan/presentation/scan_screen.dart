import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/medicine_search_sheet.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/domain/medicine.dart';
import '../../catalog/domain/medicine_matcher.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../ocr/presentation/ocr_providers.dart';

/// Shows the photo, runs OCR + fuzzy matching, and lets the user confirm
/// which detected medicines go into the cart.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.imageBytes});

  final Uint8List? imageBytes;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _DetectedLine {
  _DetectedLine(this.match) : medicine = match.medicine, selected = match.isMatched;

  final MedicineMatch match;
  Medicine? medicine;
  bool selected;
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  List<_DetectedLine>? _lines;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) _run();
  }

  Future<void> _run() async {
    try {
      final ocr = ref.read(ocrServiceProvider);
      final lines = await ocr.readLines(widget.imageBytes!);
      final matcher = await ref.read(matcherProvider.future);
      if (!mounted) return;
      setState(() => _lines = [for (final l in lines) _DetectedLine(matcher.match(l))]);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _change(_DetectedLine line) async {
    final med = await showMedicineSearch(
      context,
      initialQuery: line.match.query,
      title: 'Choose the right medicine',
    );
    if (med != null) {
      setState(() {
        line.medicine = med;
        line.selected = true;
      });
    }
  }

  void _addToCart() {
    final chosen = [
      for (final l in _lines!)
        if (l.selected && l.medicine != null) l.medicine!,
    ];
    ref.read(cartProvider.notifier).addAll(chosen);
    context.pushReplacement(AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final ocr = ref.watch(ocrServiceProvider);
    final theme = Theme.of(context);

    if (widget.imageBytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescription')),
        body: const Center(child: Text('No image. Go back and pick a photo.')),
      );
    }

    final selectedCount = _lines?.where((l) => l.selected && l.medicine != null).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Check medicines')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(widget.imageBytes!, height: 180, fit: BoxFit.cover),
          ),
          if (ocr.isDemo) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text('${ocr.name}: sample prescription'),
                subtitle: const Text(
                    'The handwriting model is still being trained in Colab, so this shows a '
                    'sample prescription. Matching against real medicine names is live.'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_error != null)
            Text('Could not read the prescription: $_error')
          else if (_lines == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Reading prescription...'),
              ]),
            )
          else ...[
            Text('Found ${_lines!.length} lines. Tick the medicines to add.',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final l in _lines!) _lineCard(l, theme),
          ],
        ],
      ),
      bottomNavigationBar: _lines == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  key: const Key('add-to-cart'),
                  onPressed: selectedCount == 0 ? null : _addToCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('Add $selectedCount to cart'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
            ),
    );
  }

  Widget _lineCard(_DetectedLine l, ThemeData theme) {
    final med = l.medicine;
    final edited = med != null && med != l.match.medicine;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: l.selected && med != null,
              onChanged: med == null ? null : (v) => setState(() => l.selected = v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${l.match.rawLine}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic, color: theme.colorScheme.outline)),
                  const SizedBox(height: 4),
                  if (med != null) ...[
                    Text(med.name, style: theme.textTheme.titleMedium),
                    Text('${med.salt} · ${med.strength} · ${med.pack}',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(edited
                          ? 'Chosen by you'
                          : 'Match ${(l.match.score * 100).round()}%'),
                    ),
                  ] else
                    Text('Not a medicine we recognise',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                ],
              ),
            ),
            TextButton(onPressed: () => _change(l), child: Text(med == null ? 'Search' : 'Change')),
          ],
        ),
      ),
    );
  }
}
