import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/filter_sheet.dart';
import 'building_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _use(String text) {
    _ctrl.text = text;
    _ctrl.selection = TextSelection.collapsed(offset: text.length);
    context.read<AppState>().addRecent(text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    final q = _ctrl.text.trim();
    final results = s.search(q);

    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(children: [
            const Expanded(child: Text('Търсене', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
            RoundIconButton(icon: Icons.tune_rounded, size: 44, tooltip: 'Филтри', onTap: () => showFilterSheet(context)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _ctrl,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) => s.addRecent(v),
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Търси по име, квартал, адрес...',
              fillColor: c.searchFill,
              prefixIcon: Icon(Icons.search_rounded, color: c.text),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_ctrl.clear)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        if (s.hasFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: ActionChip(
              avatar: const Icon(Icons.filter_alt_rounded, size: 16),
              label: const Text('Активни филтри'),
              onPressed: () => showFilterSheet(context),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: q.isEmpty
              ? _Idle(onPick: _use)
              : results.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Няма намерени резултати',
                      subtitle: 'Опитай с друго име или квартал, или промени филтрите.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => BuildingCard(
                        building: results[i],
                        distanceMeters: s.distanceTo(results[i]),
                        onTap: () {
                          s.addRecent(q);
                          openBuilding(context, results[i]);
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    final names = s.buildings.where((b) => !b.demolished).take(4).map((b) => b.name);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
      if (s.recents.isNotEmpty) ...[
        Row(children: [
          const Expanded(child: Text('Скорошни търсения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          TextButton(onPressed: s.clearRecents, child: const Text('Изчисти')),
        ]),
        for (final r in s.recents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history_rounded, color: c.textMuted),
            title: Text(r),
            trailing: Icon(Icons.north_west_rounded, size: 18, color: c.textMuted),
            onTap: () => onPick(r),
          ),
        const SizedBox(height: 12),
      ],
      const Text('Предложения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final n in kNeighborhoods.take(6)) ActionChip(label: Text(n), onPressed: () => onPick(n)),
        for (final n in names) ActionChip(label: Text(n), onPressed: () => onPick(n)),
      ]),
    ]);
  }
}
