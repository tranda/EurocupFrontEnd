import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../administration/administration_view.dart';
import '../administration/database_backup_view.dart';
import '../administration/discipline_detail_view.dart';
import '../administration/discipline_list_view.dart' as admin;
import '../administration/event_detail_view.dart';
import '../administration/event_list_view.dart';
import '../athletes/athlete_detail_view.dart';
import '../athletes/athlete_list_view.dart';
import '../clubs/club_adel_list_view.dart';
import '../clubs/club_athlete_list_view.dart';
import '../clubs/club_detail_page.dart';
import '../clubs/club_details_view.dart';
import '../clubs/club_list_view.dart';
import '../crews/athlete_picker_view.dart';
import '../crews/crew_detail_print.dart';
import '../crews/crew_detail_view.dart';
import '../crews/crew_list_view.dart';
import '../forgot_password_view.dart';
import '../home_page_view.dart';
import '../login_view.dart';
import '../model/user.dart';
import '../qr_scanner/ai_barcode_scanner.dart';
import '../qr_scanner/barcode_scanner_controller.dart';
import '../races/competition_selector_view.dart';
import '../races/discipline_race_list_view.dart';
import '../races/race_crew_detail_view.dart';
import '../races/race_detail_view.dart';
import '../races/race_result_detail_view.dart';
import '../races/race_results_list_view.dart';
import '../reset_password_view.dart';
import '../services/startup_service.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_view.dart';
import '../teams/discipline_list_view.dart';
import '../teams/team_list_view.dart';
import '../users/user_detail_view.dart';
import '../users/users_list_view.dart';

/// Paths that do not require authentication.
const Set<String> _publicPaths = {
  LoginView.routeName,
  ForgotPasswordView.routeName,
  ResetPasswordView.routeName,
  CompetitionSelectorView.routeName,
  RaceResultsListView.routeName,
  RaceResultDetailView.routeName,
};

/// Build the GoRouter for the app.
///
/// Routes are defined as a flat list. The browser's URL is the source of
/// truth, so refresh + browser back/forward behave like a normal web app —
/// every page entry pushes a real history entry, and refresh restores the
/// route from the URL without losing the back stack.
GoRouter buildRouter(SettingsController settingsController) {
  return GoRouter(
    initialLocation: HomePage.routeName,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final path = state.uri.path;
      // Public pages always render without an auth check.
      if (_publicPaths.contains(path)) return null;
      // Everything else requires a valid session.
      if (!StartupService.isAuthenticated) {
        return LoginView.routeName;
      }
      return null;
    },
    routes: [
      // ------- Public --------------------------------------------------
      _route(LoginView.routeName, (state) => const LoginView()),
      _route(ForgotPasswordView.routeName, (state) => const ForgotPasswordView()),
      _route(ResetPasswordView.routeName, (state) => const ResetPasswordView()),
      _route(CompetitionSelectorView.routeName, (state) => const CompetitionSelectorView()),
      _route(RaceResultsListView.routeName, (state) => const RaceResultsListView()),
      GoRoute(
        path: RaceResultDetailView.routeName,
        redirect: (context, state) {
          // Detail page needs an id; fall back to the list if absent.
          final hasId = state.uri.queryParameters.containsKey('raceResultId') ||
              (state.extra is Map &&
                  (state.extra as Map)['raceResultId'] != null);
          if (!hasId) return RaceResultsListView.routeName;
          return null;
        },
        pageBuilder: (context, state) => MaterialPage(
          arguments: state.extra,
          child: const RaceResultDetailView(),
        ),
      ),

      // ------- Settings ------------------------------------------------
      GoRoute(
        path: SettingsView.routeName,
        pageBuilder: (context, state) => MaterialPage(
          arguments: state.extra,
          child: SettingsView(controller: settingsController),
        ),
      ),

      // ------- Auth-required ------------------------------------------
      _route(HomePage.routeName, (state) => const HomePage()),
      _route(AdministrationPage.routeName, (state) => const AdministrationPage()),
      _route(DatabaseBackupView.routeName, (state) => const DatabaseBackupView()),
      _route(EventListView.routeName, (state) => const EventListView()),
      _route(EventDetailView.routeName, (state) => const EventDetailView()),
      _route(admin.AdminDisciplineListView.routeName,
          (state) => const admin.AdminDisciplineListView()),
      _route(DisciplineDetailView.routeName, (state) => const DisciplineDetailView()),
      _route(DisciplineListView.routeName, (state) => const DisciplineListView()),
      _route(UserListView.routeName, (state) => const UserListView()),
      GoRoute(
        path: UserDetailView.routeName,
        pageBuilder: (context, state) {
          final user = state.extra is User ? state.extra as User : null;
          return MaterialPage(
            arguments: state.extra,
            child: UserDetailView(user: user),
          );
        },
      ),
      _route(AthleteListView.routeName, (state) => AthleteListView()),
      _route(ClubListView.routeName, (state) => const ClubListView()),
      _route(ClubAthleteListView.routeName, (state) => ClubAthleteListView()),
      _route(AthleteDetailView.routeName, (state) => const AthleteDetailView()),
      _route(CrewListView.routeName, (state) => const CrewListView()),
      _route(CrewDetailView.routeName, (state) => const CrewDetailView()),
      _route(AthletePickerView.routeName, (state) => const AthletePickerView()),
      _route(TeamListView.routeName, (state) => const TeamListView()),
      _route(DisciplineRaceListView.routeName, (state) => const DisciplineRaceListView()),
      _route(RaceDetailView.routeName, (state) => const RaceDetailView()),
      _route(RaceCrewDetailView.routeName, (state) => const RaceCrewDetailView()),
      _route(BarCodeScannerController.routeName, (state) => const BarCodeScannerController()),
      _route(ClubDetailView.routeName, (state) => const ClubDetailView()),
      _route(ClubDetailPage.routeName, (state) => const ClubDetailPage()),
      _route(CrewDetailPrint.routeName, (state) => const CrewDetailPrint()),
      _route(ClubAdelListView.routeName, (state) => const ClubAdelListView()),
      _route(AiBarcodeScanner.routeName, (state) => const AiBarcodeScanner()),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(child: Text('No route for ${state.uri}')),
      ),
    ),
  );
}

/// Helper that builds a GoRoute whose page preserves `state.extra` as the
/// route's `settings.arguments` so existing widgets that read
/// `ModalRoute.of(context).settings.arguments` continue to work unchanged.
GoRoute _route(String path, Widget Function(GoRouterState state) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => MaterialPage(
      arguments: state.extra,
      child: builder(state),
    ),
  );
}
