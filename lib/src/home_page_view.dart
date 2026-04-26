
import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/races/discipline_race_list_view.dart';
import 'package:eurocup_frontend/src/races/competition_selector_view.dart';
import 'package:eurocup_frontend/src/teams/team_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
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

    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      body: Container(
        decoration: naslovnaDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: (currentUser.accessLevel ?? -1) == 0,
              child: ListTile(
                title: Text('List of Athletes',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, AthleteListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: false,// (currentUser.accessLevel! == 0),
              child: ListTile(
                title: Text('Import Athletes',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.left),
                onTap: () {
                  selectAndParseCSV();
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? -1) == 0,
              child: ListTile(
                title: Text('Teams/Races',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, TeamListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? -1) == 0,
              child: ListTile(
                title: Text('Crew Members',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, CrewListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            const SizedBox(
              height: smallSpace,
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? -1) >= 0,
              child: ListTile(
                enabled: true,
                title: Text('Current Entries',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(
                      context, DisciplineRaceListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? -1) >= 0,
              child: ListTile(
                enabled: true,
                title: Text('Race Results',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(
                      context, CompetitionSelectorView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? -1) >= 2,
              child: ListTile(
                enabled: (currentUser.accessLevel ?? -1) >= 2,
                title: Text('Administration',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, AdministrationPage.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            ListTile(
              enabled: true,
              title: Text('Log out',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.left),
              onTap: () {
                // Call logout API first while token is still available
                api.sendLogoutRequest().then((value) {
                  // Clear local authentication data after API call
                  lastUser = null;
                  lastPassword = null;
                  currentUser = User(); // Reset user

                  // Navigate to login page and clear all previous routes
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                }).catchError((error) {
                  // Even if logout request fails, clear local data and navigate to login
                  lastUser = null;
                  lastPassword = null;
                  clearToken();
                  currentUser = User(); // Reset user

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                });
              },
              leading: const Icon(
                Icons.play_arrow,
                color: Color.fromARGB(255, 0, 80, 150),
              ),
            ),
            const SizedBox(
              height: bigSpace,
            ),
          ],
        ),
      ),
    );
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
