import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'building_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.favorites;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text('Любими', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Все още нямаш любими',
                  subtitle: 'Натисни отметката на страницата на сграда, за да я запазиш тук.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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
