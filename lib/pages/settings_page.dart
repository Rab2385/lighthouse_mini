import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/lighthouse_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final LighthouseController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameController;

  bool _savingName = false;

  AppStrings get _strings => widget.controller.strings;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.controller.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _savingName = true);

    await widget.controller.setUserName(_nameController.text);

    if (!mounted) {
      return;
    }

    setState(() => _savingName = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_strings.nameSaved)));
  }

  Future<void> _clearAllData() async {
    final strings = _strings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.clearAllDataQ),
          content: Text(strings.clearAllDataText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.deleteEverything),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.controller.clearAllData();
    _nameController.clear();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_strings.localDataDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final theme = Theme.of(context);
        final strings = _strings;

        Widget sectionCard({required String title, required Widget child}) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.settings,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.settingsSubtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),

                    sectionCard(
                      title: strings.language,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'de', label: Text('Deutsch')),
                          ButtonSegment(value: 'en', label: Text('English')),
                        ],
                        selected: {widget.controller.languageCode},
                        onSelectionChanged: (selection) {
                          widget.controller.setLanguage(selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: SwitchListTile(
                        title: Text(strings.darkMode),
                        subtitle: Text(strings.darkModeSubtitle),
                        secondary: const Icon(Icons.dark_mode_outlined),
                        value: widget.controller.darkMode,
                        onChanged: widget.controller.setDarkMode,
                      ),
                    ),
                    const SizedBox(height: 16),

                    sectionCard(
                      title: strings.yourName,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.yourNameSubtitle),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveName(),
                            decoration: InputDecoration(
                              labelText: strings.name,
                              hintText: strings.nameHint,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _savingName ? null : _saveName,
                              icon: _savingName
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(strings.save),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    sectionCard(
                      title: strings.privacy,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(strings.privacyText)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    sectionCard(
                      title: strings.dangerZone,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.dangerZoneText),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _clearAllData,
                            icon: const Icon(Icons.delete_forever),
                            label: Text(strings.clearAllData),
                          ),
                        ],
                      ),
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
