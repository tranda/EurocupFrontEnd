
import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/races/discipline_race_list_view.dart';
import 'package:eurocup_frontend/src/races/competition_selector_view.dart';
import 'package:eurocup_frontend/src/races/boat_checkin_race_list_view.dart';
import 'package:eurocup_frontend/src/teams/team_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'administration/administration_view.dart';
import 'model/user.dart';
import 'common.dart';
import 'api_helper.dart' as api;
import 'services/startup_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const routeName = '/home_page';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User user = currentUser;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // If startup service hasn't initialized or user data is missing, show loading
    if (!StartupService.isInitialized || currentUser.accessLevel == null) {
      // Trigger initialization if not already done
      if (!StartupService.isInitialized && !StartupService.isLoading) {
        StartupService.initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }

      return Scaffold(
        appBar: appBar(title: 'Events Platform'),
        body: Container(
          decoration: naslovnaDecoration(),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final level = currentUser.accessLevel ?? -1;

    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      body: Container(
        decoration: bckDecoration(),
        child: ListView(
          children: [
            const MenuBanner(),
            if (level == 0)
              MenuSection(title: 'My club', rows: [
                MenuRow(
                  icon: Icons.groups,
                  title: 'List of Athletes',
                  onTap: () => Navigator.pushNamed(context, AthleteListView.routeName),
                ),
                MenuRow(
                  icon: Icons.flag,
                  title: 'Teams/Races',
                  onTap: () => Navigator.pushNamed(context, TeamListView.routeName),
                ),
                MenuRow(
                  icon: Icons.rowing,
                  title: 'Crew Members',
                  onTap: () => Navigator.pushNamed(context, CrewListView.routeName),
                ),
              ]),
            MenuSection(title: 'Races', rows: [
              if (level >= 0)
                MenuRow(
                  icon: Icons.list_alt,
                  title: 'Current Entries',
                  onTap: () => Navigator.pushNamed(context, DisciplineRaceListView.routeName),
                ),
              if (level >= 0)
                MenuRow(
                  icon: Icons.emoji_events,
                  title: 'Race Results',
                  onTap: () => Navigator.pushNamed(context, CompetitionSelectorView.routeName),
                ),
              if (level >= 1)
                MenuRow(
                  icon: Icons.qr_code_scanner,
                  title: 'Boat Check-in',
                  onTap: () => Navigator.pushNamed(context, BoatCheckinRaceListView.routeName),
                ),
            ]),
            MenuSection(title: 'Account', rows: [
              if (level >= 1)
                MenuRow(
                  icon: Icons.admin_panel_settings,
                  title: 'Administration',
                  onTap: () => Navigator.pushNamed(context, AdministrationPage.routeName),
                ),
              MenuRow(icon: Icons.logout, title: 'Log out', onTap: _logout),
            ]),
          ],
        ),
      ),
    );
  }

  void _logout() {
    // Call logout API first while token is still available
    api.sendLogoutRequest().then((value) {
      lastUser = null;
      lastPassword = null;
      currentUser = User();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }).catchError((error) {
      // Even if logout request fails, clear local data and go to login
      lastUser = null;
      lastPassword = null;
      clearToken();
      currentUser = User();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    });
  }

  void selectAndParseCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String csvString = decodeUnicode(result.files.single.bytes!);
      String delimiter = '\t';

      List<String> lines = csvString.split('\n');

      List<List<String>> csvTable =
          lines.map((line) => line.split(delimiter)).toList();

      var headers = csvTable[0];

      List<Athlete> athletes = [];
      for (var i = 1; i < csvTable.length; i++) {
        if (csvTable[i][0] != '') {
          var athlete = Athlete.edbf(headers, csvTable[i], DATEFORMAT);
          athletes.add(athlete);
        }
      }
      // Finished parsing csv

      var success = await api.sendAthletes(athletes);
      // Finished sending athletes
      if (success) {
        showInfoDialog(context, 'Message', 'Athletes imported', () {});
      } else {
        showInfoDialog(context, 'Server error', 'Please try again later.', () {});
      }
    } else {
      // User canceled the file selection
      // File selection canceled.
    }
  }

  String decodeUnicode(List<int> bytes) {
    var decodedString = '';

    for (int i = 0; i < bytes.length - 1; i += 2) {
      int charCode = bytes[i] + (bytes[i + 1] << 8);
      decodedString += String.fromCharCode(charCode);
    }

    return decodedString;
  }

  void selectAndParseExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // String excelFilePath = result.files.single.path!;
      var bytes = result.files.single.bytes!;
      // File(excelFilePath).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      // Access the first sheet in the Excel file
      var sheet = excel.tables[excel.tables.keys.first];

      // Process the Excel data as needed
      for (var row in sheet!.rows) {
        for (var cell in row) {
          // Debug: cell value
        }
      }
    } else {
      // User canceled the file selection
      // File selection canceled.
    }
  }
}
