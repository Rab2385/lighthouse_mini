import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/habit.dart';
import '../state/lighthouse_controller.dart';
import '../widgets/habit_editor_sheet.dart';
import '../widgets/month_header.dart';

const double _kHeaderHeight = 58;
const double _kRowHeight = 62;

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
  Orientation? _lastOrientation;

  AppStrings get _strings => widget.controller.strings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final today = widget.controller.today;
    _selectedMonth = DateTime(today.year, today.month);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGridToToday());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // On a phone the orientation, not the saved preference, chooses the view.
    // When it flips (and the month grid is now on screen) re-centre on today.
    final orientation = MediaQuery.orientationOf(context);
    if (_lastOrientation != null && orientation != _lastOrientation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollGridToToday();
      });
    }
    _lastOrientation = orientation;
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
    await HabitEditorSheet.show(
      context,
      controller: widget.controller,
      habit: habit,
    );
  }

  Future<void> _showArchivedHabits() async {
    final strings = _strings;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.archivedHabits),
          content: SizedBox(
            width: 520,
            // Shrink on short screens (e.g. a phone held in landscape).
            height: (MediaQuery.sizeOf(dialogContext).height * 0.55).clamp(
              180.0,
              350.0,
            ),
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                final archived = widget.controller.archivedHabits;

                if (archived.isEmpty) {
                  return Center(child: Text(strings.noArchivedHabits));
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
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: strings.restore,
                            onPressed: () {
                              widget.controller.restoreHabit(habit.id);
                            },
                            icon: const Icon(Icons.restore),
                          ),
                          IconButton(
                            tooltip: strings.deleteForever,
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (confirmContext) {
                                  return AlertDialog(
                                    title: Text(strings.deleteForeverQ),
                                    content: Text(
                                      strings.deleteHabitMarkings(habit.name),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(confirmContext, false);
                                        },
                                        child: Text(strings.cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(confirmContext, true);
                                        },
                                        child: Text(strings.delete),
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
              child: Text(strings.close),
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

    final isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final habits = widget.controller.activeHabits;
        final strings = _strings;

        // On a phone: portrait shows the compact list, landscape shows the
        // month grid — it follows how the phone is held. Elsewhere the
        // Kompakt / Monat toggle in Settings-style header decides.
        final compact = isPhone
            ? !isLandscape
            : widget.controller.habitCompactView;

        return Column(
          children: [
            MonthHeader(
              title: strings.habitTracker,
              strings: strings,
              selectedMonth: _selectedMonth,
              showMonthControls: !compact,
              onPreviousMonth: _showPreviousMonth,
              onNextMonth: _canShowNextMonth ? _showNextMonth : null,
              onToday: _goToToday,
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // The manual toggle only makes sense where orientation
                  // isn't already choosing the view.
                  if (!isPhone)
                    _HabitViewToggle(
                      strings: strings,
                      compact: compact,
                      onChanged: (value) {
                        widget.controller.setHabitCompactView(value);
                        if (!value) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollGridToToday(),
                          );
                        }
                      },
                    ),
                  OutlinedButton.icon(
                    onPressed: _showArchivedHabits,
                    icon: const Icon(Icons.archive_outlined),
                    label: Text(strings.archiveButton),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      _showHabitDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(strings.habitButton),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habits.isEmpty
                  ? Center(child: Text(strings.noActiveHabits))
                  : compact
                  ? _HabitCompactList(
                      habits: habits,
                      controller: widget.controller,
                      today: today,
                      yesterday: yesterday,
                      onEdit: (habit) => _showHabitDialog(habit: habit),
                    )
                  : _buildMonthTable(
                      habits: habits,
                      daysInMonth: daysInMonth,
                      today: today,
                      yesterday: yesterday,
                      todayDay: todayDay,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthTable({
    required List<Habit> habits,
    required int daysInMonth,
    required DateTime today,
    required DateTime yesterday,
    required int? todayDay,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final narrow = constraints.maxWidth < 560;

        final nameWidth = narrow ? 150.0 : 200.0;
        final pinnedWidth = narrow ? 44.0 : 54.0;
        final cellWidth = narrow ? 36.0 : 44.0;
        final totalWidth = narrow ? 56.0 : 86.0;

        _gridCellWidth = cellWidth;

        final bodyHeight = _kHeaderHeight + habits.length * _kRowHeight;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
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
                      onEdit: (habit) => _showHabitDialog(habit: habit),
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
    );
  }
}

/// The compact "Kompakt" / full "Monat" switch shown in the header.
class _HabitViewToggle extends StatelessWidget {
  const _HabitViewToggle({
    required this.strings,
    required this.compact,
    required this.onChanged,
  });

  final AppStrings strings;
  final bool compact;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        ButtonSegment(
          value: true,
          label: Text(strings.compact),
          icon: const Icon(Icons.view_agenda_outlined),
        ),
        ButtonSegment(
          value: false,
          label: Text(strings.month),
          icon: const Icon(Icons.calendar_view_month_outlined),
        ),
      ],
      selected: {compact},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

/// The default view: one calm row per habit with big Gestern / Heute toggles.
class _HabitCompactList extends StatelessWidget {
  const _HabitCompactList({
    required this.habits,
    required this.controller,
    required this.today,
    required this.yesterday,
    required this.onEdit,
  });

  final List<Habit> habits;
  final LighthouseController controller;
  final DateTime today;
  final DateTime yesterday;
  final void Function(Habit habit) onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < habits.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: colorScheme.outlineVariant),
                  _HabitCompactRow(
                    habit: habits[i],
                    controller: controller,
                    today: today,
                    yesterday: yesterday,
                    onEdit: () => onEdit(habits[i]),
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

class _HabitCompactRow extends StatelessWidget {
  const _HabitCompactRow({
    required this.habit,
    required this.controller,
    required this.today,
    required this.yesterday,
    required this.onEdit,
  });

  final Habit habit;
  final LighthouseController controller;
  final DateTime today;
  final DateTime yesterday;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = controller.strings;

    final monthTotal = controller.habitTotalForMonth(
      habitId: habit.id,
      selectedMonth: DateTime(today.year, today.month),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.nThisMonth(monthTotal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CompactToggle(
            label: '${strings.weekdaysShort[yesterday.weekday - 1]}.',
            caption: strings.yesterday,
            date: yesterday,
            habitId: habit.id,
            controller: controller,
          ),
          const SizedBox(width: 6),
          _CompactToggle(
            label: '${strings.weekdaysShort[today.weekday - 1]}.',
            caption: strings.today,
            date: today,
            habitId: habit.id,
            controller: controller,
            isToday: true,
          ),
          PopupMenuButton<String>(
            tooltip: strings.manageHabit,
            iconSize: 20,
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'archive') controller.archiveHabit(habit.id);
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(value: 'edit', child: Text(strings.edit)),
                PopupMenuItem(value: 'archive', child: Text(strings.archive)),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    required this.label,
    required this.caption,
    required this.date,
    required this.habitId,
    required this.controller,
    this.isToday = false,
  });

  final String label;
  final String caption;
  final DateTime date;
  final String habitId;
  final LighthouseController controller;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = controller.isHabitCompleted(habitId: habitId, date: date);

    return SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isToday
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => controller.toggleHabit(habitId: habitId, date: date),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      width: 1.5,
                      color: completed
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.55),
                    ),
                  ),
                  child: completed
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
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
          '${controller.strings.weekdaysShort[date.weekday - 1]}. ${date.day}.',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = controller.strings;

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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          strings.habitColumn,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  _PinnedCell(
                    width: cellWidth,
                    child: _dayHeader(
                      context,
                      label: strings.yesterday,
                      date: yesterday,
                      isToday: false,
                    ),
                  ),
                  _PinnedCell(
                    width: cellWidth,
                    isToday: true,
                    child: _dayHeader(
                      context,
                      label: strings.today,
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
              message: habit.name,
              child: Text(
                habit.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: controller.strings.manageHabit,
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
              return [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(controller.strings.edit),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(controller.strings.archive),
                ),
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
              child: Text(
                controller.strings.totalColumn,
                style: const TextStyle(fontWeight: FontWeight.w700),
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
            ? controller.strings.futureDaysLocked
            : completed
            ? controller.strings.removeMark
            : controller.strings.markDay,
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
