import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../pages/lighthouse_shell.dart';
import '../state/lighthouse_controller.dart';

class LighthouseApp extends StatefulWidget {
  const LighthouseApp({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<LighthouseApp> createState() => _LighthouseAppState();
}

class _LighthouseAppState extends State<LighthouseApp> {
  static const Color _petrol = Color(0xFF0B4F57);

  late final ThemeData _lightTheme = _buildLightTheme();
  late final ThemeData _darkTheme = _buildDarkTheme();

  late bool _darkMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.controller.darkMode;
    _locale = widget.controller.appLocale;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// Rebuild `MaterialApp` only when something it actually consumes changes.
  /// Every other data change is handled by the pages' own listeners, so the
  /// root Navigator / Localizations are never torn down mid-interaction.
  void _onControllerChanged() {
    final darkMode = widget.controller.darkMode;
    final locale = widget.controller.appLocale;

    if (darkMode != _darkMode || locale != _locale) {
      setState(() {
        _darkMode = darkMode;
        _locale = locale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lighthouse',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      locale: _locale,
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LighthouseShell(controller: widget.controller),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _petrol,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: Colors.white,
        borderColor: const Color(0xFFDDE1E7),
        focusColor: _petrol,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE2F0F1),
        selectedIconTheme: IconThemeData(color: _petrol),
        selectedLabelTextStyle: TextStyle(
          color: _petrol,
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
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4BA3A9),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF111718),
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF172022),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: const Color(0xFF1B2527),
        borderColor: const Color(0xFF344346),
        focusColor: const Color(0xFF6AB8BD),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF172022),
        indicatorColor: Color(0xFF203A3D),
        selectedIconTheme: IconThemeData(color: Color(0xFF86CDD1)),
        selectedLabelTextStyle: TextStyle(
          color: Color(0xFF86CDD1),
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF172022),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D3B3D)),
        ),
      ),
      dividerColor: const Color(0xFF2D3B3D),
    );
  }

  InputDecorationTheme _inputTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: focusColor, width: 1.5),
      ),
    );
  }
}
