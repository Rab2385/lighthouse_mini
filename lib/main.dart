import 'package:flutter/material.dart';

import 'app/lighthouse_app.dart';
import 'data/lighthouse_database.dart';
import 'state/lighthouse_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = LighthouseDatabase();
  final controller = LighthouseController(database);

  try {
    await controller.initialize();
  } catch (error, stackTrace) {
    debugPrint('Lighthouse failed to start: $error\n$stackTrace');
    runApp(_StartupErrorApp(error: error));
    return;
  }

  runApp(LighthouseApp(controller: controller));
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Lighthouse konnte nicht gestartet werden.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Der lokale Speicher (IndexedDB) ist in diesem '
                    'Browser nicht verfügbar. Im privaten Modus mancher '
                    'Browser ist das erwartbar – bitte in einem normalen '
                    'Fenster erneut öffnen.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
