import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart';
import 'settings/settings_controller.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _router = buildRouter(widget.settingsController);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp.router(
          restorationScopeId: 'app',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          builder: (context, child) {
            // Apply max width constraint of 1024px
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: child ?? const SizedBox(),
              ),
            );
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            fontFamily: 'Roboto',
            primarySwatch: Colors.blue,
            canvasColor: Colors.white,
            datePickerTheme: const DatePickerThemeData(
                backgroundColor: Colors.grey, surfaceTintColor: Colors.amber),
            appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white, foregroundColor: Colors.black),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 80, 150)),
              displayMedium: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 80, 150)),
              displaySmall: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 80, 150)),
              headlineMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color.fromARGB(255, 0, 80, 150)),
              bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 255, 255)),
              bodyMedium: TextStyle(
                  fontSize: 12, color: Color.fromARGB(255, 255, 255, 255)),
              titleMedium: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color.fromARGB(255, 0, 80, 150)),
              titleSmall: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 80, 150),
                  height: 1.0),
              labelSmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Color.fromARGB(192, 255, 255, 255),
                  height: 1.0),
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                    (Set<WidgetState> states) {
                  return states.contains(WidgetState.disabled)
                      ? null
                      : const Color.fromARGB(255, 0, 80, 150);
                }),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                    (Set<WidgetState> states) {
                  return states.contains(WidgetState.disabled)
                      ? null
                      : Colors.white;
                }),
                backgroundColor: WidgetStateProperty.resolveWith(
                    (Set<WidgetState> states) {
                  return states.contains(WidgetState.disabled)
                      ? null
                      : const Color.fromARGB(255, 0, 80, 150);
                }),
              ),
            ),
            brightness: Brightness.light,
            primaryColor: Colors.amber,
            splashColor: Colors.blue,
          ),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
        );
      },
    );
  }
}
