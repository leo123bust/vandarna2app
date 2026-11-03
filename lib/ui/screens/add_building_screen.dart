import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/location_service.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'building_details_screen.dart';

class AddBuildingScreen extends StatefulWidget {
  const AddBuildingScreen({super.key});

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _history = TextEditingController();
  final _period = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  String? _neighborhood;
  String _type = kBuildingTypes.first;
  Safety _safety = Safety.medium;
  bool _hideExact = false;
  bool _demolished = false;
  bool _busy = false;
  final List<String> _photos = [];

  @override
  void dispose() {
    for (final c in [_name, _desc, _address, _history, _period, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String v) => double.tryParse(v.trim().replaceAll(',', '.'));

  Future<void> _pickPhotos() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1920);
    if (files.isEmpty) return;
    setState(() {
      _photos.addAll(files.map((f) => f.path).where((p) => !_photos.contains(p)));
      if (_photos.length > 8) _photos.removeRange(8, _photos.length);
    });
  }

  Future<void> _locate() async {
    final p = await LocationService.current();
    if (!mounted) return;
    if (p == null) {
      showSnack(context, 'GPS не е достъпен. Включи местоположението или въведи координати ръчно.');
      return;
    }
    setState(() {
      _lat.text = p.latitude.toStringAsFixed(5);
      _lng.text = p.longitude.toStringAsFixed(5);
    });
  }

  void _reset() {
    _form.currentState?.reset();
    for (final c in [_name, _desc, _address, _history, _period, _lat, _lng]) {
      c.clear();
    }
    setState(() {
      _neighborhood = null;
      _type = kBuildingTypes.first;
      _safety = Safety.medium;
      _hideExact = false;
      _demolished = false;
      _photos.clear();
    });
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    if (!_form.currentState!.validate()) return;
    if (_photos.isEmpty) {
      showSnack(context, 'Добави поне една снимка.');
      return;
    }
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;

    final lat = _num(_lat.text)!, lng = _num(_lng.text)!;
    final dup = s.findDuplicate(_name.text, LatLng(lat, lng));
    if (dup != null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Възможен дубликат'),
          content: Text('Вече има запис „${dup.name}" със същото име или на същото място. Сигурен ли си, че това е различна сграда?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отказ')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Различна е')),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      await s.submitBuilding(
        name: _name.text,
        description: _desc.text,
        neighborhood: _neighborhood!,
        address: _address.text,
        lat: lat,
        lng: lng,
        safety: _safety,
        type: _type,
        period: _period.text,
        history: _history.text,
        hideExact: _hideExact,
        demolished: _demolished,
        photoPaths: List.of(_photos),
      );
      if (!mounted) return;
      _reset();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, size: 40),
          title: const Text('Изпратено за проверка'),
          content: const Text('Статус: „Очаква проверка". Записът ще стане „Проверена", когато го потвърдят други потребители. '
              'Не можеш да потвърдиш собствената си публикация.'),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Разбрах'))],
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, e is StateError ? e.message : 'Грешка при изпращане: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      bottom: false,
      child: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          const Text('Добави сграда', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(18)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.shield_outlined, color: c.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Не влизай в частна или опасна собственост. Описвай само състоянието на мястото – не начини за достъп. '
                  'Всеки запис минава през проверка от общността.',
                  style: TextStyle(color: c.textMuted, height: 1.4, fontSize: 13.5),
                ),
              ),
            ]),
          ),
          _section('Основна информация'),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Име на сградата'),
            validator: (v) => (v ?? '').trim().length < 3 ? 'Въведи име (поне 3 символа)' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _desc,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Описание'),
            validator: (v) => (v ?? '').trim().length < 20 ? 'Опиши сградата (поне 20 символа)' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _neighborhood,
            decoration: const InputDecoration(labelText: 'Квартал'),
            items: [for (final n in kNeighborhoods) DropdownMenuItem(value: n, child: Text(n))],
            onChanged: (v) => setState(() => _neighborhood = v),
            validator: (v) => v == null ? 'Избери квартал' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Адрес'),
            validator: (v) => (v ?? '').trim().length < 3 ? 'Въведи адрес или ориентир' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Тип'),
                items: [for (final t in kBuildingTypes) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(controller: _period, decoration: const InputDecoration(labelText: 'Период', hintText: '1970 – 1990')),
            ),
          ]),
          _section('Местоположение'),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _lat,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Ширина'),
                validator: (v) {
                  final n = _num(v ?? '');
                  if (n == null) return 'Невалидно';
                  return (n < 43.0 || n > 43.4) ? 'Извън Варна' : null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lng,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Дължина'),
                validator: (v) {
                  final n = _num(v ?? '');
                  if (n == null) return 'Невалидно';
                  return (n < 27.6 || n > 28.2) ? 'Извън Варна' : null;
                },
              ),
            ),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _locate, icon: const Icon(Icons.my_location_rounded, size: 18), label: const Text('Определи автоматично с GPS')),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _hideExact || _safety == Safety.dangerous,
            onChanged: _safety == Safety.dangerous ? null : (v) => setState(() => _hideExact = v),
            title: const Text('Скрий точното местоположение'),
            subtitle: const Text('Ще се запази само приблизителна позиция. Задължително за „Опасно".'),
          ),
          _section('Безопасност'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final v in Safety.values)
              ChoiceChip(
                label: Text(v.label),
                selected: _safety == v,
                selectedColor: v.color.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => _safety = v),
              ),
          ]),
          const SizedBox(height: 6),
          Text('Описва състоянието и опасностите на мястото, не възможности за влизане.', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _demolished,
            onChanged: (v) => setState(() => _demolished = v),
            title: const Text('Сградата вече е съборена'),
            subtitle: const Text('Записът ще остане в историческия архив.'),
          ),
          _section('Снимки (${_photos.length}/8)'),
          SizedBox(
            height: 92,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              InkWell(
                onTap: _pickPhotos,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 92,
                  decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(18)),
                  child: Icon(Icons.add_photo_alternate_outlined, color: c.textMuted, size: 30),
                ),
              ),
              for (final p in _photos)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Stack(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(width: 92, height: 92, child: BuildingImage(p))),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => setState(() => _photos.remove(p)),
                        child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
          _section('Историческа информация'),
          TextFormField(
            controller: _history,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'Предишна функция, важни дати, събаряне, реставрация... (по желание)'),
          ),
          const SizedBox(height: 10),
          Text('Дата на добавяне: ${formatDate(DateTime.now())}', style: TextStyle(color: c.textMuted, fontSize: 13)),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Изпрати за проверка', icon: Icons.send_rounded, busy: _busy, onPressed: _submit),
        ]),
      ),
    );
  }
}
