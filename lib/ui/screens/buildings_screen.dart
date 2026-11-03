import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/filter_sheet.dart';
import 'building_details_screen.dart';

/// Catalog of buildings (card layout from the "Близки локации" reference) + historical archive.
class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    final list = s.visible;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            const Expanded(child: Text('Сгради', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6))),
            RoundIconButton(icon: Icons.tune_rounded, size: 44, tooltip: 'Филтри и сортиране', onTap: () => showFilterSheet(context)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            s.archive ? 'Исторически архив – сгради, които вече не съществуват.' : 'Открий още изоставени сгради във Варна.',
            style: TextStyle(fontSize: 16, color: c.textMuted, height: 1.35),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            ChoiceChip(label: const Text('Активни'), selected: !s.archive, onSelected: (_) => s.setArchive(false)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Архив'), selected: s.archive, onSelected: (_) => s.setArchive(true)),
            const Spacer(),
            Text('${list.length} обекта', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? EmptyState(
                  icon: Icons.apartment_rounded,
                  title: s.archive ? 'Архивът е празен' : 'Няма сгради',
                  subtitle: s.hasFilters ? 'Нулирай филтрите, за да видиш всички записи.' : 'Добави първата сграда от раздел „Добави".',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => BuildingCard(
                    building: list[i],
                    distanceMeters: s.distanceTo(list[i]),
                    onTap: () => openBuilding(context, list[i]),
                  ),
                ),
        ),
      ]),
    );
  }
}
