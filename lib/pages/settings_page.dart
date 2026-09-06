import 'package:flutter/material.dart';

import '../state/lighthouse_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.controller,
  });

  final LighthouseController controller;

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {
  late final TextEditingController _nameController;

  bool _savingName = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.controller.userName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() {
      _savingName = true;
    });

    await widget.controller.setUserName(
      _nameController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _savingName = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Name gespeichert.'),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Alle lokalen Daten löschen?',
          ),
          content: const Text(
            'Good Things, Habit-Markierungen, '
            'eigene Habits und Einstellungen '
            'werden dauerhaft gelöscht. '
            'Dieser Schritt kann nicht '
            'rückgängig gemacht werden.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Alles löschen',
              ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lokale Daten wurden gelöscht.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              40,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 760,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aussehen, Name und lokale Daten.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title:
                                const Text('Dark Mode'),
                            subtitle: const Text(
                              'Ruhiges dunkles Petrol-Design.',
                            ),
                            secondary:
                                const Icon(
                              Icons.dark_mode_outlined,
                            ),
                            value: widget
                                .controller.darkMode,
                            onChanged: (value) {
                              widget.controller
                                  .setDarkMode(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dein Name',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Wird für die persönliche '
                              'Begrüßung auf der Good-Things-Seite '
                              'genutzt.',
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller:
                                  _nameController,
                              textInputAction:
                                  TextInputAction.done,
                              onSubmitted:
                                  (_) => _saveName(),
                              decoration:
                                  const InputDecoration(
                                labelText: 'Name',
                                hintText:
                                    'Zum Beispiel Robert',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment:
                                  Alignment.centerRight,
                              child:
                                  FilledButton.icon(
                                onPressed: _savingName
                                    ? null
                                    : _saveName,
                                icon: _savingName
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save_outlined,
                                      ),
                                label:
                                    const Text('Speichern'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Privacy',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Alle Einträge werden derzeit '
                              'nur lokal auf diesem Gerät '
                              'gespeichert. Es werden keine '
                              'Journaltexte an einen Server '
                              'übertragen.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gefahrenzone',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Löscht alle lokalen Daten '
                              'dieser Lighthouse-Installation.',
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed:
                                  _clearAllData,
                              icon: const Icon(
                                Icons.delete_forever,
                              ),
                              label: const Text(
                                'Alle lokalen Daten löschen',
                              ),
                            ),
                          ],
                        ),
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
