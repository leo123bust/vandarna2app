import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';

Future<void> showFilterSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _FilterSheet(),
    );

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Филтри', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          _title('Безопасност'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
              label: const Text('Всички'),
              selected: s.safetyFilter == null,
              onSelected: (_) => s.setFilters(neighborhood: s.neighborhoodFilter, status: s.statusFilter),
            ),
            for (final v in Safety.values)
              ChoiceChip(
                label: Text(v.label),
                selected: s.safetyFilter == v,
                onSelected: (_) => s.setFilters(safety: v, neighborhood: s.neighborhoodFilter, status: s.statusFilter),
              ),
          ]),
          _title('Квартал'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
              label: const Text('Всички'),
              selected: s.neighborhoodFilter == null,
              onSelected: (_) => s.setFilters(safety: s.safetyFilter, status: s.statusFilter),
            ),
            for (final n in kNeighborhoods)
              ChoiceChip(
                label: Text(n),
                selected: s.neighborhoodFilter == n,
                onSelected: (_) => s.setFilters(safety: s.safetyFilter, neighborhood: n, status: s.statusFilter),
              ),
          ]),
          _title('Проверка'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
              label: const Text('Всички'),
              selected: s.statusFilter == null,
              onSelected: (_) => s.setFilters(safety: s.safetyFilter, neighborhood: s.neighborhoodFilter),
            ),
            for (final v in VerificationStatus.values)
              ChoiceChip(
                label: Text(v.label),
                selected: s.statusFilter == v,
                onSelected: (_) => s.setFilters(safety: s.safetyFilter, neighborhood: s.neighborhoodFilter, status: v),
              ),
          ]),
          _title('Сортиране'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const Text('Най-близки'), selected: s.sort == SortMode.nearest, onSelected: (_) => s.setSort(SortMode.nearest)),
            ChoiceChip(label: const Text('Най-нови'), selected: s.sort == SortMode.newest, onSelected: (_) => s.setSort(SortMode.newest)),
            ChoiceChip(label: const Text('По име'), selected: s.sort == SortMode.name, onSelected: (_) => s.setSort(SortMode.name)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: s.hasFilters ? () => s.setFilters(clear: true) : null,
                child: const Text('Нулирай'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Готово')),
            ),
          ]),
        ]),
      ),
    );
  }
}
