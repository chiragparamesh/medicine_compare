import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/domain/medicine.dart';
import '../../features/catalog/presentation/catalog_providers.dart';
import '../utils/money.dart';

/// Bottom sheet to search the medicine database. Returns the chosen medicine.
Future<Medicine?> showMedicineSearch(BuildContext context, {String initialQuery = '', String title = 'Add medicine'}) {
  return showModalBottomSheet<Medicine>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MedicineSearchSheet(initialQuery: initialQuery, title: title),
  );
}

class _MedicineSearchSheet extends ConsumerStatefulWidget {
  const _MedicineSearchSheet({required this.initialQuery, required this.title});

  final String initialQuery;
  final String title;

  @override
  ConsumerState<_MedicineSearchSheet> createState() => _MedicineSearchSheetState();
}

class _MedicineSearchSheetState extends ConsumerState<_MedicineSearchSheet> {
  late final _controller = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matcher = ref.watch(matcherProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Medicine or salt name, e.g. Dolo or paracetamol',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matcher.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load medicines: $e')),
                data: (m) {
                  final results = m.search(_controller.text);
                  if (results.isEmpty) {
                    return const Center(child: Text('No medicines found'));
                  }
                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final med = results[i];
                      return ListTile(
                        key: ValueKey('search-${med.id}'),
                        title: Text(med.name),
                        subtitle: Text('${med.salt} · ${med.strength}\n${med.pack}'),
                        isThreeLine: true,
                        trailing: Text('MRP ${formatInr(med.mrp)}'),
                        onTap: () => Navigator.pop(context, med),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
