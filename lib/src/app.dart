import 'package:eurocup_frontend/src/athletes/athlete_detail_view.dart';
import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/crews/crew_detail_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/home_page_view.dart';
import 'package:eurocup_frontend/src/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The AnimatedBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case LoginView.routeName:
                    return LoginView();
                  case HomePage.routeName:
                    return const HomePage();
                  case AthleteListView.routeName:
                    return AthleteListView();
                  case AthleteDetailView.routeName:
                    return const AthleteDetailView();
                  case CrewListView.routeName:
                    return const CrewListView();
                  case CrewDetailView.routeName:
                    return const CrewDetailView();
                  case AthletePickerView.routeName:
                    return const AthletePickerView();
                  default:
                    return LoginView();
                }
              },
            );
          },
        );
      },
    );
  }
}
