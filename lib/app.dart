import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'state/app_state.dart';
import 'ui/screens/shell.dart';
import 'ui/screens/splash_screen.dart';

class VandarnaApp extends StatelessWidget {
  const VandarnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: 'VANDARNA',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: s.themeMode,
      locale: const Locale('bg'),
      supportedLocales: const [Locale('bg')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: s.onboardingDone ? const Shell() : const SplashScreen(),
    );
  }
}
