import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../domain/models.dart';

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Very rounded surface used for list cards and panels.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 24, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: r,
        boxShadow: c.shadow,
        border: c.isDark ? Border.all(color: c.outline) : Border.all(color: c.outline.withValues(alpha: 0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(borderRadius: r, onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.size = 46, this.iconColor, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.chip,
        boxShadow: c.shadow,
        border: c.isDark ? Border.all(color: c.outline) : null,
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: size * 0.5, color: iconColor ?? c.text),
      ),
    );
  }
}

/// Full-width pill button (navy in light theme, indigo gradient in dark theme).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.trailing, this.busy = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon, trailing;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: c.buttonColors),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: busy
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: c.onAccent))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, size: 20, color: c.onAccent), const SizedBox(width: 8)],
                      Text(label, style: TextStyle(color: c.onAccent, fontSize: 16, fontWeight: FontWeight.w700)),
                      if (trailing != null) ...[const SizedBox(width: 8), Icon(trailing, size: 20, color: c.onAccent)],
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photo from an asset, a URL or a local file.
class BuildingImage extends StatelessWidget {
  const BuildingImage(this.path, {super.key, this.fit = BoxFit.cover});
  final String? path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final placeholder = Container(
      color: c.surfaceAlt,
      alignment: Alignment.center,
      child: Icon(Icons.apartment_rounded, color: c.textMuted, size: 32),
    );
    final p = path;
    if (p == null || p.isEmpty) return placeholder;
    Widget err(BuildContext _, Object __, StackTrace? ___) => placeholder;
    if (p.startsWith('assets/')) return Image.asset(p, fit: fit, errorBuilder: err);
    if (p.startsWith('http')) return Image.network(p, fit: fit, errorBuilder: err);
    return Image.file(File(p), fit: fit, errorBuilder: err);
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, this.color, {super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 52, color: c.textMuted),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, height: 1.4)),
          ],
        ]),
      ),
    );
  }
}

/// List card from the "Близки локации" reference screen.
class BuildingCard extends StatelessWidget {
  const BuildingCard({super.key, required this.building, required this.distanceMeters, required this.onTap});
  final Building building;
  final double distanceMeters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final b = building;
    return AppCard(
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(width: 96, height: 100, child: BuildingImage(b.photos.isEmpty ? null : b.photos.first)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(b.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.location_on_rounded, size: 16, color: c.pin),
              const SizedBox(width: 4),
              Expanded(child: Text('${formatKm(distanceMeters)} • ${b.neighborhood}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 13))),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              TagChip(b.safety.label, b.safety.color),
              TagChip(b.status.label, b.status.color),
            ]),
            const SizedBox(height: 4),
            Text('Добавена на ${formatDate(b.createdAt)}', style: TextStyle(color: c.textMuted, fontSize: 11.5)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: c.text),
        const SizedBox(width: 4),
      ]),
    );
  }
}
