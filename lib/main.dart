import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/app.dart';
import 'src/services/startup_service.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Explicitly use hash URL strategy for web (e.g., /#/home)
  // This prevents server-side routing issues on refresh.
  if (kIsWeb) {
    setUrlStrategy(const HashUrlStrategy());
  }

  if (kDebugMode) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // No .env file found, using default values.
    }
  }

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // Initialize app data (auth token, competitions, current user) before
  // the router evaluates redirects. Otherwise the auth gate would race the
  // first frame and could push the user to /login on cold load.
  await StartupService.initialize();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(MyApp(settingsController: settingsController));
}
