import 'package:flutter/material.dart';

import '../models/good_thing.dart';
import '../state/lighthouse_controller.dart';

enum _RangePreset { thisMonth, last7Days, last30Days, thisYear, custom }

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  static const List<String> _monthNames = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  _RangePreset _preset = _RangePreset.thisMonth;
  late DateTimeRange _range;

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
      helpText: 'Zeitraum wählen',
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

  int _rangeLengthInDays(DateTime start, DateTime end) {
    // Count in UTC so daylight-saving transitions never shift the total.
    final utcStart = DateTime.utc(start.year, start.month, start.day);
    final utcEnd = DateTime.utc(end.year, end.month, end.day);

    if (utcEnd.isBefore(utcStart)) {
      return 0;
    }

    return utcEnd.difference(utcStart).inDays + 1;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';
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
      return '${_monthNames[start.month - 1]} ${start.year}';
    }

    return '${_formatDate(start)} – ${_formatDate(end)}';
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

        final daysWithEntries = entries
            .map(
              (entry) =>
                  '${entry.date.year}-'
                  '${entry.date.month}-'
                  '${entry.date.day}',
            )
            .toSet()
            .length;

        final aheadCount = entries
            .where((entry) => entry.date.isAfter(today))
            .length;

        final totalRangeDays = _rangeLengthInDays(start, end);

        // Habits can only be completed up to today, so the percentage uses the
        // part of the range that has already happened as its denominator.
        final habitEnd = end.isAfter(today) ? today : end;
        final habitDays = _rangeLengthInDays(start, habitEnd);

        final recurring = _recurringEntries(entries);

        return Column(
          children: [
            _ReviewHeader(
              rangeLabel: _formatRange(_range),
              rangeDays: totalRangeDays,
              preset: _preset,
              onPresetSelected: _applyPreset,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          icon: Icons.auto_awesome,
                          label: 'Good Things',
                          value: entries.length.toString(),
                        ),
                        _MetricCard(
                          icon: Icons.calendar_today,
                          label: 'Tage mit Einträgen',
                          value: daysWithEntries.toString(),
                        ),
                        _MetricCard(
                          icon: Icons.arrow_forward,
                          label: 'Ahead',
                          value: aheadCount.toString(),
                        ),
                        _MetricCard(
                          icon: Icons.grid_view,
                          label: 'Aktive Habits',
                          value: controller.activeHabits.length.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Habits',
                      child: controller.activeHabits.isEmpty
                          ? const Text('Noch keine aktiven Habits.')
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
                      title: 'Wiederkehrende Einträge',
                      child: recurring.isEmpty
                          ? const Text(
                              'Noch keine wiederkehrenden '
                              'Texte in diesem Zeitraum.',
                            )
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
    required this.rangeLabel,
    required this.rangeDays,
    required this.preset,
    required this.onPresetSelected,
  });

  final String rangeLabel;
  final int rangeDays;
  final _RangePreset preset;
  final ValueChanged<_RangePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$rangeLabel · '
            '$rangeDays ${rangeDays == 1 ? 'Tag' : 'Tage'}',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PresetChip(
                label: 'Dieser Monat',
                selected: preset == _RangePreset.thisMonth,
                onSelected: () => onPresetSelected(_RangePreset.thisMonth),
              ),
              _PresetChip(
                label: 'Letzte 7 Tage',
                selected: preset == _RangePreset.last7Days,
                onSelected: () => onPresetSelected(_RangePreset.last7Days),
              ),
              _PresetChip(
                label: 'Letzte 30 Tage',
                selected: preset == _RangePreset.last30Days,
                onSelected: () => onPresetSelected(_RangePreset.last30Days),
              ),
              _PresetChip(
                label: 'Dieses Jahr',
                selected: preset == _RangePreset.thisYear,
                onSelected: () => onPresetSelected(_RangePreset.thisYear),
              ),
              OutlinedButton.icon(
                onPressed: () => onPresetSelected(_RangePreset.custom),
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(
                  preset == _RangePreset.custom
                      ? 'Zeitraum: $rangeLabel'
                      : 'Zeitraum wählen',
                ),
                style: preset == _RangePreset.custom
                    ? OutlinedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                      )
                    : null,
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
          SizedBox(
            width: 110,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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

class _RecurringEntry {
  const _RecurringEntry({required this.text, required this.count});

  final String text;
  final int count;
}
