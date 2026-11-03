import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../domain/gamification.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'building_details_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    final s = context.read<AppState>();
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
      if (f != null) await s.updatePhoto(f.path);
    } catch (e) {
      if (context.mounted) {
        showSnack(context, e is UnsupportedError ? 'Снимка на профил е налична след конфигуриране на Firebase.' : 'Грешка: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    final u = s.user;

    if (u == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.account_circle_outlined, size: 72, color: c.textMuted),
              const SizedBox(height: 14),
              const Text('Влез в профила си', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Добавяй сгради, потвърждавай информация и следи постиженията си.', textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, height: 1.4)),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Вход / Регистрация', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()))),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())), child: const Text('Настройки')),
            ]),
          ),
        ),
      );
    }

    final stats = s.statsFor(u.uid);
    final xp = stats.xp;
    final level = levelFor(xp);
    final next = nextLevel(xp);
    final mine = s.buildings.where((b) => b.createdBy == u.uid).toList();
    final initials = u.username.isEmpty ? '?' : u.username.substring(0, 1).toUpperCase();

    Widget stat(String label, int value, IconData icon) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          radius: 20,
          child: Row(children: [
            Icon(icon, color: c.pin),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
            Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
        );

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
        Row(children: [
          const Expanded(child: Text('Профил', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6))),
          RoundIconButton(icon: Icons.settings_outlined, size: 44, tooltip: 'Настройки', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()))),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          GestureDetector(
            onTap: () => _changePhoto(context),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: c.surfaceAlt,
              backgroundImage: u.photoUrl == null ? null : NetworkImage(u.photoUrl!),
              child: u.photoUrl == null ? Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              if (u.email != null) Text(u.email!, style: TextStyle(color: c.textMuted, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Член от ${u.createdAt.month.toString().padLeft(2, '0')}.${u.createdAt.year}', style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            ]),
          ),
        ]),
        if (u.isGuest) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(16)),
            child: Text('Демо режим: Firebase не е конфигуриран. Данните се пазят само на това устройство.', style: TextStyle(color: c.textMuted, fontSize: 12.5, height: 1.4)),
          ),
        ],
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.military_tech_rounded, color: c.pin),
              const SizedBox(width: 8),
              Text(level.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('$xp XP', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: levelProgress(xp), minHeight: 10, backgroundColor: c.surfaceAlt, color: c.accent),
            ),
            const SizedBox(height: 8),
            Text(next == null ? 'Най-високо ниво достигнато' : 'Още ${next.minXp - xp} XP до „${next.name}"', style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            const SizedBox(height: 6),
            Text('XP се получава само от проверени и полезни приноси: потвърдени сгради, потвърждения и исторически записи.', style: TextStyle(color: c.textMuted, fontSize: 11.5, height: 1.4)),
          ]),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            stat('Подадени', stats.submitted, Icons.upload_rounded),
            stat('Проверени', stats.verifiedSubmissions, Icons.verified_rounded),
            stat('Потвърждения', stats.confirmations, Icons.how_to_vote_rounded),
            stat('Любими', stats.favorites, Icons.bookmark_rounded),
          ],
        ),
        const SizedBox(height: 22),
        const Text('Постижения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final a in kAchievements)
            Builder(builder: (_) {
              final done = a.unlocked(stats);
              return Tooltip(
                message: a.description,
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(color: done ? c.pin.withValues(alpha: 0.12) : c.surfaceAlt, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    Icon(a.icon, size: 28, color: done ? c.pin : c.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 6),
                    Text(a.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: done ? c.text : c.textMuted)),
                  ]),
                ),
              );
            }),
        ]),
        const SizedBox(height: 22),
        const Text('Моите сгради', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (mine.isEmpty)
          Text('Още не си добавял сгради.', style: TextStyle(color: c.textMuted))
        else
          for (final b in mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BuildingCard(building: b, distanceMeters: s.distanceTo(b), onTap: () => openBuilding(context, b)),
            ),
        const SizedBox(height: 8),
        if (!u.isGuest)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
            onPressed: s.signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Изход'),
          ),
      ]),
    );
  }
}
