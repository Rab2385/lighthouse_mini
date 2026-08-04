import 'package:flutter/material.dart';

import '../state/lighthouse_controller.dart';
import 'good_things_page.dart';
import 'habits_page.dart';
import 'review_page.dart';
import 'settings_page.dart';

class LighthouseShell extends StatefulWidget {
  const LighthouseShell({
    super.key,
    required this.controller,
  });

  final LighthouseController controller;

  @override
  State<LighthouseShell> createState() =>
      _LighthouseShellState();
}

class _LighthouseShellState
    extends State<LighthouseShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      GoodThingsPage(
        controller: widget.controller,
      ),
      HabitsPage(
        controller: widget.controller,
      ),
      ReviewPage(
        controller: widget.controller,
      ),
      SettingsPage(
        controller: widget.controller,
      ),
    ];
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar =
            constraints.maxWidth >= 850;

        if (showSidebar) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: true,
                  minExtendedWidth: 220,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectPage,
                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      24,
                    ),
                    child: _LighthouseLogo(),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(
                        Icons.auto_awesome_outlined,
                      ),
                      selectedIcon: Icon(
                        Icons.auto_awesome,
                      ),
                      label: Text('Good Things'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(
                        Icons.grid_view_outlined,
                      ),
                      selectedIcon: Icon(
                        Icons.grid_view,
                      ),
                      label: Text('Habits'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(
                        Icons.insights_outlined,
                      ),
                      selectedIcon: Icon(
                        Icons.insights,
                      ),
                      label: Text('Review'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(
                        Icons.settings_outlined,
                      ),
                      selectedIcon: Icon(
                        Icons.settings,
                      ),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
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
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Image.asset(
                    'assets/images/lighthouse_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.light_mode_outlined,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lighthouse Mini',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectPage,
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.auto_awesome_outlined,
                ),
                selectedIcon: Icon(
                  Icons.auto_awesome,
                ),
                label: 'Good',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.grid_view_outlined,
                ),
                selectedIcon: Icon(
                  Icons.grid_view,
                ),
                label: 'Habits',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.insights_outlined,
                ),
                selectedIcon: Icon(
                  Icons.insights,
                ),
                label: 'Review',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                ),
                selectedIcon: Icon(
                  Icons.settings,
                ),
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
    return SizedBox(
      width: 188,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ClipRect(
              child: Transform.scale(
                scale: 2.5,
                child: Image.asset(
                  'assets/images/lighthouse_logo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Icon(
                      Icons.light_mode_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Lighthouse',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
                Text(
                  'Mini',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
