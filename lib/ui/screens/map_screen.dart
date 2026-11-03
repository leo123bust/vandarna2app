import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/filter_sheet.dart';
import 'building_details_screen.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();
  Building? _selected;

  void _handleFocusRequest(AppState s) {
    final target = s.focus;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.move(target.point, 16);
      setState(() => _selected = target);
      s.clearFocus();
    });
  }

  Future<void> _locate(AppState s) async {
    await s.refreshLocation();
    if (!mounted) return;
    final p = s.myLocation;
    if (p == null) {
      showSnack(context, 'Не може да се определи местоположението. Провери GPS и разрешенията.');
    } else {
      _controller.move(p, 15.5);
    }
  }

  Widget _pin(AppColors c, Building b) {
    final selected = _selected?.id == b.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selected = b);
        _controller.move(b.point, 16);
      },
      child: Stack(alignment: Alignment.center, children: [
        Icon(Icons.location_on, size: selected ? 52 : 42, color: c.pin),
        Positioned(
          top: selected ? 10 : 8,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: b.safety.color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    _handleFocusRequest(s);

    final list = s.mapBuildings;
    final preview = _selected ?? (list.isEmpty ? null : list.first);
    final tiles = c.isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

    return Column(children: [
      // header: logotype, settings, search field
      Container(
        color: c.bg,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Row(children: [
              Text('vandarna', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: c.text)),
              const Spacer(),
              RoundIconButton(
                icon: Icons.settings_outlined,
                tooltip: 'Настройки',
                size: 44,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ]),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => s.setTab(1),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: c.searchFill, borderRadius: BorderRadius.circular(28)),
                child: Row(children: [
                  Icon(Icons.search_rounded, color: c.text),
                  const SizedBox(width: 10),
                  Text('Търси локация...', style: TextStyle(color: c.textMuted, fontSize: 16)),
                ]),
              ),
            ),
            if (s.hasFilters) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.filter_alt_rounded, size: 16),
                  label: Text('Активни филтри • ${list.length}'),
                  onPressed: () => showFilterSheet(context),
                ),
              ),
            ],
          ]),
        ),
      ),
      Expanded(
        child: Stack(children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: kVarnaCenter,
              initialZoom: 13.5,
              minZoom: 5,
              maxZoom: 18,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: tiles,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.vandarna.app',
              ),
              if (s.myLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: s.myLocation!,
                    width: 80,
                    height: 80,
                    child: Stack(alignment: Alignment.center, children: [
                      Container(decoration: BoxDecoration(shape: BoxShape.circle, color: c.halo.withValues(alpha: 0.25))),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.isDark ? Colors.white : const Color(0xFF3B82F6),
                          border: Border.all(color: c.isDark ? c.halo : Colors.white, width: 4),
                        ),
                      ),
                    ]),
                  ),
                ]),
              MarkerLayer(
                markers: [
                  for (final b in list) Marker(point: b.point, width: 52, height: 52, child: _pin(c, b)),
                ],
              ),
            ],
          ),
          Positioned(
            left: 10,
            top: 6,
            child: Text('© OpenStreetMap · © CARTO', style: TextStyle(fontSize: 9, color: c.textMuted)),
          ),
          Positioned(
            right: 16,
            bottom: preview == null ? 24 : 150,
            child: Column(children: [
              RoundIconButton(icon: Icons.near_me_outlined, tooltip: 'Моето местоположение', size: 52, onTap: () => _locate(s)),
              const SizedBox(height: 12),
              RoundIconButton(icon: Icons.layers_outlined, tooltip: 'Филтри и слоеве', size: 52, onTap: () => showFilterSheet(context)),
            ]),
          ),
          if (preview != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PreviewCard(building: preview, distance: s.distanceTo(preview)),
            ),
        ]),
      ),
    ]);
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.building, required this.distance});
  final Building building;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final b = building;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: c.shadow,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(2))),
        AppCard(
          padding: const EdgeInsets.all(8),
          radius: 22,
          onTap: () => openBuilding(context, b),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(width: 84, height: 84, child: BuildingImage(b.photos.isEmpty ? null : b.photos.first)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 16, color: c.pin),
                  const SizedBox(width: 4),
                  Text(formatKm(distance), style: TextStyle(color: c.textMuted, fontSize: 13.5)),
                  const SizedBox(width: 8),
                  TagChip(b.safety.label, b.safety.color),
                ]),
              ]),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.chip, boxShadow: c.shadow, border: c.isDark ? Border.all(color: c.outline) : null),
              child: Icon(Icons.chevron_right_rounded, color: c.text),
            ),
          ]),
        ),
      ]),
    );
  }
}
