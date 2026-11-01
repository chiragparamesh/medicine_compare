import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/medicine_search_sheet.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/domain/medicine.dart';
import '../../catalog/domain/medicine_matcher.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../ocr/data/placeholder_ocr_service.dart';
import '../../ocr/presentation/ocr_providers.dart';
import '../domain/prescription_image.dart';

/// Reads the prescription (OCR or sample), fuzzy-matches each line to the
/// medicine database, and lets the user confirm what goes into the cart.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, required this.request});

  final ScanRequest? request;

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
  List<_DetectedLine>? _matched;
  List<_DetectedLine>? _other;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.request != null) _run();
  }

  Future<void> _run() async {
    try {
      final req = widget.request!;
      final lines = req.isSample
          ? PlaceholderOcrService.sample(req.sampleIndex!)
          : await ref.read(ocrServiceProvider).readLines(req.image!);
      if (req.isSample) await Future<void>.delayed(const Duration(milliseconds: 400));
      final matcher = await ref.read(matcherProvider.future);
      if (!mounted) return;

      // Keep the best-scoring line per medicine; everything else is "other text".
      final best = <String, _DetectedLine>{};
      final other = <_DetectedLine>[];
      for (final l in lines) {
        final d = _DetectedLine(matcher.match(l));
        final id = d.match.medicine?.id;
        if (id == null) {
          other.add(d);
        } else if (best[id] == null || best[id]!.match.score < d.match.score) {
          best[id] = d;
        }
      }
      setState(() {
        _matched = best.values.toList();
        _other = other;
      });
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
    if (med == null) return;
    setState(() {
      line.medicine = med;
      line.selected = true;
      if (_other!.remove(line)) _matched!.add(line);
    });
  }

  void _addToCart() {
    final chosen = [
      for (final l in _matched!)
        if (l.selected && l.medicine != null) l.medicine!,
    ];
    ref.read(cartProvider.notifier).addAll(chosen);
    context.pushReplacement(AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final theme = Theme.of(context);

    if (req == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescription')),
        body: const Center(child: Text('No image. Go back and pick a photo.')),
      );
    }

    final ocr = ref.watch(ocrServiceProvider);
    final isSampleData = req.isSample || ocr.isDemo;
    final done = _matched != null;
    final selectedCount = _matched?.where((l) => l.selected && l.medicine != null).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Check medicines')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (req.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(req.image!.bytes, height: 180, fit: BoxFit.cover),
            )
          else
            _SamplePaper(lines: PlaceholderOcrService.sample(req.sampleIndex!)),
          if (isSampleData) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Sample prescription'),
                subtitle: Text(req.isSample
                    ? 'A built-in example to try the app. Use the camera for your own prescription.'
                    : 'Text recognition runs on the Android app. The web preview uses a sample.'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_error != null)
            Text('Could not read the prescription: $_error')
          else if (!done)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Reading prescription...'),
              ]),
            )
          else ...[
            if (_matched!.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.search_off),
                  title: const Text('No medicines recognised'),
                  subtitle: const Text(
                      'Try a sharper, well-lit photo of the medicine lines, or add them by name.'),
                  trailing: TextButton(
                    onPressed: () async {
                      final med = await showMedicineSearch(context);
                      if (med != null) {
                        ref.read(cartProvider.notifier).add(med);
                        if (context.mounted) context.pushReplacement(AppRoutes.cart);
                      }
                    },
                    child: const Text('Search'),
                  ),
                ),
              )
            else ...[
              Text('Found ${_matched!.length} medicine${_matched!.length == 1 ? '' : 's'}. '
                  'Untick anything wrong.',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final l in _matched!) _matchedCard(l, theme),
            ],
            if (_other!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.notes),
                  title: Text('Other text (${_other!.length} lines)'),
                  subtitle: const Text('Not matched to a medicine. Tap Search if one is missing.'),
                  children: [
                    for (final l in _other!)
                      ListTile(
                        dense: true,
                        title: Text(l.match.rawLine),
                        subtitle: l.match.alternatives.isNotEmpty && l.match.score >= 0.55
                            ? Text('Did you mean ${l.match.alternatives.first.name}?')
                            : null,
                        trailing: TextButton(onPressed: () => _change(l), child: const Text('Search')),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: !done
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

  Widget _matchedCard(_DetectedLine l, ThemeData theme) {
    final med = l.medicine!;
    final edited = med != l.match.medicine;
    final pct = (l.match.score * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: l.selected, onChanged: (v) => setState(() => l.selected = v ?? false)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${l.match.rawLine}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic, color: theme.colorScheme.outline)),
                  const SizedBox(height: 4),
                  Text(med.name, style: theme.textTheme.titleMedium),
                  Text('${med.salt} · ${med.strength} · ${med.pack}', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  _ConfidenceChip(edited: edited, percent: pct),
                ],
              ),
            ),
            TextButton(onPressed: () => _change(l), child: const Text('Change')),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.edited, required this.percent});

  final bool edited;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = edited
        ? ('Chosen by you', scheme.primary)
        : percent >= 90
            ? ('Match $percent%', scheme.primary)
            : ('Check: $percent% match', scheme.tertiary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// The sample prescription drawn like a paper note.
class _SamplePaper extends StatelessWidget {
  const _SamplePaper({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(l,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Color(0xFF1F2A6B), fontSize: 15)),
            ),
        ],
      ),
    );
  }
}
