import 'package:flutter/material.dart';

import '../models/good_thing.dart';
import '../state/lighthouse_controller.dart';
import '../widgets/month_header.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.controller,
  });

  final LighthouseController controller;

  @override
  State<ReviewPage> createState() =>
      _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final today = widget.controller.today;
    _selectedMonth = DateTime(
      today.year,
      today.month,
    );
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _showNextMonth() {
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    );

    if (nextMonth.isAfter(
      widget.controller.maximumFutureMonth,
    )) {
      return;
    }

    setState(() {
      _selectedMonth = nextMonth;
    });
  }

  void _showCurrentMonth() {
    final today = widget.controller.today;

    setState(() {
      _selectedMonth = DateTime(
        today.year,
        today.month,
      );
    });
  }

  bool get _canShowNextMonth {
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    );

    return !nextMonth.isAfter(
      widget.controller.maximumFutureMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final entries = widget.controller
            .goodThingsForMonth(_selectedMonth);

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
            .where(
              (entry) => entry.date
                  .isAfter(widget.controller.today),
            )
            .length;

        final recurring =
            _recurringEntries(entries);

        return Column(
          children: [
            MonthHeader(
              title: 'Review',
              subtitle:
                  'Ein ruhiger Blick auf deinen Monat.',
              selectedMonth: _selectedMonth,
              onPreviousMonth:
                  _showPreviousMonth,
              onNextMonth:
                  _canShowNextMonth
                      ? _showNextMonth
                      : null,
              onToday: _showCurrentMonth,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  40,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          icon:
                              Icons.auto_awesome,
                          label: 'Good Things',
                          value:
                              entries.length.toString(),
                        ),
                        _MetricCard(
                          icon:
                              Icons.calendar_today,
                          label:
                              'Tage mit Einträgen',
                          value: daysWithEntries
                              .toString(),
                        ),
                        _MetricCard(
                          icon:
                              Icons.arrow_forward,
                          label: 'Ahead',
                          value:
                              aheadCount.toString(),
                        ),
                        _MetricCard(
                          icon:
                              Icons.grid_view,
                          label:
                              'Aktive Habits',
                          value: widget.controller
                              .activeHabits.length
                              .toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Habits',
                      child: widget.controller
                              .activeHabits.isEmpty
                          ? const Text(
                              'Noch keine aktiven Habits.',
                            )
                          : Column(
                              children: [
                                for (final habit
                                    in widget
                                        .controller
                                        .activeHabits)
                                  _HabitReviewRow(
                                    emoji:
                                        habit.emoji,
                                    name: habit.name,
                                    total: widget
                                        .controller
                                        .habitTotalForMonth(
                                      habitId:
                                          habit.id,
                                      selectedMonth:
                                          _selectedMonth,
                                    ),
                                    daysInMonth:
                                        DateTime(
                                      _selectedMonth
                                          .year,
                                      _selectedMonth
                                              .month +
                                          1,
                                      0,
                                    ).day,
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title:
                          'Wiederkehrende Einträge',
                      child: recurring.isEmpty
                          ? const Text(
                              'Noch keine wiederkehrenden '
                              'Texte in diesem Monat.',
                            )
                          : Column(
                              children: [
                                for (final item
                                    in recurring)
                                  ListTile(
                                    contentPadding:
                                        EdgeInsets.zero,
                                    leading:
                                        const Icon(
                                      Icons.repeat,
                                    ),
                                    title:
                                        Text(item.text),
                                    trailing: Text(
                                      '${item.count}×',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w700,
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

  List<_RecurringEntry> _recurringEntries(
    List<GoodThing> entries,
  ) {
    final counts = <String, _RecurringEntry>{};

    for (final entry in entries) {
      final key = entry.text.trim().toLowerCase();

      if (key.isEmpty) {
        continue;
      }

      final existing = counts[key];

      if (existing == null) {
        counts[key] = _RecurringEntry(
          text: entry.text.trim(),
          count: 1,
        );
      } else {
        counts[key] = _RecurringEntry(
          text: existing.text,
          count: existing.count + 1,
        );
      }
    }

    final result = counts.values
        .where((entry) => entry.count > 1)
        .toList()
      ..sort(
        (first, second) =>
            second.count.compareTo(first.count),
      );

    return result.take(5).toList();
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
              CircleAvatar(
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
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
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
    required this.daysInMonth,
  });

  final String emoji;
  final String name;
  final int total;
  final int daysInMonth;

  @override
  Widget build(BuildContext context) {
    final progress =
        daysInMonth == 0 ? 0.0 : total / daysInMonth;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius:
                  BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              '$total / $daysInMonth',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringEntry {
  const _RecurringEntry({
    required this.text,
    required this.count,
  });

  final String text;
  final int count;
}
