import 'package:eurocup_frontend/src/administration/administration_view.dart';
import 'package:eurocup_frontend/src/athletes/athlete_detail_view.dart';
import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/clubs/club_adel_list_view.dart';
import 'package:eurocup_frontend/src/clubs/club_details_view.dart';
import 'package:eurocup_frontend/src/clubs/club_list_view.dart';
import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/crews/crew_detail_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/home_page_view.dart';
import 'package:eurocup_frontend/src/login_view.dart';
import 'package:eurocup_frontend/src/qr_scanner/barcode_scanner_controller.dart';
import 'package:eurocup_frontend/src/races/discipline_race_list_view.dart';
import 'package:eurocup_frontend/src/races/race_crew_detail_view.dart';
import 'package:eurocup_frontend/src/races/race_detail_view.dart';
import 'package:eurocup_frontend/src/teams/team_list_view.dart';
import 'package:eurocup_frontend/src/users/user_detail_view.dart';
import 'package:eurocup_frontend/src/users/users_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'clubs/club_athlete_list_view.dart';
import 'crews/crew_detail_print.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'teams/discipline_list_view.dart';

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
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: AnimatedBuilder(
        animation: settingsController,
        builder: (BuildContext context, Widget? child) {
          return Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: MaterialApp(
              //           home: FutureBuilder(
              // future: ReadToken(),
              // builder: (context, snapshot) {
              //   switch (snapshot.connectionState) {
              //     case ConnectionState.none:
              //     case ConnectionState.waiting:
              //       return CircularProgressIndicator();
              //     default:
              //       if (snapshot.hasError)
              //         return Text('Error: ${snapshot.error}');
              //       // else if (snapshot.data == null)
              //         return LoginView();
              //   }
              // }),
              // Providing a restorationScopeId allows the Navigator built by the
              // MaterialApp to restore the navigation stack when a user leaves and
              // returns to the app after it has been killed while running in the
              // background.
              restorationScopeId: 'app',
              debugShowCheckedModeBanner: false,

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
              // theme: ThemeData(),
              theme: ThemeData(
                fontFamily: 'Roboto',
                primarySwatch: Colors.blue,
                canvasColor: Colors.white,
                datePickerTheme: const DatePickerThemeData(
                    backgroundColor: Colors.grey,
                    surfaceTintColor: Colors.amber),
                appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        Colors.black //here you can give the text color
                    ),
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
                ),
                textButtonTheme: TextButtonThemeData(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.resolveWith(
                        (Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled)
                          ? null
                          : const Color.fromARGB(255, 0, 80, 150);
                    }),
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.resolveWith(
                        (Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled)
                          ? null
                          : Colors.white;
                    }),
                    backgroundColor: MaterialStateProperty.resolveWith(
                        (Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled)
                          ? null
                          : const Color.fromARGB(255, 0, 80, 150);
                    }),
                  ),
                ),
                brightness: Brightness.light,
                primaryColor: Colors.amber,
                // accentColor: Colors.black,
                splashColor: Colors.blue,
              ),

              darkTheme: ThemeData.dark(),
              themeMode: ThemeMode.light, //settingsController.themeMode, //

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
                      case AdministrationPage.routeName:
                        return const AdministrationPage();
                      case UserListView.routeName:
                        return const UserListView();
                      case UserDetailView.routeName:
                        return const UserDetailView();
                      case AthleteListView.routeName:
                        return AthleteListView();
                      case ClubListView.routeName:
                        return const ClubListView();
                      case ClubAthleteListView.routeName:
                        return ClubAthleteListView();
                      case AthleteDetailView.routeName:
                        return const AthleteDetailView();
                      case CrewListView.routeName:
                        return const CrewListView();
                      case CrewDetailView.routeName:
                        return const CrewDetailView();
                      case AthletePickerView.routeName:
                        return const AthletePickerView();
                      case TeamListView.routeName:
                        return const TeamListView();
                      case DisciplineListView.routeName:
                        return const DisciplineListView();
                      case DisciplineRaceListView.routeName:
                        return const DisciplineRaceListView();
                      case RaceDetailView.routeName:
                        return const RaceDetailView();
                      case RaceCrewDetailView.routeName:
                        return const RaceCrewDetailView();
                      case BarCodeScannerController.routeName:
                        return const BarCodeScannerController();
                      case ClubDetailView.routeName:
                        return const ClubDetailView();
                      case CrewDetailPrint.routeName:
                        return const CrewDetailPrint();
                      case ClubAdelListView.routeName:
                        return const ClubAdelListView();
                      default:
                        return LoginView();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
