import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens/tokens.dart';
import 'confidia_glow_button.dart';
import 'confidia_modal_sheet.dart';
import 'confidia_tappable.dart';

/// Date picker (+ optional time) in CONFIDIA / macOS style.
/// Reuses [showConfidiaSheet]: same blur, slide, and barrier.
/// More compact than the parent sheet for a stacked overlay effect.
Future<DateTime?> showConfidiaDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  bool includeTime = true,
  String? title,
}) {
  final selected = ValueNotifier<DateTime>(initial);
  return showConfidiaSheet<DateTime>(
    context: context,
    title: title ?? (includeTime ? 'Date et heure' : 'Sélectionner une date'),
    maxWidth: 400,
    maxHeightFactor: 0.86,
    child: _ConfidiaDateTimePickerBody(
      initial: initial,
      includeTime: includeTime,
      selected: selected,
    ),
    actions: [
      _DateTimePickerActions(selected: selected),
    ],
  ).whenComplete(selected.dispose);
}

class _ConfidiaDateTimePickerBody extends StatefulWidget {
  final DateTime initial;
  final bool includeTime;
  final ValueNotifier<DateTime> selected;

  const _ConfidiaDateTimePickerBody({
    required this.initial,
    required this.includeTime,
    required this.selected,
  });

  @override
  State<_ConfidiaDateTimePickerBody> createState() => _ConfidiaDateTimePickerBodyState();
}

class _ConfidiaDateTimePickerBodyState extends State<_ConfidiaDateTimePickerBody> {
  late DateTime _visibleMonth;
  late DateTime _selected;
  late int _hour;
  late int _minute;

  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _selected = DateTime(widget.initial.year, widget.initial.month, widget.initial.day);
    _visibleMonth = DateTime(widget.initial.year, widget.initial.month);
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _publish();
  }

  void _publish() {
    widget.selected.value = widget.includeTime
        ? DateTime(_selected.year, _selected.month, _selected.day, _hour, _minute)
        : DateTime(_selected.year, _selected.month, _selected.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<DateTime?> _daysInGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final lead = first.weekday - 1;
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (var i = 0; i < lead; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = context.palette.primary;
    final muted = AppColors.textSecondary(isDark);
    final today = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(_visibleMonth);
    final selectedLabel = DateFormat('EEE d MMM', 'fr_FR').format(_selected);
    final cells = _daysInGrid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedLabel,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: ConfidiaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel[0].toUpperCase() + monthLabel.substring(1),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            _NavIcon(icon: Icons.chevron_left_rounded, onTap: () => _shiftMonth(-1)),
            const SizedBox(width: 4),
            _NavIcon(icon: Icons.chevron_right_rounded, onTap: () => _shiftMonth(1)),
          ],
        ),
        const SizedBox(height: ConfidiaSpacing.sm),
        Row(
          children: _weekdays
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < cells.length / 7; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _DayCell(
                      day: cells[row * 7 + col],
                      selected: cells[row * 7 + col] != null &&
                          _isSameDay(cells[row * 7 + col]!, _selected),
                      isToday: cells[row * 7 + col] != null &&
                          _isSameDay(cells[row * 7 + col]!, today),
                      brand: brand,
                      onTap: cells[row * 7 + col] == null
                          ? null
                          : () => setState(() {
                                _selected = cells[row * 7 + col]!;
                                _publish();
                              }),
                    ),
                  ),
              ],
            ),
          ),
        if (widget.includeTime) ...[
          const SizedBox(height: ConfidiaSpacing.sm),
          Divider(height: 1, color: AppBorders.subtle(isDark).color),
          const SizedBox(height: ConfidiaSpacing.sm),
          Text(
            'Heure',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeUnit(
                value: _hour,
                max: 23,
                onChanged: (v) => setState(() {
                  _hour = v;
                  _publish();
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ':',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                ),
              ),
              _TimeUnit(
                value: _minute,
                max: 59,
                step: 5,
                onChanged: (v) => setState(() {
                  _minute = v;
                  _publish();
                }),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DateTimePickerActions extends StatelessWidget {
  final ValueNotifier<DateTime> selected;

  const _DateTimePickerActions({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ConfidiaGlowButton(
            label: 'Annuler',
            icon: Icons.close_rounded,
            primary: false,
            expand: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ConfidiaGlowButton(
            label: 'OK',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: () => Navigator.pop(context, selected.value),
          ),
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConfidiaTappable(
      onTap: onTap,
      pressScale: 0.92,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.fromBorderSide(AppBorders.subtle(isDark)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime? day;
  final bool selected;
  final bool isToday;
  final Color brand;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.brand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox(height: 36);

    final fg = selected
        ? Colors.white
        : (isToday ? brand : AppColors.textPrimary(Theme.of(context).brightness == Brightness.dark));

    return ConfidiaTappable(
      onTap: onTap,
      pressScale: 0.9,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 36,
        child: Center(
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? brand : Colors.transparent,
              border: isToday && !selected
                  ? Border.all(color: brand.withValues(alpha: 0.55), width: 1.2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day!.day}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fg,
                    fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _TimeUnit({
    required this.value,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  void _bump(int delta) {
    final next = (value + delta * step) % (max + 1);
    onChanged(next < 0 ? next + max + 1 : next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = value.toString().padLeft(2, '0');

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface2(isDark).withValues(alpha: isDark ? 0.55 : 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.fromBorderSide(AppBorders.subtle(isDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConfidiaTappable(
            onTap: () => _bump(1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: const SizedBox(
              height: 28,
              width: double.infinity,
              child: Icon(Icons.keyboard_arrow_up_rounded, size: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          ConfidiaTappable(
            onTap: () => _bump(-1),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: const SizedBox(
              height: 28,
              width: double.infinity,
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
