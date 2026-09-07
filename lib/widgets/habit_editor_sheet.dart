import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/habit.dart';
import '../state/lighthouse_controller.dart';

/// A single pickable symbol plus the words (German + English) that find it.
typedef _Emoji = ({String char, String cat, String terms});

/// Curated symbol set for habits — grouped, calm, and small enough to scan.
/// A full emoji keyboard would be overkill here; these cover the vast majority
/// of habits people track.
const List<_Emoji> _emojiCatalog = [
  // --- activity -------------------------------------------------------------
  (char: '🏃', cat: 'activity', terms: 'sport lauf laufen run running jog rennen cardio'),
  (char: '🚶', cat: 'activity', terms: 'gehen spazieren walk steps schritte'),
  (char: '🏋️', cat: 'activity', terms: 'gym kraft krafttraining weights strength workout'),
  (char: '🚴', cat: 'activity', terms: 'rad fahrrad radfahren bike cycling'),
  (char: '🏊', cat: 'activity', terms: 'schwimmen swim swimming'),
  (char: '🧘', cat: 'activity', terms: 'yoga meditation meditieren atmen breathe stretch dehnen'),
  (char: '🧗', cat: 'activity', terms: 'klettern bouldern climb climbing'),
  (char: '⚽', cat: 'activity', terms: 'fussball fußball soccer ball training'),
  (char: '🤸', cat: 'activity', terms: 'turnen mobility beweglichkeit stretch dehnen'),
  (char: '⛰️', cat: 'activity', terms: 'wandern hike hiking berg mountain'),
  (char: '🏄', cat: 'activity', terms: 'surfen surf sport'),
  (char: '🥊', cat: 'activity', terms: 'boxen box boxing kampfsport'),
  // --- food & drink --------------------------------------------------------
  (char: '💧', cat: 'food', terms: 'wasser water trinken drink hydration'),
  (char: '☕', cat: 'food', terms: 'kaffee coffee'),
  (char: '🍵', cat: 'food', terms: 'tee tea matcha'),
  (char: '🥤', cat: 'food', terms: 'getränk drink smoothie shake'),
  (char: '🍷', cat: 'food', terms: 'wein wine alkohol alcohol'),
  (char: '🍺', cat: 'food', terms: 'bier beer alkohol alcohol'),
  (char: '🚭', cat: 'food', terms: 'rauchen nicht smoke nonsmoking quit'),
  (char: '🥗', cat: 'food', terms: 'salat salad gesund healthy gemüse veggies'),
  (char: '🍎', cat: 'food', terms: 'obst fruit apfel apple snack'),
  (char: '🥦', cat: 'food', terms: 'gemüse vegetables broccoli greens'),
  (char: '🍳', cat: 'food', terms: 'kochen cook cooking frühstück breakfast'),
  (char: '🍫', cat: 'food', terms: 'zucker sugar süß sweets naschen'),
  // --- health -------------------------------------------------------------
  (char: '💊', cat: 'health', terms: 'vitamin vitamine pille pill tablette medizin medication supplement'),
  (char: '😴', cat: 'health', terms: 'schlaf schlafen sleep bett rest'),
  (char: '🛌', cat: 'health', terms: 'früh ins bett bedtime schlafenszeit'),
  (char: '🦷', cat: 'health', terms: 'zähne zahn zahnseide teeth brush floss'),
  (char: '🧴', cat: 'health', terms: 'hautpflege skincare creme sonnencreme lotion'),
  (char: '🧼', cat: 'health', terms: 'hygiene waschen wash hände hands'),
  (char: '🩺', cat: 'health', terms: 'gesundheit health checkup blutdruck'),
  (char: '⚖️', cat: 'health', terms: 'wiegen weigh gewicht weight waage'),
  (char: '🧠', cat: 'health', terms: 'mental fokus focus achtsamkeit mindful'),
  (char: '🩹', cat: 'health', terms: 'pause break erholung recovery'),
  // --- work --------------------------------------------------------------
  (char: '💼', cat: 'work', terms: 'arbeit work job büro office'),
  (char: '💻', cat: 'work', terms: 'code coding programmieren develop laptop computer'),
  (char: '📝', cat: 'work', terms: 'notizen notes planen plan todo aufgaben'),
  (char: '📞', cat: 'work', terms: 'anruf call telefon phone kontakt'),
  (char: '📊', cat: 'work', terms: 'zahlen report analyse analytics dashboard'),
  (char: '📅', cat: 'work', terms: 'kalender calendar planung schedule'),
  (char: '⏰', cat: 'work', terms: 'früh aufstehen wake alarm morgens routine'),
  (char: '🎯', cat: 'work', terms: 'ziel goal fokus focus'),
  (char: '📧', cat: 'work', terms: 'email mail inbox postfach'),
  (char: '🧾', cat: 'work', terms: 'finanzen budget geld money ausgaben expenses'),
  (char: '💰', cat: 'work', terms: 'sparen save geld money budget'),
  (char: '📚', cat: 'work', terms: 'lernen learn study studieren kurs course'),
  // --- mind --------------------------------------------------------------
  (char: '📖', cat: 'mind', terms: 'lesen read reading buch book'),
  (char: '✍️', cat: 'mind', terms: 'schreiben write writing tagebuch journal'),
  (char: '🎧', cat: 'mind', terms: 'musik music podcast hören listen hörbuch'),
  (char: '🎨', cat: 'mind', terms: 'malen zeichnen draw paint kunst art kreativ'),
  (char: '🎸', cat: 'mind', terms: 'gitarre guitar instrument üben practice musik'),
  (char: '🎹', cat: 'mind', terms: 'klavier piano keyboard üben practice'),
  (char: '📷', cat: 'mind', terms: 'foto photo fotografie photography'),
  (char: '🧩', cat: 'mind', terms: 'puzzle rätsel game spiel denksport'),
  (char: '🗣️', cat: 'mind', terms: 'sprache language vokabeln speak duolingo'),
  (char: '🙏', cat: 'mind', terms: 'dankbarkeit gratitude dankbar grateful beten pray'),
  (char: '🕯️', cat: 'mind', terms: 'ruhe calm reflexion reflect achtsam'),
  (char: '💭', cat: 'mind', terms: 'reflexion journal gedanken thoughts tagesrückblick'),
  // --- home --------------------------------------------------------------
  (char: '🧹', cat: 'home', terms: 'putzen clean aufräumen tidy haushalt'),
  (char: '🧺', cat: 'home', terms: 'wäsche laundry waschen'),
  (char: '🍽️', cat: 'home', terms: 'abwasch dishes küche kitchen spülen'),
  (char: '🛏️', cat: 'home', terms: 'bett machen make bed'),
  (char: '🪴', cat: 'home', terms: 'pflanzen plants gießen water garten'),
  (char: '🗑️', cat: 'home', terms: 'müll trash rausbringen entsorgen'),
  (char: '🔧', cat: 'home', terms: 'reparieren fix diy heimwerken'),
  (char: '👕', cat: 'home', terms: 'kleidung clothes anziehen outfit'),
  (char: '🐕', cat: 'home', terms: 'hund dog gassi walk haustier pet'),
  (char: '🐈', cat: 'home', terms: 'katze cat haustier pet'),
  (char: '💐', cat: 'home', terms: 'blumen flowers pflege'),
  (char: '🧽', cat: 'home', terms: 'schwamm bad bathroom reinigen scrub'),
  // --- nature ------------------------------------------------------------
  (char: '🌳', cat: 'nature', terms: 'natur nature draußen outdoor wald park'),
  (char: '🌱', cat: 'nature', terms: 'wachsen grow garten garden setzling'),
  (char: '☀️', cat: 'nature', terms: 'sonne sun licht tageslicht daylight'),
  (char: '🌙', cat: 'nature', terms: 'mond moon abend night abendroutine'),
  (char: '⭐', cat: 'nature', terms: 'stern star wunsch highlight'),
  (char: '🌊', cat: 'nature', terms: 'meer see wasser ocean kaltduschen'),
  (char: '🥾', cat: 'nature', terms: 'wandern hike boots trekking'),
  (char: '🏕️', cat: 'nature', terms: 'camping zelt outdoor natur'),
  (char: '🍂', cat: 'nature', terms: 'herbst autumn spazieren draußen'),
  (char: '❄️', cat: 'nature', terms: 'kalt cold winter kaltdusche eisbaden'),
  (char: '🌸', cat: 'nature', terms: 'frühling spring blüte bloom'),
  (char: '🚲', cat: 'nature', terms: 'radfahren bike pendeln commute'),
];

const List<String> _emojiCategoryOrder = [
  'activity',
  'food',
  'health',
  'work',
  'mind',
  'home',
  'nature',
];

/// High-confidence name → symbol hints. First substring match wins, so the more
/// specific keys go first.
const Map<String, String> _emojiNameHints = {
  'meditier': '🧘',
  'meditat': '🧘',
  'yoga': '🧘',
  'atem': '🧘',
  'lesen': '📖',
  'read': '📖',
  'buch': '📖',
  'book': '📖',
  'wasser': '💧',
  'water': '💧',
  'trinken': '💧',
  'hydrat': '💧',
  'kaffee': '☕',
  'coffee': '☕',
  'tee ': '🍵',
  'tea': '🍵',
  'matcha': '🍵',
  'lauf': '🏃',
  'renn': '🏃',
  'jog': '🏃',
  'run': '🏃',
  'cardio': '🏃',
  'spazier': '🚶',
  'walk': '🚶',
  'schritte': '🚶',
  'steps': '🚶',
  'gehen': '🚶',
  'rad': '🚴',
  'fahrrad': '🚴',
  'bike': '🚴',
  'cycl': '🚴',
  'schwimm': '🏊',
  'swim': '🏊',
  'klett': '🧗',
  'boulder': '🧗',
  'climb': '🧗',
  'gym': '🏋️',
  'kraft': '🏋️',
  'hantel': '🏋️',
  'weight': '🏋️',
  'workout': '🏋️',
  'wandern': '⛰️',
  'hike': '⛰️',
  'hiking': '⛰️',
  'box': '🥊',
  'schlaf': '😴',
  'sleep': '😴',
  'bett': '🛏️',
  'aufsteh': '⏰',
  'wake': '⏰',
  'früh auf': '⏰',
  'vitamin': '💊',
  'pille': '💊',
  'pill': '💊',
  'tablet': '💊',
  'medi': '💊',
  'supplement': '💊',
  'zähne': '🦷',
  'zahn': '🦷',
  'teeth': '🦷',
  'floss': '🦷',
  'zahnseide': '🦷',
  'haut': '🧴',
  'skincare': '🧴',
  'creme': '🧴',
  'sonnencreme': '🧴',
  'wieg': '⚖️',
  'weigh': '⚖️',
  'waage': '⚖️',
  'rauch': '🚭',
  'smoke': '🚭',
  'arbeit': '💼',
  'work': '💼',
  'büro': '💼',
  'office': '💼',
  'code': '💻',
  'coding': '💻',
  'programm': '💻',
  'develop': '💻',
  'schreib': '✍️',
  'write': '✍️',
  'writing': '✍️',
  'tagebuch': '✍️',
  'journal': '✍️',
  'notiz': '📝',
  'note': '📝',
  'planen': '📝',
  'plan ': '📝',
  'todo': '📝',
  'musik': '🎧',
  'music': '🎧',
  'podcast': '🎧',
  'hörbuch': '🎧',
  'gitarre': '🎸',
  'guitar': '🎸',
  'klavier': '🎹',
  'piano': '🎹',
  'mal': '🎨',
  'zeichn': '🎨',
  'draw': '🎨',
  'paint': '🎨',
  'kunst': '🎨',
  'foto': '📷',
  'photo': '📷',
  'sprache': '🗣️',
  'vokabel': '🗣️',
  'language': '🗣️',
  'duolingo': '🗣️',
  'lern': '📚',
  'learn': '📚',
  'study': '📚',
  'studier': '📚',
  'kurs': '📚',
  'course': '📚',
  'dankbar': '🙏',
  'gratitude': '🙏',
  'grateful': '🙏',
  'beten': '🙏',
  'pray': '🙏',
  'kirche': '🙏',
  'geld': '💰',
  'money': '💰',
  'sparen': '💰',
  'budget': '💰',
  'finanz': '🧾',
  'ausgab': '🧾',
  'expense': '🧾',
  'email': '📧',
  'mail': '📧',
  'inbox': '📧',
  'anruf': '📞',
  'call': '📞',
  'telefon': '📞',
  'ziel': '🎯',
  'goal': '🎯',
  'fokus': '🎯',
  'focus': '🎯',
  'putz': '🧹',
  'clean': '🧹',
  'aufräum': '🧹',
  'tidy': '🧹',
  'haushalt': '🧹',
  'wäsche': '🧺',
  'laundry': '🧺',
  'abwasch': '🍽️',
  'spülen': '🍽️',
  'dishes': '🍽️',
  'geschirr': '🍽️',
  'pflanze': '🪴',
  'plant': '🪴',
  'gieß': '🪴',
  'garten': '🪴',
  'garden': '🪴',
  'müll': '🗑️',
  'trash': '🗑️',
  'hund': '🐕',
  'dog': '🐕',
  'gassi': '🐕',
  'katze': '🐈',
  'cat ': '🐈',
  'koch': '🍳',
  'cook': '🍳',
  'frühstück': '🍳',
  'breakfast': '🍳',
  'salat': '🥗',
  'salad': '🥗',
  'gemüse': '🥦',
  'veggie': '🥦',
  'vegetable': '🥦',
  'obst': '🍎',
  'fruit': '🍎',
  'apfel': '🍎',
  'apple': '🍎',
  'zucker': '🍫',
  'sugar': '🍫',
  'süß': '🍫',
  'naschen': '🍫',
  'wein': '🍷',
  'wine': '🍷',
  'alkohol': '🍷',
  'alcohol': '🍷',
  'bier': '🍺',
  'beer': '🍺',
  'natur': '🌳',
  'nature': '🌳',
  'draußen': '🌳',
  'outdoor': '🌳',
  'wald': '🌳',
  'sonne': '☀️',
  'sun': '☀️',
  'tageslicht': '☀️',
  'daylight': '☀️',
  'kalt dusch': '❄️',
  'kaltdusch': '❄️',
  'cold shower': '❄️',
  'eisbad': '❄️',
  'camping': '🏕️',
  'zelt': '🏕️',
  'puzzle': '🧩',
  'rätsel': '🧩',
};

String? _suggestEmoji(String name) {
  final normalised = name.toLowerCase().trim();
  if (normalised.isEmpty) {
    return null;
  }
  for (final entry in _emojiNameHints.entries) {
    if (normalised.contains(entry.key.trim())) {
      return entry.value;
    }
  }
  return null;
}

String _categoryLabel(AppStrings strings, String cat) {
  switch (cat) {
    case 'activity':
      return strings.emojiCatActivity;
    case 'food':
      return strings.emojiCatFood;
    case 'health':
      return strings.emojiCatHealth;
    case 'work':
      return strings.emojiCatWork;
    case 'mind':
      return strings.emojiCatMind;
    case 'home':
      return strings.emojiCatHome;
    case 'nature':
      return strings.emojiCatNature;
    default:
      return '';
  }
}

/// The bottom sheet used to create or edit a habit: name, a searchable curated
/// symbol grid, and a single wide save button. It goes full height on a phone
/// and stays a centred panel on wider screens, so it never overflows the way
/// the old cramped dialog did.
class HabitEditorSheet extends StatefulWidget {
  const HabitEditorSheet({super.key, required this.controller, this.habit});

  final LighthouseController controller;
  final Habit? habit;

  static Future<void> show(
    BuildContext context, {
    required LighthouseController controller,
    Habit? habit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => HabitEditorSheet(controller: controller, habit: habit),
    );
  }

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late final TextEditingController _nameController;
  final TextEditingController _searchController = TextEditingController();

  String _emoji = '';
  String _search = '';

  /// Once the user picks a symbol themselves, stop auto-suggesting from the name.
  bool _emojiPinned = false;
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');

    final existing = widget.habit?.emoji ?? '';
    if (existing.isNotEmpty && existing != '✓') {
      _emoji = existing;
      _emojiPinned = true;
    }

    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_emojiPinned) {
      return;
    }
    final suggestion = _suggestEmoji(_nameController.text) ?? '';
    if (suggestion != _emoji) {
      setState(() => _emoji = suggestion);
    }
  }

  void _pickEmoji(String emoji) {
    setState(() {
      _emoji = emoji;
      _emojiPinned = true;
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    setState(() => _saving = true);

    final controller = widget.controller;
    if (_isEditing) {
      await controller.updateHabit(
        id: widget.habit!.id,
        name: _nameController.text,
        emoji: _emoji,
      );
    } else {
      await controller.addHabit(
        name: _nameController.text,
        emoji: _emoji,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<_Emoji> get _filtered {
    final query = _search.toLowerCase().trim();
    if (query.isEmpty) {
      return _emojiCatalog;
    }
    return _emojiCatalog
        .where((e) => e.char == query || e.terms.contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = widget.controller.strings;

    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final nameEmpty = _nameController.text.trim().isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                children: [
                  _EmojiPreview(emoji: _emoji),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isEditing ? strings.editHabit : strings.newHabit,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      autofocus: !_isEditing,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: strings.name,
                        hintText: strings.habitNameHint,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      strings.symbol,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: strings.searchSymbol,
                        suffixIcon: _search.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _search = '');
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EmojiGrid(
                      options: _filtered,
                      selected: _emoji,
                      grouped: _search.trim().isEmpty,
                      strings: strings,
                      onPick: _pickEmoji,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.cancel),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: (nameEmpty || _saving) ? null : _save,
                      child: Text(
                        _isEditing ? strings.save : strings.createHabit,
                      ),
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

/// The round symbol chip shown next to the sheet title.
class _EmojiPreview extends StatelessWidget {
  const _EmojiPreview({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEmoji = emoji.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: hasEmoji
          ? Text(emoji, style: const TextStyle(fontSize: 22))
          : Icon(Icons.check, size: 20, color: colorScheme.primary),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({
    required this.options,
    required this.selected,
    required this.grouped,
    required this.strings,
    required this.onPick,
  });

  final List<_Emoji> options;
  final String selected;
  final bool grouped;
  final AppStrings strings;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            strings.noSymbolMatch,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    Widget tile(_Emoji option) {
      final isSelected = option.char == selected;
      return Semantics(
        button: true,
        selected: isSelected,
        label: option.char,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onPick(option.char),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.16)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(option.char, style: const TextStyle(fontSize: 21)),
          ),
        ),
      );
    }

    if (!grouped) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map(tile).toList(),
      );
    }

    final children = <Widget>[];
    for (final cat in _emojiCategoryOrder) {
      final inCat = options.where((e) => e.cat == cat).toList();
      if (inCat.isEmpty) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _categoryLabel(strings, cat),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
      children.add(
        Wrap(spacing: 8, runSpacing: 8, children: inCat.map(tile).toList()),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
