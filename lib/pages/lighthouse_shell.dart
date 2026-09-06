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
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 850;

        if (showSidebar) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: true,
                  minExtendedWidth: 220,

                  // Good Things, Habits and Review use indexes 0–2.
                  // Settings is opened through the separate bottom button.
                  selectedIndex: _selectedIndex < 3 ? _selectedIndex : null,

                  onDestinationSelected: _selectPage,

                  // Keep the logo at the top and Settings at the bottom.
                  leadingAtTop: true,
                  trailingAtBottom: true,
                  groupAlignment: -1,

                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(16, 22, 16, 26),
                    child: _LighthouseLogo(),
                  ),

                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.auto_awesome_outlined),
                      selectedIcon: Icon(Icons.auto_awesome),
                      label: Text('Good Things'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view),
                      label: Text('Habits'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights),
                      label: Text('Review'),
                    ),
                  ],

                  trailing: _SidebarSettingsButton(
                    selected: _selectedIndex == 3,
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Good',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: 'Habits',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Review',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
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
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = selected
        ? colorScheme.primaryContainer
        : Colors.transparent;

    final foregroundColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Settings',
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
                      'Settings',
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
