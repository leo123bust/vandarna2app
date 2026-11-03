import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../state/app_state.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

void showAbout(BuildContext context) => showAboutDialog(
      context: context,
      applicationName: 'VANDARNA',
      applicationVersion: '1.0.0',
      applicationLegalese: '© VANDARNA',
      children: const [
        SizedBox(height: 12),
        Text('Общностен архив на изоставени сгради във Варна. '
            'Приложението не насърчава влизане в частна или опасна собственост – '
            'наблюдавай отдалеч и спазвай закона.'),
        SizedBox(height: 8),
        Text('Карта: © OpenStreetMap, © CARTO.'),
      ],
    );

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final wordmark = GoogleFonts.manrope(
      fontSize: 54,
      letterSpacing: -1.5,
      fontWeight: c.isDark ? FontWeight.w500 : FontWeight.w800,
      color: c.text,
    );
    return Scaffold(
      body: Stack(children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 120,
          height: 280,
          child: CustomPaint(painter: CityPainter(c.isDark ? const Color(0xFF2A2D4A) : const Color(0xFFBCC4DE))),
        ),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 3),
            SizedBox(
              width: 220,
              height: 165,
              child: CustomPaint(
                painter: LogoPainter(
                  body: c.isDark ? Colors.white : const Color(0xFF0B1630),
                  pin: c.isDark ? c.pin : const Color(0xFF4F8BFF),
                  hole: c.bg,
                  outline: c.isDark,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('vandarna', style: wordmark),
            const SizedBox(height: 14),
            Text(
              'Открий изоставените\nсгради във Варна',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, height: 1.3, color: c.textMuted),
            ),
            const Spacer(flex: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: PrimaryButton(
                label: 'Започни',
                trailing: Icons.arrow_forward_rounded,
                onPressed: () async {
                  await context.read<AppState>().completeOnboarding();
                },
              ),
            ),
            TextButton(
              onPressed: () => showAbout(context),
              child: Text('За приложението', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ]),
    );
  }
}
