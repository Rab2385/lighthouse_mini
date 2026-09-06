import 'package:flutter/material.dart';

import '../models/good_thing.dart';
import '../state/lighthouse_controller.dart';
import '../widgets/month_header.dart';

class GoodThingsPage extends StatefulWidget {
  const GoodThingsPage({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<GoodThingsPage> createState() => _GoodThingsPageState();
}

class _GoodThingsPageState extends State<GoodThingsPage>
    with WidgetsBindingObserver {
  late DateTime _selectedMonth;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _monthScrollController = ScrollController();
  final GlobalKey _todayCardKey = GlobalKey();

  String _searchQuery = '';

  static const List<String> _weekdayNames = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final today = widget.controller.today;
    _selectedMonth = DateTime(today.year, today.month);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _monthScrollController.dispose();
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

  /// Jump back to the current month and scroll today's card into view.
  void _goToToday() {
    if (!mounted) {
      return;
    }

    final today = widget.controller.today;

    setState(() {
      _selectedMonth = DateTime(today.year, today.month);
      if (_searchQuery.trim().isNotEmpty) {
        _searchQuery = '';
        _searchController.clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!mounted || !_isViewingCurrentMonth || _searchQuery.trim().isNotEmpty) {
      return;
    }

    final cardContext = _todayCardKey.currentContext;
    if (cardContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      cardContext,
      alignment: 0.06,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  bool get _canShowNextMonth {
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

    return !nextMonth.isAfter(widget.controller.maximumFutureMonth);
  }

  Future<void> _editEntry(GoodThing entry) async {
    final textController = TextEditingController(text: entry.text);

    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eintrag bearbeiten'),
          content: SizedBox(
            width: 460,
            child: TextField(
              controller: textController,
              autofocus: true,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Good Thing'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final text = textController.text.trim();

                if (text.isNotEmpty) {
                  Navigator.pop(dialogContext, text);
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (newText == null) {
      return;
    }

    await widget.controller.updateGoodThing(id: entry.id, text: newText);
  }

  Future<void> _deleteEntry(GoodThing entry) async {
    await widget.controller.deleteGoodThing(entry.id);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Eintrag gelöscht.'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            widget.controller.addGoodThing(date: entry.date, text: entry.text);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final searchResults = widget.controller.searchGoodThings(_searchQuery);

        return Column(
          children: [
            MonthHeader(
              title: 'Good Things',
              subtitle: widget.controller.greeting,
              selectedMonth: _selectedMonth,
              onPreviousMonth: _showPreviousMonth,
              onNextMonth: _canShowNextMonth ? _showNextMonth : null,
              onToday: _goToToday,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Good Things durchsuchen …',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Suche löschen',
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Expanded(
              child: _searchQuery.trim().isNotEmpty
                  ? _SearchResults(
                      query: _searchQuery,
                      results: searchResults,
                      controller: widget.controller,
                      onEdit: _editEntry,
                      onDelete: _deleteEntry,
                    )
                  : SingleChildScrollView(
                      controller: _monthScrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Column(
                        children: [
                          for (var day = 1; day <= daysInMonth; day++)
                            _buildDayCard(day),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayCard(int day) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);

    final isToday =
        _isViewingCurrentMonth && day == widget.controller.today.day;

    return _GoodThingsDayCard(
      key: isToday
          ? _todayCardKey
          : ValueKey('${date.year}-${date.month}-${date.day}'),
      date: date,
      weekdayName: _weekdayNames[date.weekday - 1],
      entries: widget.controller.goodThingsForDate(date),
      canAdd: widget.controller.canAddGoodThingForDate(date),
      maximumFutureDate: widget.controller.maximumFutureDate,
      controller: widget.controller,
      onEdit: _editEntry,
      onDelete: _deleteEntry,
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.results,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final String query;
  final List<GoodThing> results;
  final LighthouseController controller;
  final Future<void> Function(GoodThing entry) onEdit;
  final Future<void> Function(GoodThing entry) onDelete;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Keine Einträge für „$query“ gefunden.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = results[index];
        final isAhead = entry.date.isAfter(controller.today);

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: CircleAvatar(
              child: Icon(
                isAhead ? Icons.arrow_forward : Icons.auto_awesome,
                size: 18,
              ),
            ),
            title: Text(entry.text),
            subtitle: Text(
              '${_twoDigits(entry.date.day)}.'
              '${_twoDigits(entry.date.month)}.'
              '${entry.date.year} · '
              '${isAhead ? 'Ahead' : 'Good'}',
            ),
            onTap: () => onEdit(entry),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit(entry);
                }

                if (value == 'delete') {
                  onDelete(entry);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                  PopupMenuItem(value: 'delete', child: Text('Löschen')),
                ];
              },
            ),
          ),
        );
      },
    );
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class _GoodThingsDayCard extends StatelessWidget {
  const _GoodThingsDayCard({
    super.key,
    required this.date,
    required this.weekdayName,
    required this.entries,
    required this.canAdd,
    required this.maximumFutureDate,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime date;
  final String weekdayName;
  final List<GoodThing> entries;
  final bool canAdd;
  final DateTime maximumFutureDate;
  final LighthouseController controller;
  final Future<void> Function(GoodThing entry) onEdit;
  final Future<void> Function(GoodThing entry) onDelete;

  bool get _isToday {
    final today = controller.today;

    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  bool get _isFuture {
    return date.isAfter(controller.today);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isToday
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isToday
              ? colorScheme.primary.withValues(alpha: 0.45)
              : colorScheme.outlineVariant,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 650;

          final dateArea = SizedBox(
            width: narrow ? double.infinity : 125,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekdayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isToday
                              ? 'Heute'
                              : _isFuture
                              ? 'Ahead'
                              : 'Good',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          final entryArea = Column(
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SavedGoodThingLine(
                    entry: entry,
                    onEdit: () => onEdit(entry),
                    onDelete: () => onDelete(entry),
                  ),
                ),
              if (canAdd)
                _QuickEntryField(date: date, controller: controller)
              else
                _FutureLimitMessage(maximumFutureDate: maximumFutureDate),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [dateArea, const SizedBox(height: 14), entryArea],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dateArea,
              const SizedBox(width: 20),
              Expanded(child: entryArea),
            ],
          );
        },
      ),
    );
  }
}

class _SavedGoodThingLine extends StatelessWidget {
  const _SavedGoodThingLine({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final GoodThing entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(child: Text(entry.text)),
              IconButton(
                tooltip: 'Bearbeiten',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'Löschen',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickEntryField extends StatefulWidget {
  const _QuickEntryField({required this.date, required this.controller});

  final DateTime date;
  final LighthouseController controller;

  @override
  State<_QuickEntryField> createState() => _QuickEntryFieldState();
}

class _QuickEntryFieldState extends State<_QuickEntryField> {
  final TextEditingController _textController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool _isSaving = false;
  bool _hasFocus = false;
  String _query = '';

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();

    if (text.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.controller.addGoodThing(date: widget.date, text: text);

    _textController.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _query = '';
      _isSaving = false;
    });

    _focusNode.requestFocus();
  }

  Future<void> _selectSuggestion(String suggestion) async {
    _textController
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);

    setState(() {
      _query = suggestion;
    });

    await _submit();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Texts already saved for this day – never suggest an instant duplicate.
    final existingForDay = widget.controller
        .goodThingsForDate(widget.date)
        .map((entry) => entry.text.trim().toLowerCase())
        .toSet();

    final suggestions = (_hasFocus || _query.trim().isNotEmpty)
        ? widget.controller
              .suggestionsFor(_query)
              .where(
                (text) => !existingForDay.contains(text.trim().toLowerCase()),
              )
              .toList()
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Write something good …',
            prefixIcon: const Icon(Icons.add),
            suffixIcon: _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Mit Enter speichern',
                    onPressed: _submit,
                    icon: const Icon(Icons.arrow_forward),
                  ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(suggestion),
                  onPressed: () async => await _selectSuggestion(suggestion),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FutureLimitMessage extends StatelessWidget {
  const _FutureLimitMessage({required this.maximumFutureDate});

  final DateTime maximumFutureDate;

  @override
  Widget build(BuildContext context) {
    final day = maximumFutureDate.day.toString().padLeft(2, '0');
    final month = maximumFutureDate.month.toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Ahead-Einträge sind bis '
        '$day.$month.${maximumFutureDate.year} möglich.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
