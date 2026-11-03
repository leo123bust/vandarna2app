import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';

void openBuilding(BuildContext context, Building b) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BuildingDetailsScreen(buildingId: b.id)));

/// Opens the login screen when needed. Returns true when a user is available afterwards.
Future<bool> ensureLoggedIn(BuildContext context) async {
  final s = context.read<AppState>();
  if (s.user != null) return true;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
  return context.mounted && context.read<AppState>().user != null;
}

class BuildingDetailsScreen extends StatefulWidget {
  const BuildingDetailsScreen({super.key, required this.buildingId});
  final String buildingId;

  @override
  State<BuildingDetailsScreen> createState() => _BuildingDetailsScreenState();
}

class _BuildingDetailsScreenState extends State<BuildingDetailsScreen> {
  int _page = 0;

  Future<void> _toggleFavorite(Building b) async {
    if (!await ensureLoggedIn(context)) return;
    await context.read<AppState>().toggleFavorite(b);
  }

  Future<void> _verify(Building b) async {
    final s = context.read<AppState>();
    if (s.user == null && !await ensureLoggedIn(context)) return;
    final reason = s.verifyBlockReason(b);
    if (reason != null) {
      showSnack(context, reason);
      return;
    }
    try {
      await s.verify(b);
      if (mounted) showSnack(context, 'Благодарим! Потвърждението е записано.');
    } catch (e) {
      if (mounted) showSnack(context, e is StateError ? e.message : 'Грешка: $e');
    }
  }

  Future<void> _report(Building b) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Докладвай проблем', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          ),
          for (final t in kReportTypes)
            ListTile(leading: const Icon(Icons.flag_outlined), title: Text(t), onTap: () => Navigator.of(ctx).pop(t)),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (type == null || !mounted) return;
    try {
      await context.read<AppState>().report(b, type);
      if (mounted) showSnack(context, 'Докладът е изпратен.');
    } catch (e) {
      if (mounted) showSnack(context, e is StateError ? e.message : 'Грешка: $e');
    }
  }

  Future<void> _addHistory(Building b) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добави историческа информация'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          minLines: 3,
          decoration: const InputDecoration(hintText: 'Предишна функция, дати, събаряне, реставрация...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отказ')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim().length >= 10 ? ctrl.text.trim() : null),
            child: const Text('Запази'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || !mounted) return;
    try {
      await context.read<AppState>().addHistory(b, text);
      if (mounted) showSnack(context, 'Историческият запис е добавен.');
    } catch (e) {
      if (mounted) showSnack(context, e is StateError ? e.message : 'Грешка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    final found = s.buildings.where((x) => x.id == widget.buildingId);
    if (found.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.apartment_rounded, title: 'Сградата не е намерена'));
    }
    final b = found.first;
    final photoCount = max(1, b.photos.length);
    final progress = (b.verifiedBy.length / kVerificationsNeeded).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(children: [
        // gallery
        SizedBox(
          height: 340,
          width: double.infinity,
          child: Stack(children: [
            PageView.builder(
              itemCount: photoCount,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => BuildingImage(b.photos.isEmpty ? null : b.photos[i]),
            ),
            if (photoCount > 1)
              Positioned(
                bottom: 44,
                left: 0,
                right: 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < photoCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: i == _page ? 1 : 0.55), borderRadius: BorderRadius.circular(4)),
                    ),
                ]),
              ),
          ]),
        ),
        // content sheet
        Positioned.fill(
          top: 300,
          child: Container(
            decoration: BoxDecoration(color: c.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 12), children: [
                  Text(b.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 18, color: c.pin),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${formatKm(s.distanceTo(b))} • ${b.neighborhood}${b.approximate ? ' • приблизително' : ''}',
                        style: TextStyle(fontSize: 15.5, color: c.textMuted),
                      ),
                    ),
                  ]),
                  if (b.createdBy == 'demo') ...[
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: TagChip('Примерен запис (демо)', c.textMuted)),
                  ],
                  const SizedBox(height: 14),
                  Text(b.description, style: TextStyle(fontSize: 16.5, height: 1.45, color: c.textMuted)),
                  const SizedBox(height: 16),
                  Divider(color: c.outline),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: c.text),
                    const SizedBox(width: 8),
                    const Text('Информация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 8),
                  _InfoRow(Icons.business_outlined, 'Тип', Text(b.type, style: _valueStyle)),
                  if (b.period.isNotEmpty) _InfoRow(Icons.calendar_today_outlined, 'Период', Text(b.period, style: _valueStyle)),
                  _InfoRow(Icons.warning_amber_rounded, 'Състояние', Text(b.demolished ? 'Съборена' : 'Изоставена', style: _valueStyle)),
                  _InfoRow(Icons.shield_outlined, 'Безопасност', TagChip(b.safety.label, b.safety.color)),
                  _InfoRow(Icons.verified_outlined, 'Проверка', TagChip(b.status.label, b.status.color)),
                  _InfoRow(Icons.place_outlined, 'Адрес', Flexible(child: Text(b.address, textAlign: TextAlign.end, style: _valueStyle))),
                  _InfoRow(Icons.event_outlined, 'Добавена на', Text(formatDate(b.createdAt), style: _valueStyle)),
                  _InfoRow(Icons.update_rounded, 'Последна проверка', Text(b.lastVerifiedAt == null ? '—' : formatDate(b.lastVerifiedAt!), style: _valueStyle)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('Потвърждения от общността', style: TextStyle(color: c.textMuted, fontSize: 14)),
                    const Spacer(),
                    Text('${b.verifiedBy.length} / $kVerificationsNeeded', style: _valueStyle),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: c.surfaceAlt, color: c.accent),
                  ),
                  const SizedBox(height: 8),
                  Text('Статусът „Безопасност" описва състоянието и опасностите на мястото – не е покана за влизане. '
                      'Не влизай в частна или опасна собственост.',
                      style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.4)),
                  const SizedBox(height: 18),
                  Row(children: [
                    const Icon(Icons.history_edu_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Исторически архив', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                    TextButton.icon(onPressed: () => _addHistory(b), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Добави')),
                  ]),
                  if (b.history.isEmpty)
                    Text('Още няма исторически данни. Добави предишна функция, дати или снимки.', style: TextStyle(color: c.textMuted, height: 1.4))
                  else
                    for (final h in b.history)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(18)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h.text, style: const TextStyle(height: 1.4)),
                          const SizedBox(height: 6),
                          Text(formatDate(h.date), style: TextStyle(fontSize: 12, color: c.textMuted)),
                        ]),
                      ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _verify(b),
                        icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                        label: const Text('Потвърди'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _report(b),
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: const Text('Докладвай'),
                      ),
                    ),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: SafeArea(
                  top: false,
                  child: PrimaryButton(
                    label: 'Покажи на картата',
                    icon: Icons.location_on_outlined,
                    onPressed: b.demolished
                        ? null
                        : () {
                            s.requestFocus(b);
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                  ),
                ),
              ),
            ]),
          ),
        ),
        // top buttons
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Назад', onTap: () => Navigator.of(context).pop()),
                RoundIconButton(
                  icon: s.isFavorite(b.id) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  tooltip: 'Любима',
                  onTap: () => _toggleFavorite(b),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

const _valueStyle = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600);

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 20, color: c.textMuted),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: c.textMuted, fontSize: 14.5)),
        const Spacer(),
        value,
      ]),
    );
  }
}
