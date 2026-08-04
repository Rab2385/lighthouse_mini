import 'package:flutter/material.dart';

import '../pages/lighthouse_shell.dart';
import '../state/lighthouse_controller.dart';

class LighthouseApp extends StatelessWidget {
  const LighthouseApp({super.key, required this.controller});

  final LighthouseController controller;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF3567C8);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Lighthouse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFE9F0FF),
          selectedIconTheme: IconThemeData(color: seedColor),
          selectedLabelTextStyle: TextStyle(
            color: seedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
        ),
      ),
      home: LighthouseShell(controller: controller),
    );
  }
}
