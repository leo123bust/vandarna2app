import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../widgets/bottom_nav.dart';
import 'add_building_screen.dart';
import 'buildings_screen.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Main scaffold with the six-tab bottom navigation.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      body: IndexedStack(
        index: s.tab,
        children: const [
          MapScreen(),
          SearchScreen(),
          BuildingsScreen(),
          AddBuildingScreen(),
          FavoritesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(index: s.tab, onChanged: s.setTab),
    );
  }
}
