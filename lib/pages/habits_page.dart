import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/habit.dart';
import '../state/lighthouse_controller.dart';
import '../util/resume_policy.dart';
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

  final ResumePolicy _resumePolicy = ResumePolicy();

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

    // Turning a phone sideways switches to the month grid. When the
    // orientation flips (and the grid may now be on screen) re-centre on
    // today.
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
    // Back from the background after a while (or on a new day): land on
    // today again. A quick glance at a notification keeps the view as is.
    if (_resumePolicy.onStateChanged(state)) {
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

  /// Archive a habit and offer a one-tap undo — archiving is reversible, so it
  /// should never feel like a dead end.
  void _archiveHabit(Habit habit) {
    widget.controller.archiveHabit(habit.id);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_strings.habitArchived(habit.name)),
        // Action snackbars persist by default in Flutter; auto-hide after 5s.
        persist: false,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: _strings.undo,
          onPressed: () => widget.controller.restoreHabit(habit.id),
        ),
      ),
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
                      // The name says it all; the symbol is decoration.
                      leading: ExcludeSemantics(
                        child: Text(
                          habit.emoji,
                          style: const TextStyle(fontSize: 23),
                        ),
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

        // A phone held sideways always gets the month grid. Everywhere else
        // — including a phone in portrait, which may be rotation-locked —
        // the Kompakt / Monat toggle decides.
        final forceGrid = isPhone && isLandscape;
        final compact = !forceGrid && widget.controller.habitCompactView;

        return Column(
          children: [
            MonthHeader(
              title: strings.habits,
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
                  // Hidden only where orientation already chose the grid.
                  if (!forceGrid)
                    _HabitViewToggle(
                      strings: strings,
                      compact: compact,
                      iconsOnly: isPhone,
                      onChanged: (value) {
                        widget.controller.setHabitCompactView(value);
                        if (!value) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollGridToToday(),
                          );
                        }
                      },
                    ),
                  // Icon-only on a phone so the header stays one row high.
                  if (isPhone)
                    IconButton.outlined(
                      tooltip: strings.archiveButton,
                      onPressed: _showArchivedHabits,
                      icon: const Icon(Icons.archive_outlined),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _showArchivedHabits,
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(strings.archiveButton),
                    ),
                  // Sideways on a phone the header is a single row — keep
                  // it there with an icon-only button.
                  if (forceGrid)
                    IconButton.filled(
                      tooltip: strings.addHabit,
                      onPressed: _showHabitDialog,
                      icon: const Icon(Icons.add),
                    )
                  else
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
                      onArchive: _archiveHabit,
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

        // Phone portrait: the pinned Gestern / Heute columns would leave room
        // for about one day, and they repeat the last two columns anyway —
        // drop them and slim everything so ~5 days are visible.
        final portraitPhone = constraints.maxWidth < 440;

        final sidePadding = portraitPhone ? 12.0 : 24.0;
        final nameWidth = portraitPhone ? 104.0 : (narrow ? 150.0 : 200.0);
        final pinnedWidth = narrow ? 44.0 : 54.0;
        final cellWidth = narrow ? 40.0 : 44.0;
        final totalWidth = portraitPhone ? 48.0 : (narrow ? 56.0 : 86.0);

        _gridCellWidth = cellWidth;

        final bodyHeight = _kHeaderHeight + habits.length * _kRowHeight;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 40),
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
                      showPinnedDays: !portraitPhone,
                      compactNames: portraitPhone,
                      bodyHeight: bodyHeight,
                      today: today,
                      yesterday: yesterday,
                      onEdit: (habit) => _showHabitDialog(habit: habit),
                      onArchive: _archiveHabit,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _gridScrollController,
                        scrollDirection: Axis.horizontal,
                        // Its own Material so the day cells' Ink is painted
                        // (and clipped) inside the scroll view, instead of
                        // showing through behind the habit names when the
                        // month is scrolled.
                        child: Material(
                          type: MaterialType.transparency,
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
    this.iconsOnly = false,
  });

  final AppStrings strings;
  final bool compact;
  final ValueChanged<bool> onChanged;

  /// On a phone the labels would push Archiv / + Habit onto another row.
  final bool iconsOnly;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      // Standard density: each segment needs a full 48 dp tap target.
      segments: [
        ButtonSegment(
          value: true,
          label: iconsOnly ? null : Text(strings.compact),
          tooltip: iconsOnly ? strings.compact : null,
          icon: const Icon(Icons.view_agenda_outlined),
        ),
        ButtonSegment(
          value: false,
          label: iconsOnly ? null : Text(strings.month),
          tooltip: iconsOnly ? strings.month : null,
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
    required this.onArchive,
  });

  final List<Habit> habits;
  final LighthouseController controller;
  final DateTime today;
  final DateTime yesterday;
  final void Function(Habit habit) onEdit;
  final void Function(Habit habit) onArchive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // The smallest phones (320 px): every pixel goes to the habit names.
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final side = narrow ? 12.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(side, 0, side, 40),
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
                    narrow: narrow,
                    today: today,
                    yesterday: yesterday,
                    onEdit: () => onEdit(habits[i]),
                    onArchive: () => onArchive(habits[i]),
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
    this.narrow = false,
    required this.today,
    required this.yesterday,
    required this.onEdit,
    required this.onArchive,
  });

  final Habit habit;
  final LighthouseController controller;

  /// No separate ⋮ button: the name opens the habit menu, so the name keeps
  /// enough room on a 320 px phone.
  final bool narrow;
  final DateTime today;
  final DateTime yesterday;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = controller.strings;

    void onSelected(String value) {
      if (value == 'edit') onEdit();
      if (value == 'archive') onArchive();
    }

    List<PopupMenuEntry<String>> menuItems(BuildContext context) => [
      PopupMenuItem(value: 'edit', child: Text(strings.edit)),
      PopupMenuItem(value: 'archive', child: Text(strings.archive)),
    ];

    final monthTotal = controller.habitTotalForMonth(
      habitId: habit.id,
      selectedMonth: DateTime(today.year, today.month),
    );

    final nameBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          habit.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          strings.nThisMonth(monthTotal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Decoration next to the name: screen readers would read it as
          // "briefcase, Work".
          ExcludeSemantics(
            child: Text(habit.emoji, style: const TextStyle(fontSize: 22)),
          ),
          SizedBox(width: narrow ? 10 : 14),
          Expanded(
            child: narrow
                ? PopupMenuButton<String>(
                    tooltip: strings.manageHabit,
                    onSelected: onSelected,
                    itemBuilder: menuItems,
                    child: nameBlock,
                  )
                : nameBlock,
          ),
          const SizedBox(width: 8),
          _CompactToggle(
            label: '${strings.weekdaysShort[yesterday.weekday - 1]}.',
            caption: strings.yesterday,
            date: yesterday,
            habitId: habit.id,
            habitName: habit.name,
            controller: controller,
          ),
          const SizedBox(width: 6),
          _CompactToggle(
            label: '${strings.weekdaysShort[today.weekday - 1]}.',
            caption: strings.today,
            date: today,
            habitId: habit.id,
            habitName: habit.name,
            controller: controller,
            isToday: true,
          ),
          if (!narrow)
            PopupMenuButton<String>(
              tooltip: strings.manageHabit,
              iconSize: 20,
              onSelected: onSelected,
              itemBuilder: menuItems,
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
    required this.habitName,
    required this.controller,
    this.isToday = false,
  });

  final String label;
  final String caption;
  final DateTime date;
  final String habitId;

  /// For screen readers: "Water, heute" instead of "Heute, Mi.".
  final String habitName;
  final LighthouseController controller;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = controller.isHabitCompleted(habitId: habitId, date: date);

    void toggle() {
      HapticFeedback.selectionClick();
      controller.toggleHabit(habitId: habitId, date: date);
    }

    // The whole column is the tap target (>= 48dp), not just the 26dp circle,
    // so tapping the "Heute" label toggles the day too.
    return _HabitDaySemantics(
      habitName: habitName,
      date: date,
      controller: controller,
      completed: completed,
      onToggle: toggle,
      child: SizedBox(
        width: 54,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? colorScheme.primary
                          : Colors.transparent,
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
                ],
              ),
            ),
          ),
        ),
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
    required this.onArchive,
    this.showPinnedDays = true,
    this.compactNames = false,
  });

  final List<Habit> habits;
  final LighthouseController controller;
  final double nameWidth;
  final double cellWidth;

  /// Whether the Gestern / Heute columns are pinned next to the names.
  final bool showPinnedDays;

  /// Narrow name cells: the whole cell opens the habit menu.
  final bool compactNames;
  final double bodyHeight;
  final DateTime today;
  final DateTime yesterday;
  final void Function(Habit habit) onEdit;
  final void Function(Habit habit) onArchive;

  Widget _dayHeader(
    BuildContext context, {
    required String label,
    required DateTime date,
    required bool isToday,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // The pinned columns are only ~44 px wide: shrink rather than wrap onto
    // a second line (which overflows the header, e.g. at large text sizes).
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isToday
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${controller.strings.weekdaysShort[date.weekday - 1]}. ${date.day}.',
            maxLines: 1,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
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
        width: nameWidth + (showPinnedDays ? cellWidth * 2 : 0),
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
                  if (showPinnedDays) ...[
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
                        compact: compactNames,
                        onEdit: () => onEdit(habit),
                        onArchive: () => onArchive(habit),
                      ),
                    ),
                    if (showPinnedDays) ...[
                      _PinnedCell(
                        width: cellWidth,
                        child: _HabitDayCell(
                          habitId: habit.id,
                          habitName: habit.name,
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
                          habitName: habit.name,
                          date: today,
                          controller: controller,
                          width: cellWidth,
                          isToday: true,
                          pinned: true,
                        ),
                      ),
                    ],
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
    required this.onArchive,
    this.compact = false,
  });

  final Habit habit;
  final LighthouseController controller;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  /// No separate ⋮ button: the whole (narrow) cell opens the menu, and the
  /// name may wrap onto a second line instead of being cut to a few letters.
  final bool compact;

  void _onSelected(String value) {
    if (value == 'edit') {
      onEdit();
    }

    if (value == 'archive') {
      onArchive();
    }
  }

  List<PopupMenuEntry<String>> _items(BuildContext context) {
    return [
      PopupMenuItem(value: 'edit', child: Text(controller.strings.edit)),
      PopupMenuItem(value: 'archive', child: Text(controller.strings.archive)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return PopupMenuButton<String>(
        tooltip: controller.strings.manageHabit,
        onSelected: _onSelected,
        itemBuilder: _items,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Text(habit.emoji, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 2,
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
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text(habit.emoji, style: const TextStyle(fontSize: 19)),
          ),
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
            onSelected: _onSelected,
            itemBuilder: _items,
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
                    habitName: habit.name,
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
              // Shrinks rather than wrapping in the slim phone-portrait column.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  controller.strings.totalColumn,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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
    required this.habitName,
    required this.date,
    required this.controller,
    this.width = 44,
    this.isToday = false,
    this.pinned = false,
  });

  final String habitId;
  final String habitName;
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

    void toggle() {
      HapticFeedback.selectionClick();
      controller.toggleHabit(habitId: habitId, date: date);
    }

    final strings = controller.strings;
    final label = strings.habitDayLabel(habitName, date, controller.today);

    return _HabitDaySemantics(
      habitName: habitName,
      date: date,
      controller: controller,
      completed: completed,
      onToggle: disabled ? null : toggle,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Tooltip(
          // Which habit and day, for mouse users scanning a long grid.
          message: disabled ? '$label · ${strings.futureDaysLocked}' : label,
          child: Ink(
            color: cellColor,
            child: InkWell(
              // The whole cell is the tap target, not just the 22px circle.
              onTap: disabled ? null : toggle,
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
        ),
      ),
    );
  }
}

/// One habit on one day, as screen readers hear it: a checkbox called
/// "Water, heute" that is ticked or not, and disabled for days to come.
class _HabitDaySemantics extends StatelessWidget {
  const _HabitDaySemantics({
    required this.habitName,
    required this.date,
    required this.controller,
    required this.completed,
    required this.onToggle,
    required this.child,
  });

  final String habitName;
  final DateTime date;
  final LighthouseController controller;
  final bool completed;

  /// Null for days that can't be marked yet.
  final VoidCallback? onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = controller.strings;

    return Semantics(
      container: true,
      button: true,
      checked: completed,
      enabled: onToggle != null,
      label: strings.habitDayLabel(habitName, date, controller.today),
      hint: onToggle == null ? strings.futureDaysLocked : null,
      onTap: onToggle,
      // One complete label instead of "Gestern", "Di." and the tooltip.
      excludeSemantics: true,
      child: child,
    );
  }
}
