import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/lighthouse_controller.dart';
import '../widgets/backup_card.dart';
import '../widgets/page_title.dart';

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

    // A failed save was rolled back and already reported by the shell.
    if (widget.controller.userName != _nameController.text.trim()) {
      return;
    }

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

    final cleared = await widget.controller.clearAllData();

    if (!cleared || !mounted) {
      return;
    }

    _nameController.clear();

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
            padding: EdgeInsets.fromLTRB(
              24,
              isPhoneLayout(context) ? 12 : 24,
              24,
              40,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageTitle(
                      title: strings.settings,
                      subtitle: strings.settingsSubtitle,
                    ),
                    const SizedBox(height: 22),

                    BackupCard(controller: widget.controller),
                    const SizedBox(height: 16),

                    _ReminderCard(controller: widget.controller),
                    const SizedBox(height: 16),

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

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                strings.helpersTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SwitchListTile(
                              title: Text(strings.quickEntryTitle),
                              subtitle: Text(strings.quickEntrySubtitle),
                              secondary: const Icon(Icons.edit_note),
                              value: widget.controller.quickEntryOnOpen,
                              onChanged: widget.controller.setQuickEntryOnOpen,
                            ),
                            SwitchListTile(
                              title: Text(strings.showMemoriesTitle),
                              subtitle: Text(strings.showMemoriesSubtitle),
                              secondary: const Icon(
                                Icons.auto_awesome_outlined,
                              ),
                              value: widget.controller.showMemories,
                              onChanged: widget.controller.setShowMemories,
                            ),
                          ],
                        ),
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

/// The evening reminder: on/off and the time. Only works in the phone app.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.controller});

  final LighthouseController controller;

  Future<void> _toggle(BuildContext context, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = await controller.setReminderEnabled(value);

    if (value && !changed) {
      messenger.showSnackBar(
        SnackBar(content: Text(controller.strings.reminderPermissionDenied)),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final minutes = controller.reminderMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );

    if (picked != null) {
      await controller.setReminderMinutes(picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = controller.strings;
    final supported = controller.reminderSupported;
    final minutes = controller.reminderMinutes;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(strings.reminderCardTitle),
              subtitle: Text(
                supported
                    ? strings.reminderCardText
                    : strings.reminderUnsupported,
              ),
              secondary: const Icon(Icons.notifications_none),
              value: controller.reminderEnabled,
              onChanged: supported ? (value) => _toggle(context, value) : null,
            ),
            if (controller.reminderEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(context),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(strings.reminderAt(time)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
