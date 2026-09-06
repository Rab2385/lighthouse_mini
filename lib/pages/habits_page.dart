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

const double _kHeaderHeight = 58;
const double _kRowHeight = 62;

const List<String> _weekdayAbbr = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> with WidgetsBindingObserver {
  late DateTime _selectedMonth;

  final ScrollController _gridScrollController = ScrollController();

  double _gridCellWidth = 44;

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

    // The grid scroll view starts at day 1, so today's centre is simply
    // its column offset within that view.
    final columnCentre = (todayDay - 1) * _gridCellWidth + _gridCellWidth / 2;

    final target = (columnCentre - position.viewportDimension / 2).clamp(
      0.0,
      position.maxScrollExtent,
    );

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
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.16,
                                      )
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

    final today = widget.controller.today;
    final yesterday = DateTime(today.year, today.month, today.day - 1);

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
              subtitle: 'Gestern und heute sind immer sichtbar.',
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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final colorScheme = Theme.of(context).colorScheme;
                        final narrow = constraints.maxWidth < 560;

                        final nameWidth = narrow ? 150.0 : 200.0;
                        final pinnedWidth = narrow ? 44.0 : 54.0;
                        final cellWidth = narrow ? 36.0 : 44.0;
                        final totalWidth = narrow ? 56.0 : 86.0;

                        _gridCellWidth = cellWidth;

                        final bodyHeight =
                            _kHeaderHeight + habits.length * _kRowHeight;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SizedBox(
                              height: bodyHeight,
                              child: Material(
                                type: MaterialType.transparency,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FrozenHabitColumn(
                                      habits: habits,
                                      controller: widget.controller,
                                      nameWidth: nameWidth,
                                      cellWidth: pinnedWidth,
                                      bodyHeight: bodyHeight,
                                      today: today,
                                      yesterday: yesterday,
                                      onEdit: (habit) =>
                                          _showHabitDialog(habit: habit),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: _gridScrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: daysInMonth * cellWidth,
                                          height: bodyHeight,
                                          child: _MonthGridColumn(
                                            habits: habits,
                                            controller: widget.controller,
                                            selectedMonth: _selectedMonth,
                                            daysInMonth: daysInMonth,
                                            todayDay: todayDay,
                                            cellWidth: cellWidth,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _TotalColumn(
                                      habits: habits,
                                      controller: widget.controller,
                                      selectedMonth: _selectedMonth,
                                      daysInMonth: daysInMonth,
                                      width: totalWidth,
                                      bodyHeight: bodyHeight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// The always-visible left block: habit name + the pinned "Gestern" and
/// "Heute" columns. Never scrolls horizontally.
class _FrozenHabitColumn extends StatelessWidget {
  const _FrozenHabitColumn({
    required this.habits,
    required this.controller,
    required this.nameWidth,
    required this.cellWidth,
    required this.bodyHeight,
    required this.today,
    required this.yesterday,
    required this.onEdit,
  });

  final List<Habit> habits;
  final LighthouseController controller;
  final double nameWidth;
  final double cellWidth;
  final double bodyHeight;
  final DateTime today;
  final DateTime yesterday;
  final void Function(Habit habit) onEdit;

  Widget _dayHeader(
    BuildContext context, {
    required String label,
    required DateTime date,
    required bool isToday,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_weekdayAbbr[date.weekday - 1]}. ${date.day}.',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SizedBox(
        width: nameWidth + cellWidth * 2,
        height: bodyHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: _kHeaderHeight,
              color: colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  SizedBox(
                    width: nameWidth,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Habit',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  _PinnedCell(
                    width: cellWidth,
                    child: _dayHeader(
                      context,
                      label: 'Gestern',
                      date: yesterday,
                      isToday: false,
                    ),
                  ),
                  _PinnedCell(
                    width: cellWidth,
                    isToday: true,
                    child: _dayHeader(
                      context,
                      label: 'Heute',
                      date: today,
                      isToday: true,
                    ),
                  ),
                ],
              ),
            ),
            for (final habit in habits)
              Container(
                height: _kRowHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: nameWidth,
                      child: _HabitNameCell(
                        habit: habit,
                        controller: controller,
                        onEdit: () => onEdit(habit),
                      ),
                    ),
                    _PinnedCell(
                      width: cellWidth,
                      child: _HabitDayCell(
                        habitId: habit.id,
                        date: yesterday,
                        controller: controller,
                        width: cellWidth,
                        pinned: true,
                      ),
                    ),
                    _PinnedCell(
                      width: cellWidth,
                      isToday: true,
                      child: _HabitDayCell(
                        habitId: habit.id,
                        date: today,
                        controller: controller,
                        width: cellWidth,
                        isToday: true,
                        pinned: true,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A faint petrol wash behind the pinned Gestern / Heute columns.
class _PinnedCell extends StatelessWidget {
  const _PinnedCell({
    required this.width,
    required this.child,
    this.isToday = false,
  });

  final double width;
  final Widget child;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.center,
      color: colorScheme.primary.withValues(alpha: isToday ? 0.10 : 0.045),
      child: child,
    );
  }
}

class _HabitNameCell extends StatelessWidget {
  const _HabitNameCell({
    required this.habit,
    required this.controller,
    required this.onEdit,
  });

  final Habit habit;
  final LighthouseController controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 9),
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
            padding: EdgeInsets.zero,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
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
                PopupMenuItem(value: 'archive', child: Text('Archivieren')),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// The scrolling middle: the full month, one column per day.
class _MonthGridColumn extends StatelessWidget {
  const _MonthGridColumn({
    required this.habits,
    required this.controller,
    required this.selectedMonth,
    required this.daysInMonth,
    required this.cellWidth,
    this.todayDay,
  });

  final List<Habit> habits;
  final LighthouseController controller;
  final DateTime selectedMonth;
  final int daysInMonth;
  final double cellWidth;
  final int? todayDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: _kHeaderHeight,
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              for (var day = 1; day <= daysInMonth; day++)
                SizedBox(
                  width: cellWidth,
                  child: Center(
                    child: Text(
                      day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: day == todayDay ? colorScheme.primary : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final habit in habits)
          Container(
            height: _kRowHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                for (var day = 1; day <= daysInMonth; day++)
                  _HabitDayCell(
                    habitId: habit.id,
                    date: DateTime(
                      selectedMonth.year,
                      selectedMonth.month,
                      day,
                    ),
                    controller: controller,
                    width: cellWidth,
                    isToday: day == todayDay,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The always-visible right block: the monthly total per habit.
class _TotalColumn extends StatelessWidget {
  const _TotalColumn({
    required this.habits,
    required this.controller,
    required this.selectedMonth,
    required this.daysInMonth,
    required this.width,
    required this.bodyHeight,
  });

  final List<Habit> habits;
  final LighthouseController controller;
  final DateTime selectedMonth;
  final int daysInMonth;
  final double width;
  final double bodyHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SizedBox(
        width: width,
        height: bodyHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: _kHeaderHeight,
              color: colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Text(
                'Gesamt',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final habit in habits)
              Container(
                height: _kRowHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${controller.habitTotalForMonth(habitId: habit.id, selectedMonth: selectedMonth)}'
                    '/$daysInMonth',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HabitDayCell extends StatelessWidget {
  const _HabitDayCell({
    required this.habitId,
    required this.date,
    required this.controller,
    this.width = 44,
    this.isToday = false,
    this.pinned = false,
  });

  final String habitId;
  final DateTime date;
  final LighthouseController controller;
  final double width;
  final bool isToday;

  /// Rendered inside the pinned Gestern / Heute columns, which already carry
  /// their own background tint.
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final disabled = date.isAfter(controller.today);

    final completed = controller.isHabitCompleted(habitId: habitId, date: date);

    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    final Color? cellColor = pinned
        ? null
        : isToday
        ? colorScheme.primary.withValues(alpha: 0.08)
        : isWeekend
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
        : null;

    return SizedBox(
      width: width,
      height: double.infinity,
      child: Tooltip(
        message: disabled
            ? 'Zukünftige Tage sind gesperrt.'
            : completed
            ? 'Markierung entfernen'
            : 'Tag markieren',
        child: Ink(
          color: cellColor,
          child: InkWell(
            // The whole cell is the tap target, not just the 22px circle.
            onTap: disabled
                ? null
                : () {
                    controller.toggleHabit(habitId: habitId, date: date);
                  },
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? colorScheme.primary : Colors.transparent,
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
                    ? Icon(Icons.check, size: 14, color: colorScheme.onPrimary)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
