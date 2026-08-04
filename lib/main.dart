import 'package:flutter/material.dart';

import 'app/lighthouse_app.dart';
import 'data/lighthouse_database.dart';
import 'state/lighthouse_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = LighthouseDatabase();
  final controller = LighthouseController(database);

  await controller.initialize();

  runApp(LighthouseApp(controller: controller));
}
