import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/lighthouse_controller.dart';
import '../widgets/month_header.dart';

const List<String> _defaultHabitEmojis = [
  '💼',
  '☕',
  '💧',
  '💻',
  '🏃',
  '🍷',
  '📖',
  '🧘',
  '🍎',
  '😴',
  '📝',
  '🎧',
];

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage>
    with WidgetsBindingObserver {
  late DateTime _selectedMonth;

  final ScrollController _gridScrollController = ScrollController();

  static const double _nameColumnWidth = 220;
  static const double _dayCellWidth = 44;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final today = widget.controller.today;
    _selectedMonth = DateTime(today.year, today.month);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGridToToday());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app comes back to the foreground, land on today again.
    if (state == AppLifecycleState.resumed) {
      _goToToday();
    }
  }

  bool get _isViewingCurrentMonth {
    final today = widget.controller.today;
    return _selectedMonth.year == today.year &&
        _selectedMonth.month == today.month;
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _showNextMonth() {
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

    if (nextMonth.isAfter(widget.controller.maximumFutureMonth)) {
      return;
    }

    setState(() {
      _selectedMonth = nextMonth;
    });
  }

  /// Jump back to the current month and scroll today's column into view.
  void _goToToday() {
    if (!mounted) {
      return;
    }

    final today = widget.controller.today;

    setState(() {
      _selectedMonth = DateTime(today.year, today.month);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGridToToday());
  }

  void _scrollGridToToday() {
    if (!mounted ||
        !_isViewingCurrentMonth ||
        !_gridScrollController.hasClients) {
      return;
    }

    final position = _gridScrollController.position;
    final todayDay = widget.controller.today.day;

    final columnCentre =
        _nameColumnWidth + (todayDay - 1) * _dayCellWidth + _dayCellWidth / 2;

    final target = (columnCentre - position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent);

    _gridScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  bool get _canShowNextMonth {
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

    return !nextMonth.isAfter(widget.controller.maximumFutureMonth);
  }

  Future<void> _showHabitDialog({Habit? habit}) async {
    final nameController = TextEditingController(text: habit?.name ?? '');

    final emojiController = TextEditingController(text: habit?.emoji ?? '');

    final descriptionController = TextEditingController(
      text: habit?.description ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(habit == null ? 'Habit hinzufügen' : 'Habit bearbeiten'),
          content: SizedBox(
            width: 430,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final colorScheme = Theme.of(context).colorScheme;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Zum Beispiel Reading',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emojiController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Emoji',
                        hintText: '📖',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _defaultHabitEmojis.map((emoji) {
                          final isSelected = emojiController.text == emoji;

                          return GestureDetector(
                            onTap: () {
                              emojiController.text = emoji;
                              setDialogState(() {});
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                          .withValues(alpha: 0.16)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung',
                        hintText: 'Was bedeutet die Markierung?',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      if (habit == null) {
        await widget.controller.addHabit(
          name: nameController.text,
          emoji: emojiController.text,
          description: descriptionController.text,
        );
      } else {
        await widget.controller.updateHabit(
          id: habit.id,
          name: nameController.text,
          emoji: emojiController.text,
          description: descriptionController.text,
        );
      }
    }

    nameController.dispose();
    emojiController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showArchivedHabits() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archivierte Habits'),
          content: SizedBox(
            width: 520,
            height: 350,
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                final archived = widget.controller.archivedHabits;

                if (archived.isEmpty) {
                  return const Center(
                    child: Text('Keine archivierten Habits.'),
                  );
                }

                return ListView.separated(
                  itemCount: archived.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final habit = archived[index];

                    return ListTile(
                      leading: Text(
                        habit.emoji,
                        style: const TextStyle(fontSize: 23),
                      ),
                      title: Text(habit.name),
                      subtitle: habit.description.isEmpty
                          ? null
                          : Text(habit.description),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Wiederherstellen',
                            onPressed: () {
                              widget.controller.restoreHabit(habit.id);
                            },
                            icon: const Icon(Icons.restore),
                          ),
                          IconButton(
                            tooltip: 'Endgültig löschen',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (confirmContext) {
                                  return AlertDialog(
                                    title: const Text('Endgültig löschen?'),
                                    content: Text(
                                      'Alle Markierungen '
                                      'von "${habit.name}" '
                                      'werden gelöscht.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(confirmContext, false);
                                        },
                                        child: const Text('Abbrechen'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(confirmContext, true);
                                        },
                                        child: const Text('Löschen'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed == true) {
                                await widget.controller.permanentlyDeleteHabit(
                                  habit.id,
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final tableWidth = 220 + (daysInMonth * 44) + 90;

    final today = widget.controller.today;
    final todayDay =
        (today.year == _selectedMonth.year &&
            today.month == _selectedMonth.month)
        ? today.day
        : null;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final habits = widget.controller.activeHabits;

        return Column(
          children: [
            MonthHeader(
              title: 'Habit Tracker',
              subtitle: 'Ein Klick markiert den Tag.',
              selectedMonth: _selectedMonth,
              onPreviousMonth: _showPreviousMonth,
              onNextMonth: _canShowNextMonth ? _showNextMonth : null,
              onToday: _goToToday,
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showArchivedHabits,
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Archiv'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      _showHabitDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Habit'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habits.isEmpty
                  ? const Center(child: Text('Noch keine aktiven Habits.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          controller: _gridScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth.toDouble(),
                            child: Column(
                              children: [
                                _HabitHeaderRow(
                                  daysInMonth: daysInMonth,
                                  todayDay: todayDay,
                                ),
                                for (final habit in habits)
                                  _HabitRow(
                                    habit: habit,
                                    selectedMonth: _selectedMonth,
                                    daysInMonth: daysInMonth,
                                    todayDay: todayDay,
                                    controller: widget.controller,
                                    onEdit: () {
                                      _showHabitDialog(habit: habit);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HabitHeaderRow extends StatelessWidget {
  const _HabitHeaderRow({required this.daysInMonth, this.todayDay});

  final int daysInMonth;
  final int? todayDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 58,
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(
            width: 220,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Habit',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          for (var day = 1; day <= daysInMonth; day++)
            SizedBox(
              width: 44,
              child: Center(
                child: Text(
                  day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: day == todayDay ? colorScheme.primary : null,
                  ),
                ),
              ),
            ),
          const SizedBox(
            width: 90,
            child: Center(
              child: Text(
                'Gesamt',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.selectedMonth,
    required this.daysInMonth,
    required this.controller,
    required this.onEdit,
    this.todayDay,
  });

  final Habit habit;
  final DateTime selectedMonth;
  final int daysInMonth;
  final int? todayDay;
  final LighthouseController controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final total = controller.habitTotalForMonth(
      habitId: habit.id,
      selectedMonth: selectedMonth,
    );

    return Container(
      height: 66,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Row(
                children: [
                  Text(habit.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message: habit.description.isEmpty
                          ? habit.name
                          : habit.description,
                      child: Text(
                        habit.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Habit verwalten',
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      }

                      if (value == 'archive') {
                        controller.archiveHabit(habit.id);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text('Archivieren'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
          for (var day = 1; day <= daysInMonth; day++)
            _HabitDayCell(
              habitId: habit.id,
              date: DateTime(selectedMonth.year, selectedMonth.month, day),
              controller: controller,
              isToday: day == todayDay,
            ),
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$total / $daysInMonth',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitDayCell extends StatelessWidget {
  const _HabitDayCell({
    required this.habitId,
    required this.date,
    required this.controller,
    this.isToday = false,
  });

  final String habitId;
  final DateTime date;
  final LighthouseController controller;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final disabled = date.isAfter(controller.today);

    final completed = controller.isHabitCompleted(habitId: habitId, date: date);

    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    final Color? cellColor = isToday
        ? colorScheme.primary.withValues(alpha: 0.08)
        : isWeekend
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
        : null;

    return Container(
      width: 44,
      height: double.infinity,
      color: cellColor,
      child: Center(
        child: Tooltip(
          message: disabled
              ? 'Zukünftige Tage sind gesperrt.'
              : completed
              ? 'Markierung entfernen'
              : 'Tag markieren',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: disabled
                ? null
                : () {
                    controller.toggleHabit(habitId: habitId, date: date);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  width: 1.5,
                  color: disabled
                      ? colorScheme.outlineVariant
                      : completed
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.55),
                ),
              ),
              child: completed
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
