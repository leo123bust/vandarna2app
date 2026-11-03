import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'splash_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _header(BuildContext context, String t) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textMuted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: c.bg, scrolledUnderElevation: 0),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
        _header(context, 'Тема'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Системна'), icon: Icon(Icons.brightness_auto_rounded, size: 18)),
              ButtonSegment(value: ThemeMode.light, label: Text('Светла'), icon: Icon(Icons.light_mode_rounded, size: 18)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Тъмна'), icon: Icon(Icons.dark_mode_rounded, size: 18)),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => s.setTheme(v.first),
          ),
        ),
        _header(context, 'Език'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.language_rounded),
          title: Text('Български'),
          subtitle: Text('Засега това е единственият наличен език'),
        ),
        _header(context, 'Известия'),
        for (final e in kNotificationKeys.entries)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.value),
            value: s.notifications[e.key] ?? true,
            onChanged: (v) => s.setNotification(e.key, v),
          ),
        if (!s.firebaseReady)
          Text('Push известията изискват конфигуриран Firebase Cloud Messaging.', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
        _header(context, 'Поверителност'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.shield_outlined),
          title: Text('Защита на местоположението'),
          subtitle: Text('Опасни и чувствителни места се записват само с приблизителни координати. Точната позиция никога не се публикува.'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_toggle_off_rounded),
          title: const Text('Изчисти историята на търсенията'),
          onTap: () {
            s.clearRecents();
            showSnack(context, 'Историята е изчистена.');
          },
        ),
        _header(context, 'Акаунт'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline_rounded),
          title: Text(s.user?.username ?? 'Не си влязъл'),
          subtitle: Text(s.user?.isGuest == true ? 'Локален демо профил' : (s.user?.email ?? '')),
        ),
        if (s.user != null && s.user!.isGuest != true)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Изход'),
            onTap: () async {
              await s.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        _header(context, 'За приложението'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('За VANDARNA'),
          onTap: () => showAbout(context),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.tag_rounded),
          title: Text('Версия'),
          trailing: Text('1.0.0'),
        ),
      ]),
    );
  }
}
