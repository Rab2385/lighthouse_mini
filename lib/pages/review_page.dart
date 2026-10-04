import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/good_thing.dart';
import '../state/lighthouse_controller.dart';
import '../util/review_text.dart';
import '../util/year_heatmap.dart';
import '../widgets/page_title.dart';

enum _RangePreset { thisMonth, last7Days, last30Days, thisYear, custom }

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  _RangePreset _preset = _RangePreset.thisMonth;
  late DateTimeRange _range;

  AppStrings get _strings => widget.controller.strings;

  @override
  void initState() {
    super.initState();
    _range = _rangeForPreset(_RangePreset.thisMonth);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTimeRange _rangeForPreset(_RangePreset preset) {
    final today = widget.controller.today;

    switch (preset) {
      case _RangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: DateTime(today.year, today.month + 1, 0),
        );
      case _RangePreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _RangePreset.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case _RangePreset.thisYear:
        return DateTimeRange(
          start: DateTime(today.year, 1, 1),
          end: DateTime(today.year, 12, 31),
        );
      case _RangePreset.custom:
        return _range;
    }
  }

  void _applyPreset(_RangePreset preset) {
    if (preset == _RangePreset.custom) {
      _pickCustomRange();
      return;
    }

    setState(() {
      _preset = preset;
      _range = _rangeForPreset(preset);
    });
  }

  Future<void> _pickCustomRange() async {
    final firstDate = DateTime(widget.controller.today.year - 5);
    final lastDate = widget.controller.maximumFutureDate;

    final safeStart = _range.start.isBefore(firstDate)
        ? firstDate
        : _range.start;
    final safeEnd = _range.end.isAfter(lastDate) ? lastDate : _range.end;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(start: safeStart, end: safeEnd),
      helpText: _strings.pickRange,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _preset = _RangePreset.custom;
      _range = DateTimeRange(
        start: _dateOnly(picked.start),
        end: _dateOnly(picked.end),
      );
    });
  }

  /// From a box in the year card: look at that month in the whole Review.
  void _showMonth(DateTime month) {
    setState(() {
      _preset = _RangePreset.custom;
      _range = DateTimeRange(
        start: DateTime(month.year, month.month, 1),
        end: DateTime(month.year, month.month + 1, 0),
      );
    });
  }

  int _rangeLengthInDays(DateTime start, DateTime end) {
    // Count in UTC so daylight-saving transitions never shift the total.
    final utcStart = DateTime.utc(start.year, start.month, start.day);
    final utcEnd = DateTime.utc(end.year, end.month, end.day);

    if (utcEnd.isBefore(utcStart)) {
      return 0;
    }

    return utcEnd.difference(utcStart).inDays + 1;
  }

  String _formatRange(DateTimeRange range) {
    final start = range.start;
    final end = range.end;

    final lastDayOfStartMonth = DateTime(start.year, start.month + 1, 0).day;
    final isWholeMonth =
        start.day == 1 &&
        end.year == start.year &&
        end.month == start.month &&
        end.day == lastDayOfStartMonth;

    if (isWholeMonth) {
      return _strings.monthAndYear(start);
    }

    final isWholeYear =
        start.month == 1 &&
        start.day == 1 &&
        end.year == start.year &&
        end.month == 12 &&
        end.day == 31;

    if (isWholeYear) {
      return '${start.year}';
    }

    return '${_strings.formatDate(start)} – ${_strings.formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final controller = widget.controller;
        final today = controller.today;

        final start = _range.start;
        final end = _range.end;

        final entries = controller.goodThingsInRange(start, end);

        final totalRangeDays = _rangeLengthInDays(start, end);

        // Habits can only be completed up to today, so the percentage uses the
        // part of the range that has already happened as its denominator.
        final habitEnd = end.isAfter(today) ? today : end;
        final habitDays = _rangeLengthInDays(start, habitEnd);

        final recurring = _recurringEntries(entries);

        // Reading back is about what already happened; Ahead entries stay on
        // the Good Things page.
        final pastEntries = entries
            .where((entry) => !entry.date.isAfter(today))
            .toList();

        final strings = _strings;

        return Column(
          children: [
            _ReviewHeader(
              strings: strings,
              rangeLabel: _formatRange(_range),
              rangeDays: totalRangeDays,
              elapsedDays: habitDays,
              year: today.year,
              preset: _preset,
              onPresetSelected: _applyPreset,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_preset == _RangePreset.thisYear) ...[
                      _YearCard(
                        controller: controller,
                        year: start.year,
                        onMonthSelected: _showMonth,
                      ),
                      const SizedBox(height: 18),
                    ],
                    _GoodThingsSection(
                      strings: strings,
                      entries: pastEntries,
                      periodLabel: _formatRange(_range),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: strings.habits,
                      child: controller.activeHabits.isEmpty
                          ? Text(strings.noActiveHabits)
                          : Column(
                              children: [
                                for (final habit in controller.activeHabits)
                                  _HabitReviewRow(
                                    emoji: habit.emoji,
                                    name: habit.name,
                                    total: controller.habitCompletionsInRange(
                                      habitId: habit.id,
                                      start: start,
                                      end: habitEnd,
                                    ),
                                    days: habitDays,
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: strings.recurringEntries,
                      child: recurring.isEmpty
                          ? Text(strings.noRecurring)
                          : Column(
                              children: [
                                for (final item in recurring)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.repeat),
                                    title: Text(item.text),
                                    trailing: Text(
                                      '${item.count}×',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_RecurringEntry> _recurringEntries(List<GoodThing> entries) {
    final counts = <String, _RecurringEntry>{};

    for (final entry in entries) {
      final key = entry.text.trim().toLowerCase();

      if (key.isEmpty) {
        continue;
      }

      final existing = counts[key];

      if (existing == null) {
        counts[key] = _RecurringEntry(text: entry.text.trim(), count: 1);
      } else {
        counts[key] = _RecurringEntry(
          text: existing.text,
          count: existing.count + 1,
        );
      }
    }

    final result = counts.values.where((entry) => entry.count > 1).toList()
      ..sort((first, second) => second.count.compareTo(first.count));

    return result.take(5).toList();
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.strings,
    required this.rangeLabel,
    required this.rangeDays,
    required this.elapsedDays,
    required this.year,
    required this.preset,
    required this.onPresetSelected,
  });

  final AppStrings strings;
  final String rangeLabel;
  final int rangeDays;

  /// Days of the range that have already happened. Below [rangeDays] whenever
  /// the range runs past today (e.g. the current month), and that's the number
  /// the habit bars are scored against — so the subtitle spells both out.
  final int elapsedDays;
  final int year;
  final _RangePreset preset;
  final ValueChanged<_RangePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final custom = preset == _RangePreset.custom;

    final daysText = elapsedDays >= rangeDays
        ? strings.rangeDays(rangeDays)
        : strings.daysElapsedOfRange(elapsedDays, rangeDays);

    final phone = isPhoneLayout(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, phone ? 12 : 24, 24, phone ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(title: strings.review, subtitle: '$rangeLabel · $daysText'),
          SizedBox(height: phone ? 8 : 14),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      _PresetChip(
                        label: strings.rangeThisMonth,
                        selected: preset == _RangePreset.thisMonth,
                        onSelected: () =>
                            onPresetSelected(_RangePreset.thisMonth),
                      ),
                      const SizedBox(width: 8),
                      _PresetChip(
                        label: strings.rangeLastDays(7),
                        selected: preset == _RangePreset.last7Days,
                        onSelected: () =>
                            onPresetSelected(_RangePreset.last7Days),
                      ),
                      const SizedBox(width: 8),
                      _PresetChip(
                        label: strings.rangeLastDays(30),
                        selected: preset == _RangePreset.last30Days,
                        onSelected: () =>
                            onPresetSelected(_RangePreset.last30Days),
                      ),
                      const SizedBox(width: 8),
                      _PresetChip(
                        label: '$year',
                        selected: preset == _RangePreset.thisYear,
                        onSelected: () =>
                            onPresetSelected(_RangePreset.thisYear),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onPresetSelected(_RangePreset.custom),
                isSelected: custom,
                tooltip: strings.pickRange,
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                style: IconButton.styleFrom(
                  backgroundColor: custom
                      ? colorScheme.secondaryContainer
                      : null,
                  foregroundColor: custom
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

/// Every Good Thing of the period to read back, grouped by day, with a
/// "copy as text" action. Long periods start folded to the newest days.
class _GoodThingsSection extends StatefulWidget {
  const _GoodThingsSection({
    required this.strings,
    required this.entries,
    required this.periodLabel,
  });

  final AppStrings strings;
  final List<GoodThing> entries;
  final String periodLabel;

  @override
  State<_GoodThingsSection> createState() => _GoodThingsSectionState();
}

class _GoodThingsSectionState extends State<_GoodThingsSection> {
  static const int _foldedDays = 5;

  bool _expanded = false;

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final text = goodThingsAsText(
      periodLabel: widget.periodLabel,
      entries: widget.entries,
      strings: widget.strings,
    );

    await Clipboard.setData(ClipboardData(text: text));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(widget.strings.copied)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final colorScheme = Theme.of(context).colorScheme;

    final days = <DateTime, List<GoodThing>>{};
    for (final entry in newestDayFirst(widget.entries)) {
      days.putIfAbsent(entry.date, () => []).add(entry);
    }

    final visibleDays = _expanded
        ? days.entries.toList()
        : days.entries.take(_foldedDays).toList();

    return _SectionCard(
      title: strings.goodThings,
      count: widget.entries.isEmpty ? null : widget.entries.length,
      child: widget.entries.isEmpty
          ? Text(strings.noGoodThingsInRange)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final day in visibleDays) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      strings.dayLabel(day.key),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final entry in day.value)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '·  ',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                          Expanded(child: Text(entry.text)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
                // After reading, not squeezed next to the title.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: Text(strings.copyAsText),
                    ),
                    if (days.length > _foldedDays)
                      TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          _expanded
                              ? strings.showLess
                              : strings.showAll(widget.entries.length),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.count});

  final String title;
  final Widget child;

  /// Shown faintly after the title.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: title,
                      children: [
                        if (count != null)
                          TextSpan(
                            text: '  $count',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _HabitReviewRow extends StatelessWidget {
  const _HabitReviewRow({
    required this.emoji,
    required this.name,
    required this.total,
    required this.days,
  });

  final String emoji;
  final String name;
  final int total;
  final int days;

  @override
  Widget build(BuildContext context) {
    final progress = days == 0 ? 0.0 : (total / days).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          // Name and bar share the width, so on a 320 px phone the bar
          // doesn't shrink to a sliver next to a fixed-width name.
          Expanded(
            flex: 3,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              '$total / $days',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Twelve month boxes per row — Good Things and every active habit — shaded
/// by how often it happened. A calm picture of the year, no numbers to beat.
class _YearCard extends StatelessWidget {
  const _YearCard({
    required this.controller,
    required this.year,
    required this.onMonthSelected,
  });

  final LighthouseController controller;
  final int year;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final strings = controller.strings;
    final today = controller.today;
    final colorScheme = Theme.of(context).colorScheme;
    final months = [for (var m = 1; m <= 12; m++) DateTime(year, m)];

    List<_YearCell> cells(int Function(DateTime start, DateTime end) count) {
      return [
        for (final month in months)
          () {
            final days = scoredDaysInMonth(month, today);
            final done = days == 0
                ? 0
                : count(month, DateTime(month.year, month.month, days));
            return _YearCell(month: month, done: done, days: days);
          }(),
      ];
    }

    return _SectionCard(
      title: strings.yearCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: _YearGrid(
              children: [
                for (final month in months)
                  Text(
                    strings.monthNames[month.month - 1].substring(0, 1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _YearRow(
            icon: Icons.auto_awesome,
            name: strings.goodThings,
            cells: cells(controller.goodThingDaysInRange),
            strings: strings,
            onMonthSelected: onMonthSelected,
          ),
          for (final habit in controller.activeHabits)
            _YearRow(
              emoji: habit.emoji,
              name: habit.name,
              cells: cells(
                (start, end) => controller.habitCompletionsInRange(
                  habitId: habit.id,
                  start: start,
                  end: end,
                ),
              ),
              strings: strings,
              onMonthSelected: onMonthSelected,
            ),
          const SizedBox(height: 2),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  strings.heatLess,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                for (var level = 0; level <= 4; level++)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: _heatDecoration(colorScheme, level, true),
                  ),
                const SizedBox(width: 3),
                Text(
                  strings.heatMore,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YearCell {
  const _YearCell({
    required this.month,
    required this.done,
    required this.days,
  });

  final DateTime month;
  final int done;

  /// 0 for a month that hasn't started yet.
  final int days;
}

/// Box colours: empty surface, then four steps towards the theme's primary,
/// so contrast holds in light and dark mode. Months still ahead are outlines.
BoxDecoration _heatDecoration(
  ColorScheme colorScheme,
  int level,
  bool started,
) {
  if (!started) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: colorScheme.outlineVariant),
    );
  }

  const steps = [0.0, 0.3, 0.55, 0.78, 1.0];
  final empty = colorScheme.surfaceContainerHighest;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(3),
    color: Color.lerp(empty, colorScheme.primary, steps[level]),
  );
}

/// Twelve equal columns with a small gap, shared by the month letters and
/// every row so they line up.
class _YearGrid extends StatelessWidget {
  const _YearGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({
    this.icon,
    this.emoji,
    required this.name,
    required this.cells,
    required this.strings,
    required this.onMonthSelected,
  });

  /// Shown before [name]: an icon for Good Things, the symbol for a habit.
  final IconData? icon;
  final String? emoji;
  final String name;
  final List<_YearCell> cells;
  final AppStrings strings;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, size: 16, color: colorScheme.primary)
                else
                  Text(emoji ?? '', style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _YearGrid(
            children: [
              for (final cell in cells)
                Tooltip(
                  message: strings.yearCellLabel(
                    name,
                    cell.month,
                    cell.done,
                    cell.days,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(3),
                    onTap: cell.days == 0
                        ? null
                        : () => onMonthSelected(cell.month),
                    child: Container(
                      height: 18,
                      decoration: _heatDecoration(
                        colorScheme,
                        heatLevel(cell.done, cell.days),
                        cell.days > 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringEntry {
  const _RecurringEntry({required this.text, required this.count});

  final String text;
  final int count;
}
