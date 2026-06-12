import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/spacing.dart';
import '../../shared/models/calendar_event_model.dart';
import '../../shared/widgets/confidia_glow_button.dart';
import '../../shared/widgets/confidia_glow_chip.dart';
import '../../shared/widgets/confidia_modal_sheet.dart';
import '../../shared/widgets/confidia_switch.dart';
import '../../shared/widgets/confidia_text_field.dart';
import 'calendar_provider.dart';
import 'event_type_config.dart';

Future<void> showEventFormSheet(
  BuildContext context, {
  CalendarEventModel? event,
  DateTime? initialDay,
}) {
  return showConfidiaSheet<void>(
    context: context,
    title: event != null ? 'Modifier l\'événement' : 'Nouvel événement',
    child: _EventFormContent(event: event, initialDay: initialDay),
    actions: null,
  );
}

class _EventFormContent extends ConsumerStatefulWidget {
  final CalendarEventModel? event;
  final DateTime? initialDay;

  const _EventFormContent({this.event, this.initialDay});

  @override
  ConsumerState<_EventFormContent> createState() => _EventFormContentState();
}

class _EventFormContentState extends ConsumerState<_EventFormContent> {
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
      useRootNavigator: true,
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
          if (_end.isBefore(_start)) _end = _start;
        } else {
          _end = DateTime(date.year, date.month, date.day, 23, 59);
        }
      });
      return;
    }

    final time = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _start = dt;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
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
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      start: _start,
      end: _end,
      allDay: _allDay,
      eventType: _type,
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Type d\'événement', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: eventTypeConfigs(context.palette).map((cfg) {
              return ConfidiaGlowChip(
                label: cfg.label,
                icon: cfg.icon,
                accentColor: cfg.color,
                selected: _type == cfg.type,
                onTap: () => setState(() => _type = cfg.type),
              );
            }).toList(),
          ),
          const SizedBox(height: ConfidiaSpacing.md),
          ConfidiaTextFormField(
            controller: _titleCtrl,
            labelText: 'Titre',
            prefixIcon: Icons.title_rounded,
            validator: (v) => v?.trim().isEmpty == true ? 'Requis' : null,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaTextFormField(
            controller: _descCtrl,
            labelText: 'Description',
            prefixIcon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaTextFormField(
            controller: _locationCtrl,
            labelText: 'Lieu (optionnel)',
            prefixIcon: Icons.place_outlined,
          ),
          const SizedBox(height: ConfidiaSpacing.sm),
          ConfidiaSwitchTile(
            contentPadding: EdgeInsets.zero,
            title: 'Toute la journée',
            value: _allDay,
            onChanged: (v) => setState(() => _allDay = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.play_arrow_rounded, size: 20),
            title: const Text('Début'),
            subtitle: Text(_allDay
                ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_start)
                : DateFormat('EEEE d MMM yyyy · HH:mm', 'fr_FR').format(_start)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => _pickDateTime(isStart: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.stop_rounded, size: 20),
            title: const Text('Fin'),
            subtitle: Text(_allDay
                ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_end)
                : DateFormat('EEEE d MMM yyyy · HH:mm', 'fr_FR').format(_end)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => _pickDateTime(isStart: false),
          ),
          const SizedBox(height: ConfidiaSpacing.lg),
          ConfidiaGlowButton(
            label: _isEdit ? 'Enregistrer' : 'Créer l\'événement',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save,
          ),
          if (_isEdit) ...[
            const SizedBox(height: ConfidiaSpacing.sm),
            ConfidiaGlowButton(
              label: 'Supprimer',
              icon: Icons.delete_outline_rounded,
              primary: false,
              expand: true,
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
    );
  }
}
