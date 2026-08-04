import 'package:flutter/material.dart';

import '../state/lighthouse_controller.dart';
import 'good_things_page.dart';
import 'habits_page.dart';

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
        final showSidebar = constraints.maxWidth >= 850;

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
                  ],
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
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Image.asset(
                    'assets/images/lighthouse_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lighthouse Mini',
                  style: TextStyle(
                    color: Color(0xFF123F46),
                    fontWeight: FontWeight.w700,
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
                label: 'Good Things',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: 'Habits',
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
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lighthouse',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF123F46),
                  ),
                ),
                Text(
                  'Development',
                  style: TextStyle(color: Color.fromARGB(255, 16, 137, 167)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
