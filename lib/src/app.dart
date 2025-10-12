import 'package:eurocup_frontend/src/administration/administration_view.dart';
import 'package:eurocup_frontend/src/administration/event_list_view.dart';
import 'package:eurocup_frontend/src/administration/event_detail_view.dart';
import 'package:eurocup_frontend/src/administration/discipline_list_view.dart' as admin;
import 'package:eurocup_frontend/src/administration/discipline_detail_view.dart';
import 'package:eurocup_frontend/src/athletes/athlete_detail_view.dart';
import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/model/user.dart';
import 'package:eurocup_frontend/src/clubs/club_adel_list_view.dart';
import 'package:eurocup_frontend/src/clubs/club_details_view.dart';
import 'package:eurocup_frontend/src/clubs/club_detail_page.dart';
import 'package:eurocup_frontend/src/clubs/club_list_view.dart';
import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/crews/crew_detail_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/home_page_view.dart';
import 'package:eurocup_frontend/src/login_view.dart';
import 'package:eurocup_frontend/src/forgot_password_view.dart';
import 'package:eurocup_frontend/src/reset_password_view.dart';
import 'package:eurocup_frontend/src/qr_scanner/barcode_scanner_controller.dart';
import 'package:eurocup_frontend/src/races/discipline_race_list_view.dart';
import 'package:eurocup_frontend/src/races/race_crew_detail_view.dart';
import 'package:eurocup_frontend/src/races/race_detail_view.dart';
import 'package:eurocup_frontend/src/races/race_results_list_view.dart';
import 'package:eurocup_frontend/src/races/race_result_detail_view.dart';
import 'package:eurocup_frontend/src/races/competition_selector_view.dart';
import 'package:eurocup_frontend/src/teams/team_list_view.dart';
import 'package:eurocup_frontend/src/users/user_detail_view.dart';
import 'package:eurocup_frontend/src/users/users_list_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:eurocup_frontend/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'clubs/club_athlete_list_view.dart';
import 'crews/crew_detail_print.dart';
import 'qr_scanner/ai_barcode_scanner.dart';
import 'qr_scanner/ai_barcode_scanner_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'teams/discipline_list_view.dart';
import 'common.dart';
import 'api_helper.dart' as api;
import 'services/startup_service.dart';
import 'widgets/startup_wrapper.dart';

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
              debugShowCheckedModeBanner: false,

              // Set initial route based on current URL for web deep linking
              initialRoute: kIsWeb ? _getInitialRoute() : LoginView.routeName,

              // Initialize app data on startup
              builder: (context, child) {
                // Trigger startup service initialization on app start
                if (!StartupService.isInitialized && !StartupService.isLoading) {
                  StartupService.initialize();
                }
                // Apply max width constraint of 1024px
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1024),
                    child: child ?? const SizedBox(),
                  ),
                );
              },

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
                // accentColor: Colors.black,
                splashColor: Colors.blue,
              ),

              darkTheme: ThemeData.dark(),
              themeMode: ThemeMode.light, //settingsController.themeMode, //

              // Define a function to handle named routes in order to support
              // Flutter web url navigation and deep linking.
              onGenerateRoute: (RouteSettings routeSettings) {
                // Extract route arguments from URL if available (for web deep linking)
                // But preserve existing arguments if they were passed programmatically
                print('onGenerateRoute: route = ${routeSettings.name}');
                print('onGenerateRoute: original arguments = ${routeSettings.arguments}');
                print('onGenerateRoute: arguments type = ${routeSettings.arguments.runtimeType}');

                final extractedArguments = _extractArgumentsFromSettings(routeSettings);
                final finalArguments = routeSettings.arguments ?? extractedArguments;

                print('onGenerateRoute: extracted arguments = $extractedArguments');
                print('onGenerateRoute: final arguments = $finalArguments');

                final updatedSettings = RouteSettings(
                  name: routeSettings.name,
                  arguments: finalArguments,
                );

                return MaterialPageRoute<void>(
                  settings: updatedSettings,
                  builder: (BuildContext context) {
                    // Router: Building route for ${routeSettings.name}
                    // Router: Arguments extracted: $finalArguments
                    // Handle routes that might have query parameters
                    final routeName = routeSettings.name ?? '';

                    // Skip the initial '/' route if we're on web with a fragment
                    if (kIsWeb && routeName == '/' && Uri.base.fragment.isNotEmpty) {
                      // Router: Skipping initial / route, waiting for fragment route
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    switch (routeSettings.name) {
                      case SettingsView.routeName:
                        return SettingsView(controller: settingsController);
                      case LoginView.routeName:
                        return const LoginView();
                      case ForgotPasswordView.routeName:
                        return const ForgotPasswordView();
                      case ResetPasswordView.routeName:
                        // Router: Creating ResetPasswordView
                        return const ResetPasswordView();
                    }

                    // Handle routes with query parameters
                    if (routeName.startsWith('/reset-password')) {
                      // Router: Creating ResetPasswordView for route with params
                      return const ResetPasswordView();
                    }

                    // Router: Second switch checking route: ${routeSettings.name}
                    // Router: CompetitionSelectorView.routeName = ${CompetitionSelectorView.routeName}
                    switch (routeSettings.name) {
                      case HomePage.routeName:
                        return StartupWrapper(
                          targetRoute: routeSettings.name,
                          child: const HomePage(),
                        );
                      case AdministrationPage.routeName:
                        return const AdministrationPage();
                      case EventListView.routeName:
                        return const EventListView();
                      case EventDetailView.routeName:
                        return const EventDetailView();
                      case admin.AdminDisciplineListView.routeName:
                        return const admin.AdminDisciplineListView();
                      case DisciplineDetailView.routeName:
                        return const DisciplineDetailView();
                      case DisciplineListView.routeName:
                        return const DisciplineListView();
                      case UserListView.routeName:
                        return const UserListView();
                      case UserDetailView.routeName:
                        print('Route: UserDetailView');
                        print('Original routeSettings.arguments: ${routeSettings.arguments}');
                        print('Updated settings.arguments: ${updatedSettings.arguments}');
                        print('Final arguments: $finalArguments');
                        // Pass the user directly if available
                        final userArg = updatedSettings.arguments is User ? updatedSettings.arguments as User : null;
                        return UserDetailView(user: userArg);
                      case AthleteListView.routeName:
                        return AthleteListView();
                      case ClubListView.routeName:
                        return const ClubListView();
                      case ClubAthleteListView.routeName:
                        return ClubAthleteListView();
                      case AthleteDetailView.routeName:
                        return const AthleteDetailView();
                      case CrewListView.routeName:
                        return StartupWrapper(
                          targetRoute: routeSettings.name,
                          child: const CrewListView(),
                        );
                      case CrewDetailView.routeName:
                        return const CrewDetailView();
                      case AthletePickerView.routeName:
                        return const AthletePickerView();
                      case TeamListView.routeName:
                        return const TeamListView();
                      case DisciplineRaceListView.routeName:
                        return StartupWrapper(
                          targetRoute: routeSettings.name,
                          child: const DisciplineRaceListView(),
                        );
                      case RaceDetailView.routeName:
                        return StartupWrapper(
                          targetRoute: routeSettings.name,
                          child: const RaceDetailView(),
                        );
                      case RaceCrewDetailView.routeName:
                        return StartupWrapper(
                          targetRoute: routeSettings.name,
                          child: const RaceCrewDetailView(),
                        );
                      case CompetitionSelectorView.routeName:
                        // Competition selector is public - no auth needed
                        // Router: Creating CompetitionSelectorView
                        return const CompetitionSelectorView();
                      case RaceResultsListView.routeName:
                        // Race results can be viewed publicly
                        // Load token and basic data if available, but don't require authentication
                        loadToken();
                        return const RaceResultsListView();
                      case RaceResultDetailView.routeName:
                        // Check if we have the required raceResultId argument
                        if (finalArguments is Map && finalArguments['raceResultId'] == null) {
                          // If no argument, redirect to race results list
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(context).pushReplacementNamed(RaceResultsListView.routeName);
                          });
                          loadToken();
                          return const RaceResultsListView();
                        }
                        // Race result details can be viewed publicly
                        loadToken();
                        return const RaceResultDetailView();
                      case BarCodeScannerController.routeName:
                        return const BarCodeScannerController();
                      case ClubDetailView.routeName:
                        return const ClubDetailView();
                      case ClubDetailPage.routeName:
                        return const ClubDetailPage();
                      case CrewDetailPrint.routeName:
                        return const CrewDetailPrint();
                      case ClubAdelListView.routeName:
                        return const ClubAdelListView();
                      case AiBarcodeScanner.routeName:
                        return const AiBarcodeScanner();
                      default:
                        // For unknown routes, redirect to home page instead of login
                        // Router: Unknown route ${routeSettings.name}, redirecting to HomePage
                        return const HomePage();
                    }
                  },
                );
              },
          );
        },
    );
  }

  /// Extract the initial route from the current URL (for web deep linking)
  static String _getInitialRoute() {
    if (!kIsWeb) return LoginView.routeName;

    try {
      // Get current URL path from fragment for hash routing
      final uri = Uri.base;
      String routePath;

      // For hash routing, the route is in the fragment
      if (uri.fragment.isNotEmpty) {
        routePath = '/${uri.fragment}';
        // Remove the leading slash if fragment already has it
        if (routePath.startsWith('//')) {
          routePath = routePath.substring(1);
        }
        // Router: Initial route from fragment: $routePath
      } else {
        // Fall back to path-based routing
        final path = uri.path;
        routePath = path.startsWith('/') ? path : '/$path';
        // Router: Initial route from path: $routePath
      }

      // Define valid routes that can be accessed directly
      const validDirectRoutes = [
        LoginView.routeName,
        ForgotPasswordView.routeName,
        ResetPasswordView.routeName,
        HomePage.routeName,
        CompetitionSelectorView.routeName,
        RaceResultsListView.routeName,
        AthleteListView.routeName,
        ClubListView.routeName,
        CrewListView.routeName,
        TeamListView.routeName,
        DisciplineRaceListView.routeName,
        AdministrationPage.routeName,
        EventListView.routeName,
        admin.AdminDisciplineListView.routeName,
        DisciplineListView.routeName,
        UserListView.routeName,
      ];

      // Check if the route is valid for direct access
      // Router: Checking if $routePath is in validDirectRoutes
      if (validDirectRoutes.contains(routePath)) {
        // Router: Route is valid, returning: $routePath
        return routePath;
      }
      // Router: Route not in valid list

      // Handle routes that require parameters
      if (routePath == RaceResultDetailView.routeName) {
        // Check if we have the required parameter in query string
        final raceResultId = uri.queryParameters['raceResultId'];
        if (raceResultId != null) {
          return routePath;
        }
        // If no parameter, redirect to race results list
        return RaceResultsListView.routeName;
      }

      // For other routes that might require parameters, redirect to a safe default
      if (routePath.contains('detail') || routePath.contains('picker')) {
        return HomePage.routeName;
      }

      // Default fallback - check if path looks like a public race results view
      if (routePath.contains('race') || routePath.contains('result')) {
        return RaceResultsListView.routeName;
      }

      // Ultimate fallback
      return HomePage.routeName;
    } catch (e) {
      // In case of any error, return safe default
      return HomePage.routeName;
    }
  }

  /// Extract arguments from route settings and URL query parameters (for web deep linking)
  static dynamic _extractArgumentsFromSettings(RouteSettings routeSettings) {
    // If arguments are not a Map, return them as-is (e.g., User object)
    if (routeSettings.arguments != null && routeSettings.arguments is! Map<String, dynamic>) {
      return routeSettings.arguments;
    }

    Map<String, dynamic> arguments = {};

    // First, use any existing arguments
    if (routeSettings.arguments != null) {
      if (routeSettings.arguments is Map<String, dynamic>) {
        arguments.addAll(routeSettings.arguments as Map<String, dynamic>);
      }
    }

    // For web, also extract from URL query parameters
    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final queryParams = uri.queryParameters;
        // Extraction: URI = $uri
        // Extraction: Query params = $queryParams
        // Extraction: Route name = ${routeSettings.name}

        // Handle route-specific parameter extraction
        switch (routeSettings.name) {
          case RaceResultDetailView.routeName:
            if (queryParams.containsKey('raceResultId')) {
              final raceResultId = int.tryParse(queryParams['raceResultId']!);
              if (raceResultId != null) {
                arguments['raceResultId'] = raceResultId;
              }
            }
            break;

          case RaceResultsListView.routeName:
            if (queryParams.containsKey('eventId')) {
              arguments['eventId'] = queryParams['eventId'];
            }
            if (queryParams.containsKey('eventName')) {
              arguments['eventName'] = queryParams['eventName'];
            }
            break;

          case AthleteDetailView.routeName:
            if (queryParams.containsKey('athleteId')) {
              final athleteId = int.tryParse(queryParams['athleteId']!);
              if (athleteId != null) {
                arguments['athleteId'] = athleteId;
              }
            }
            break;

          case CrewDetailView.routeName:
            if (queryParams.containsKey('crewId')) {
              final crewId = int.tryParse(queryParams['crewId']!);
              if (crewId != null) {
                arguments['crewId'] = crewId;
              }
            }
            break;

          case RaceDetailView.routeName:
            if (queryParams.containsKey('raceId')) {
              final raceId = int.tryParse(queryParams['raceId']!);
              if (raceId != null) {
                arguments['raceId'] = raceId;
              }
            }
            break;
        }

        // Handle reset password route with query parameters
        final routeName = routeSettings.name ?? '';
        if (routeName.startsWith('/reset-password')) {
          // Extraction: Found reset-password route
          if (queryParams.containsKey('token')) {
            arguments['token'] = queryParams['token'];
            // Extraction: Token found in query params = ${queryParams['token']}
          } else if (routeName.contains('?token=')) {
            // Extraction: No token in query params, checking route name
            final tokenPart = routeName.split('?token=')[1];
            final token = tokenPart.split('&')[0]; // Get only the token part
            arguments['token'] = token;
            // Extraction: Token found in route name = $token
          } else {
            // Extraction: No token found anywhere
          }
        }
      } catch (e) {
        // In case of any error, just return existing arguments
        // Error extracting URL parameters: $e
      }
    }

    return arguments.isEmpty ? null : arguments;
  }

}
