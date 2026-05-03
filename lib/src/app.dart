import 'package:eurocup_frontend/src/administration/administration_view.dart';
import 'package:eurocup_frontend/src/administration/database_backup_view.dart';
import 'package:eurocup_frontend/src/administration/event_list_view.dart';
import 'package:eurocup_frontend/src/administration/event_detail_view.dart';
import 'package:eurocup_frontend/src/administration/discipline_list_view.dart' as admin;
import 'package:eurocup_frontend/src/administration/discipline_detail_view.dart';
import 'package:eurocup_frontend/src/administration/schedule/schedule_builder_page.dart';
import 'package:eurocup_frontend/src/administration/schedule/schedule_event_picker.dart';
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
import 'package:eurocup_frontend/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'clubs/club_athlete_list_view.dart';
import 'crews/crew_detail_print.dart';
import 'qr_scanner/ai_barcode_scanner.dart';
import 'services/startup_service.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'teams/discipline_list_view.dart';
import 'common.dart';
import 'widgets/startup_wrapper.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  /// Map of route → its logical parent. Used by `onGenerateInitialRoutes` to
  /// reconstruct a navigation stack on cold load (e.g. after a refresh) so
  /// browser back walks up the natural hierarchy instead of dropping the user
  /// at home or a placeholder.
  ///
  /// Routes not present here are treated as top-level (no parent).
  static const Map<String, String> _routeParents = {
    // Administration sub-pages → /administration_page
    UserListView.routeName: AdministrationPage.routeName,
    EventListView.routeName: AdministrationPage.routeName,
    admin.AdminDisciplineListView.routeName: AdministrationPage.routeName,
    TeamListView.routeName: AdministrationPage.routeName,
    ClubListView.routeName: AdministrationPage.routeName,
    DatabaseBackupView.routeName: AdministrationPage.routeName,
    ClubAdelListView.routeName: AdministrationPage.routeName,
    ScheduleEventPicker.routeName: AdministrationPage.routeName,
    ScheduleBuilderPage.routeName: ScheduleEventPicker.routeName,

    // Detail pages → corresponding list/parent
    UserDetailView.routeName: UserListView.routeName,
    EventDetailView.routeName: EventListView.routeName,
    DisciplineDetailView.routeName: admin.AdminDisciplineListView.routeName,
    ClubDetailPage.routeName: ClubListView.routeName,
    ClubDetailView.routeName: ClubDetailPage.routeName,
    ClubAthleteListView.routeName: ClubDetailPage.routeName,
    AthleteDetailView.routeName: ClubAthleteListView.routeName,

    // Crews
    CrewDetailView.routeName: CrewListView.routeName,
    AthletePickerView.routeName: CrewDetailView.routeName,
    CrewDetailPrint.routeName: CrewDetailView.routeName,

    // Races (admin)
    RaceDetailView.routeName: DisciplineRaceListView.routeName,
    RaceCrewDetailView.routeName: RaceDetailView.routeName,

    // Race results (public branch — parent is the public selector)
    RaceResultsListView.routeName: CompetitionSelectorView.routeName,
    RaceResultDetailView.routeName: RaceResultsListView.routeName,

    // Direct children of home
    AdministrationPage.routeName: HomePage.routeName,
    CrewListView.routeName: HomePage.routeName,
    DisciplineListView.routeName: HomePage.routeName,
    DisciplineRaceListView.routeName: HomePage.routeName,
    CompetitionSelectorView.routeName: HomePage.routeName,
    AthleteListView.routeName: HomePage.routeName,
    BarCodeScannerController.routeName: HomePage.routeName,
    AiBarcodeScanner.routeName: HomePage.routeName,
    SettingsView.routeName: HomePage.routeName,
  };

  /// Walk the parent chain to build the implicit navigation stack for a
  /// deep-linked or refreshed route. Cycles are guarded against.
  List<String> _resolveStack(String leafRoute) {
    final stack = <String>[leafRoute];
    String? cursor = _routeParents[leafRoute];
    while (cursor != null && !stack.contains(cursor)) {
      stack.insert(0, cursor);
      cursor = _routeParents[cursor];
    }
    return stack;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          debugShowCheckedModeBanner: false,
          initialRoute: kIsWeb ? _getInitialRoute() : LoginView.routeName,
          builder: (context, child) {
            if (!StartupService.isInitialized && !StartupService.isLoading) {
              StartupService.initialize();
            }
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
          supportedLocales: const [Locale('en', '')],
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
          onGenerateRoute: _buildRoute,
          onGenerateInitialRoutes: (String initialRouteName) {
            // Walk the parent chain so a deep-link or refresh restores a
            // navigation stack, not just one route. Browser back then walks
            // up the hierarchy instead of dropping to home.
            return _resolveStack(initialRouteName)
                .map((name) => _buildRoute(RouteSettings(name: name)))
                .whereType<Route<dynamic>>()
                .toList();
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Route construction
  // ---------------------------------------------------------------------------

  /// Generates a [Route] for a given [RouteSettings]. Used both as
  /// `onGenerateRoute` (for runtime navigation) and by `onGenerateInitialRoutes`
  /// (when reconstructing the initial stack on cold load).
  Route<dynamic>? _buildRoute(RouteSettings routeSettings) {
    final extractedArguments = _extractArgumentsFromSettings(routeSettings);
    final finalArguments = routeSettings.arguments ?? extractedArguments;

    final updatedSettings = RouteSettings(
      name: routeSettings.name,
      arguments: finalArguments,
    );

    return MaterialPageRoute<void>(
      settings: updatedSettings,
      builder: (BuildContext context) {
        final routeName = routeSettings.name ?? '';

        // The bootstrap '/' slot — render a wrapped HomePage so it has a
        // working init/auth path rather than a dead-end spinner.
        if (kIsWeb && routeName == '/') {
          return const StartupWrapper(
            targetRoute: HomePage.routeName,
            child: HomePage(),
          );
        }

        // Public routes (no auth needed)
        switch (routeName) {
          case SettingsView.routeName:
            return SettingsView(controller: settingsController);
          case LoginView.routeName:
            return const LoginView();
          case ForgotPasswordView.routeName:
            return const ForgotPasswordView();
          case ResetPasswordView.routeName:
            return const ResetPasswordView();
        }
        if (routeName.startsWith('/reset-password')) {
          return const ResetPasswordView();
        }

        // Auth-gated routes
        switch (routeName) {
          case HomePage.routeName:
            return const StartupWrapper(
              targetRoute: HomePage.routeName,
              child: HomePage(),
            );
          case AdministrationPage.routeName:
            return const StartupWrapper(
              targetRoute: AdministrationPage.routeName,
              child: AdministrationPage(),
            );
          case ScheduleEventPicker.routeName:
            return const StartupWrapper(
              targetRoute: ScheduleEventPicker.routeName,
              child: ScheduleEventPicker(),
            );
          case ScheduleBuilderPage.routeName:
            return const StartupWrapper(
              targetRoute: ScheduleBuilderPage.routeName,
              child: ScheduleBuilderPage(),
            );
          case DatabaseBackupView.routeName:
            return const StartupWrapper(
              targetRoute: DatabaseBackupView.routeName,
              child: DatabaseBackupView(),
            );
          case EventListView.routeName:
            return const StartupWrapper(
              targetRoute: EventListView.routeName,
              child: EventListView(),
            );
          case EventDetailView.routeName:
            return const StartupWrapper(
              targetRoute: EventDetailView.routeName,
              child: EventDetailView(),
            );
          case admin.AdminDisciplineListView.routeName:
            return const StartupWrapper(
              targetRoute: admin.AdminDisciplineListView.routeName,
              child: admin.AdminDisciplineListView(),
            );
          case DisciplineDetailView.routeName:
            return const StartupWrapper(
              targetRoute: DisciplineDetailView.routeName,
              child: DisciplineDetailView(),
            );
          case DisciplineListView.routeName:
            return const StartupWrapper(
              targetRoute: DisciplineListView.routeName,
              child: DisciplineListView(),
            );
          case UserListView.routeName:
            return const StartupWrapper(
              targetRoute: UserListView.routeName,
              child: UserListView(),
            );
          case UserDetailView.routeName:
            final userArg = finalArguments is User ? finalArguments : null;
            return StartupWrapper(
              targetRoute: UserDetailView.routeName,
              child: UserDetailView(user: userArg),
            );
          case AthleteListView.routeName:
            return StartupWrapper(
              targetRoute: AthleteListView.routeName,
              child: AthleteListView(),
            );
          case ClubListView.routeName:
            return const StartupWrapper(
              targetRoute: ClubListView.routeName,
              child: ClubListView(),
            );
          case ClubAthleteListView.routeName:
            return StartupWrapper(
              targetRoute: ClubAthleteListView.routeName,
              child: ClubAthleteListView(),
            );
          case AthleteDetailView.routeName:
            return const StartupWrapper(
              targetRoute: AthleteDetailView.routeName,
              child: AthleteDetailView(),
            );
          case CrewListView.routeName:
            return const StartupWrapper(
              targetRoute: CrewListView.routeName,
              child: CrewListView(),
            );
          case CrewDetailView.routeName:
            return const StartupWrapper(
              targetRoute: CrewDetailView.routeName,
              child: CrewDetailView(),
            );
          case AthletePickerView.routeName:
            return const StartupWrapper(
              targetRoute: AthletePickerView.routeName,
              child: AthletePickerView(),
            );
          case TeamListView.routeName:
            return const StartupWrapper(
              targetRoute: TeamListView.routeName,
              child: TeamListView(),
            );
          case DisciplineRaceListView.routeName:
            return const StartupWrapper(
              targetRoute: DisciplineRaceListView.routeName,
              child: DisciplineRaceListView(),
            );
          case RaceDetailView.routeName:
            return const StartupWrapper(
              targetRoute: RaceDetailView.routeName,
              child: RaceDetailView(),
            );
          case RaceCrewDetailView.routeName:
            return const StartupWrapper(
              targetRoute: RaceCrewDetailView.routeName,
              child: RaceCrewDetailView(),
            );
          case BarCodeScannerController.routeName:
            return const StartupWrapper(
              targetRoute: BarCodeScannerController.routeName,
              child: BarCodeScannerController(),
            );
          case ClubDetailView.routeName:
            return const StartupWrapper(
              targetRoute: ClubDetailView.routeName,
              child: ClubDetailView(),
            );
          case ClubDetailPage.routeName:
            return const StartupWrapper(
              targetRoute: ClubDetailPage.routeName,
              child: ClubDetailPage(),
            );
          case CrewDetailPrint.routeName:
            return const StartupWrapper(
              targetRoute: CrewDetailPrint.routeName,
              child: CrewDetailPrint(),
            );
          case ClubAdelListView.routeName:
            return const StartupWrapper(
              targetRoute: ClubAdelListView.routeName,
              child: ClubAdelListView(),
            );
          case AiBarcodeScanner.routeName:
            return const StartupWrapper(
              targetRoute: AiBarcodeScanner.routeName,
              child: AiBarcodeScanner(),
            );
          case CompetitionSelectorView.routeName:
            return const CompetitionSelectorView();
          case RaceResultsListView.routeName:
            loadToken();
            return const RaceResultsListView();
          case RaceResultDetailView.routeName:
            if (finalArguments is Map &&
                finalArguments['raceResultId'] == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed(
                    RaceResultsListView.routeName);
              });
              loadToken();
              return const RaceResultsListView();
            }
            loadToken();
            return const RaceResultDetailView();
        }

        // Fallback: any unrecognized route resolves to wrapped HomePage so
        // unknown URLs still go through init/auth instead of rendering bare.
        return const StartupWrapper(
          targetRoute: HomePage.routeName,
          child: HomePage(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // URL → initial route detection (web only)
  // ---------------------------------------------------------------------------

  /// Extract the initial route from the current URL (for web deep linking).
  static String _getInitialRoute() {
    if (!kIsWeb) return LoginView.routeName;

    try {
      final uri = Uri.base;
      String routePath;

      // Hash routing puts the route in the fragment.
      if (uri.fragment.isNotEmpty) {
        routePath = '/${uri.fragment}';
        if (routePath.startsWith('//')) {
          routePath = routePath.substring(1);
        }
      } else {
        final path = uri.path;
        routePath = path.startsWith('/') ? path : '/$path';
      }

      // Strip query string before route matching — params are handled separately.
      final queryIndex = routePath.indexOf('?');
      if (queryIndex != -1) {
        routePath = routePath.substring(0, queryIndex);
      }

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
        ScheduleEventPicker.routeName,
      ];

      if (validDirectRoutes.contains(routePath)) {
        return routePath;
      }

      if (routePath == RaceResultDetailView.routeName) {
        final raceResultId = uri.queryParameters['raceResultId'];
        if (raceResultId != null) return routePath;
        return RaceResultsListView.routeName;
      }

      if (routePath.contains('detail') || routePath.contains('picker')) {
        return HomePage.routeName;
      }
      if (routePath.contains('race') || routePath.contains('result')) {
        return RaceResultsListView.routeName;
      }
      return HomePage.routeName;
    } catch (_) {
      return HomePage.routeName;
    }
  }

  /// Extract arguments from route settings and URL query parameters.
  static dynamic _extractArgumentsFromSettings(RouteSettings routeSettings) {
    if (routeSettings.arguments != null &&
        routeSettings.arguments is! Map<String, dynamic>) {
      return routeSettings.arguments;
    }

    Map<String, dynamic> arguments = {};
    if (routeSettings.arguments != null) {
      if (routeSettings.arguments is Map<String, dynamic>) {
        arguments.addAll(routeSettings.arguments as Map<String, dynamic>);
      }
    }

    if (kIsWeb) {
      try {
        final uri = Uri.base;
        // With HashUrlStrategy, query params live inside the URL fragment
        // (e.g. /#/race_results_list?eventId=5), not in uri.queryParameters.
        // Merge both so the function works regardless of strategy.
        final Map<String, String> queryParams =
            Map<String, String>.from(uri.queryParameters);
        if (uri.fragment.isNotEmpty) {
          try {
            queryParams.addAll(Uri.parse(uri.fragment).queryParameters);
          } catch (_) {}
        }

        switch (routeSettings.name) {
          case RaceResultDetailView.routeName:
            if (queryParams.containsKey('raceResultId')) {
              final raceResultId =
                  int.tryParse(queryParams['raceResultId']!);
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
              if (crewId != null) arguments['crewId'] = crewId;
            }
            break;
          case RaceDetailView.routeName:
            if (queryParams.containsKey('raceId')) {
              final raceId = int.tryParse(queryParams['raceId']!);
              if (raceId != null) arguments['raceId'] = raceId;
            }
            break;
        }

        final routeName = routeSettings.name ?? '';
        if (routeName.startsWith('/reset-password')) {
          if (queryParams.containsKey('token')) {
            arguments['token'] = queryParams['token'];
          } else if (routeName.contains('?token=')) {
            final tokenPart = routeName.split('?token=')[1];
            arguments['token'] = tokenPart.split('&')[0];
          }
        }
      } catch (_) {}
    }

    return arguments.isEmpty ? null : arguments;
  }
}
