import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/backup.dart';
import '../state/lighthouse_controller.dart';

/// Writes a backup file: a download on the web, the system "save as" / Files
/// dialog on Android, iOS and desktop.
Future<void> saveBackupFile(
  BuildContext context,
  LighthouseController controller,
) async {
  final strings = controller.strings;
  final messenger = ScaffoldMessenger.of(context);

  try {
    final backup = await controller.createBackup();

    final saved = await FilePicker.saveFile(
      fileName: Backup.fileNameFor(backup.createdAt),
      bytes: utf8.encode(backup.encode()),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    // null = the user closed the dialog. The web download has no dialog
    // to cancel, so it always counts as saved.
    if (saved == null && !kIsWeb) {
      return;
    }

    await controller.markBackupSaved(backup.createdAt);
    messenger.showSnackBar(SnackBar(content: Text(strings.backupSaved)));
  } catch (error) {
    debugPrint('Lighthouse could not save a backup: $error');
    messenger.showSnackBar(SnackBar(content: Text(strings.backupFailed)));
  }
}

/// Picks a backup file, shows what it contains, and restores it after the
/// user confirms. Nothing changes unless the whole file is valid.
Future<void> restoreBackupFile(
  BuildContext context,
  LighthouseController controller,
) async {
  final strings = controller.strings;
  final messenger = ScaffoldMessenger.of(context);

  final Backup backup;
  try {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) {
      return;
    }
    backup = Backup.decode(utf8.decode(await file.readAsBytes()));
  } on BackupException catch (error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (error.reason) {
          BackupProblem.notJson ||
          BackupProblem.notLighthouse => strings.backupNotLighthouse,
          BackupProblem.tooNew => strings.backupTooNew,
          BackupProblem.damaged => strings.backupDamaged,
        }),
      ),
    );
    return;
  } catch (error) {
    // Includes a file that isn't UTF-8 text at all.
    debugPrint('Lighthouse could not read a backup: $error');
    messenger.showSnackBar(
      SnackBar(content: Text(strings.backupNotLighthouse)),
    );
    return;
  }

  if (!context.mounted) {
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(strings.backupRestoreQ),
      content: Text(
        strings.backupRestoreText(
          '${strings.formatDate(backup.createdAt)} (v${backup.appVersion})',
          strings.backupCounts(
            backup.data.goodThingCount,
            backup.data.habitCount,
          ),
          strings.backupCounts(
            controller.goodThings.length,
            controller.habits.length,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(strings.backupRestore),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    return;
  }

  try {
    await controller.restoreBackup(backup);
  } catch (error) {
    debugPrint('Lighthouse could not restore a backup: $error');
    messenger.showSnackBar(SnackBar(content: Text(strings.backupFailed)));
    return;
  }

  // Language may have changed with the restored settings.
  final restoredStrings = controller.strings;
  messenger.showSnackBar(
    SnackBar(
      content: Text(restoredStrings.backupRestored),
      persist: false,
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: restoredStrings.undo,
        onPressed: () => undoRestore(messenger, controller),
      ),
    ),
  );
}

Future<void> undoRestore(
  ScaffoldMessengerState messenger,
  LighthouseController controller,
) async {
  try {
    await controller.undoRestore();
    messenger.showSnackBar(
      SnackBar(content: Text(controller.strings.backupUndone)),
    );
  } catch (error) {
    debugPrint('Lighthouse could not undo a restore: $error');
    messenger.showSnackBar(
      SnackBar(content: Text(controller.strings.backupFailed)),
    );
  }
}

/// The Backup section in Settings.
class BackupCard extends StatelessWidget {
  const BackupCard({super.key, required this.controller});

  final LighthouseController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = controller.strings;
    final lastBackupAt = controller.lastBackupAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.backup,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? '${strings.backupText} ${strings.backupTextWeb}'
                  : strings.backupText,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => saveBackupFile(context, controller),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(strings.backupSave),
                ),
                OutlinedButton.icon(
                  onPressed: () => restoreBackupFile(context, controller),
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(strings.backupRestore),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              [
                lastBackupAt == null
                    ? strings.noBackupYet
                    : strings.lastBackup(strings.formatDate(lastBackupAt)),
                strings.backupCounts(
                  controller.goodThings.length,
                  controller.habits.length,
                ),
              ].join(' · '),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (controller.hasSafetyBackup) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () =>
                    undoRestore(ScaffoldMessenger.of(context), controller),
                icon: const Icon(Icons.history, size: 18),
                label: Text(strings.backupUndoRestore),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The gentle "save a backup" reminder shown above the Good Things list.
class BackupReminderBanner extends StatelessWidget {
  const BackupReminderBanner({super.key, required this.controller});

  final LighthouseController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = controller.strings;
    final lastBackupAt = controller.lastBackupAt;

    final text = lastBackupAt == null
        ? strings.backupReminderNever
        : strings.backupReminder(
            DateTime.now().difference(lastBackupAt).inDays,
          );

    return Material(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        child: Row(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
            TextButton(
              onPressed: () => saveBackupFile(context, controller),
              child: Text(strings.backupNow),
            ),
            IconButton(
              tooltip: strings.dismiss,
              visualDensity: VisualDensity.compact,
              onPressed: controller.dismissBackupReminder,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
