import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/calendar_event_model.dart';
import '../../shared/widgets/confidia_button.dart';
import 'calendar_provider.dart';
import 'event_type_config.dart';

Future<void> showEventFormSheet(
  BuildContext context, {
  CalendarEventModel? event,
  DateTime? initialDay,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EventFormSheet(event: event, initialDay: initialDay),
  );
}

class _EventFormSheet extends ConsumerStatefulWidget {
  final CalendarEventModel? event;
  final DateTime? initialDay;

  const _EventFormSheet({this.event, this.initialDay});

  @override
  ConsumerState<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<_EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late EventType _type;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    final day = widget.initialDay ?? DateTime.now();
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _type = e?.eventType ?? EventType.deadline;
    _allDay = e?.allDay ?? false;
    _start = e?.start ?? DateTime(day.year, day.month, day.day, 9);
    _end = e?.end ?? DateTime(day.year, day.month, day.day, 10);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
    );
    if (date == null || !mounted) return;

    if (_allDay) {
      setState(() {
        if (isStart) {
          _start = DateTime(date.year, date.month, date.day);
          _end = DateTime(date.year, date.month, date.day, 23, 59);
        } else {
          _end = DateTime(date.year, date.month, date.day, 23, 59);
        }
      });
      return;
    }

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _start = dt;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = dt;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(calendarProvider.notifier);
    final model = notifier.buildEvent(
      id: widget.event?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      start: _start,
      end: _allDay ? DateTime(_end.year, _end.month, _end.day, 23, 59) : _end,
      eventType: _type,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      allDay: _allDay,
      documentId: widget.event?.documentId,
    );
    if (_isEdit) {
      notifier.update(model);
    } else {
      notifier.add(model);
    }
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'événement ?'),
        content: Text('« ${widget.event!.title} » sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ConfidiaColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(calendarProvider.notifier).delete(widget.event!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14141E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ConfidiaColors.border(isDark)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ConfidiaSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(_isEdit ? 'Modifier l\'événement' : 'Nouvel événement', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: ConfidiaSpacing.md),
                Text('Type d\'événement', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: eventTypeConfigs.map((cfg) {
                    final selected = _type == cfg.type;
                    return FilterChip(
                      selected: selected,
                      showCheckmark: false,
                      avatar: Icon(cfg.icon, size: 16, color: selected ? Colors.white : cfg.color),
                      label: Text(cfg.label),
                      selectedColor: cfg.color,
                      labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: selected ? FontWeight.w600 : null),
                      onSelected: (_) => setState(() => _type = cfg.type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: ConfidiaSpacing.md),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre', prefixIcon: Icon(Icons.title_rounded)),
                  validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: ConfidiaSpacing.sm),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_rounded)),
                  maxLines: 2,
                ),
                const SizedBox(height: ConfidiaSpacing.sm),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Lieu (optionnel)', prefixIcon: Icon(Icons.place_outlined)),
                ),
                const SizedBox(height: ConfidiaSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Toute la journée'),
                  value: _allDay,
                  onChanged: (v) => setState(() => _allDay = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.play_arrow_rounded),
                  title: const Text('Début'),
                  subtitle: Text(_allDay
                      ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_start)
                      : DateFormat('EEEE d MMM yyyy · HH:mm', 'fr_FR').format(_start)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickDateTime(isStart: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.stop_rounded),
                  title: const Text('Fin'),
                  subtitle: Text(_allDay
                      ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_end)
                      : DateFormat('EEEE d MMM yyyy · HH:mm', 'fr_FR').format(_end)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickDateTime(isStart: false),
                ),
                const SizedBox(height: ConfidiaSpacing.lg),
                ConfidiaButton(label: _isEdit ? 'Enregistrer' : 'Créer l\'événement', icon: Icons.check_rounded, onPressed: _save),
                if (_isEdit) ...[
                  const SizedBox(height: ConfidiaSpacing.sm),
                  ConfidiaButton(
                    label: 'Supprimer',
                    icon: Icons.delete_outline_rounded,
                    outlined: true,
                    onPressed: _confirmDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
