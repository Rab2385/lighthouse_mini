import 'package:flutter/material.dart';

import '../state/lighthouse_controller.dart';
import '../widgets/lighthouse_mark.dart';
import 'good_things_page.dart';
import 'habits_page.dart';
import 'review_page.dart';
import 'settings_page.dart';

class LighthouseShell extends StatefulWidget {
  const LighthouseShell({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<LighthouseShell> createState() => _LighthouseShellState();
}

class _LighthouseShellState extends State<LighthouseShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      GoodThingsPage(controller: widget.controller),
      HabitsPage(controller: widget.controller),
      ReviewPage(controller: widget.controller),
      SettingsPage(controller: widget.controller),
    ];
  }

  void _selectPage(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.controller.strings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 850;

        // A phone that's wide enough for the rail (i.e. held in landscape) gets
        // an icon-only rail, not the 220px extended one — landscape needs the
        // width for the habit grid, and its height for the rows.
        final isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
        final extendedRail = showSidebar && !isPhone;

        if (showSidebar) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: extendedRail,
                  minExtendedWidth: 220,
                  // Icons only when collapsed: keeps the rail narrow and, more
                  // importantly, short enough to fit a landscape phone's height.
                  labelType: extendedRail
                      ? null
                      : NavigationRailLabelType.none,
                  // Belt-and-braces for very short heights / large text scale.
                  scrollable: !extendedRail,

                  // Good Things, Habits and Review use indexes 0–2.
                  // Settings is opened through the separate bottom button.
                  selectedIndex: _selectedIndex < 3 ? _selectedIndex : null,

                  onDestinationSelected: _selectPage,

                  // Keep the logo at the top and Settings at the bottom.
                  leadingAtTop: true,
                  trailingAtBottom: true,
                  groupAlignment: -1,

                  leading: extendedRail
                      ? const Padding(
                          padding: EdgeInsets.fromLTRB(16, 22, 16, 26),
                          child: _LighthouseLogo(),
                        )
                      : const Padding(
                          padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
                          child: LighthouseMark(height: 26),
                        ),

                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      selectedIcon: const Icon(Icons.auto_awesome),
                      label: Text(strings.goodThings),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view),
                      label: Text(strings.habits),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.insights_outlined),
                      selectedIcon: const Icon(Icons.insights),
                      label: Text(strings.review),
                    ),
                  ],

                  trailing: _SidebarSettingsButton(
                    label: strings.settings,
                    selected: _selectedIndex == 3,
                    extended: extendedRail,
                    onPressed: () {
                      _selectPage(3);
                    },
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LighthouseMark(height: 28),
                const SizedBox(width: 10),
                Text(
                  'Lighthouse',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectPage,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome),
                label: strings.navGood,
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view),
                label: strings.habits,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: strings.review,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: strings.settings,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LighthouseLogo extends StatelessWidget {
  const _LighthouseLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 188,
      child: Row(
        children: [
          const LighthouseMark(height: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lighthouse',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                Text('Mini', style: TextStyle(color: colorScheme.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSettingsButton extends StatelessWidget {
  const _SidebarSettingsButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.extended = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  /// Matches the rail: a wide pill when extended, an icon-only destination
  /// when the rail is collapsed (phone in landscape).
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final foregroundColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: Tooltip(
            message: label,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    selected ? Icons.settings : Icons.settings_outlined,
                    size: 24,
                    color: foregroundColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final backgroundColor = selected
        ? colorScheme.primaryContainer
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 196,
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.settings : Icons.settings_outlined,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
