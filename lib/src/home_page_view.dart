
import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/races/discipline_race_list_view.dart';
import 'package:eurocup_frontend/src/teams/team_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'administration/administration_view.dart';
import 'model/user.dart';
import 'common.dart';
import 'api_helper.dart' as api;

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
    competitions = [];
    disciplines = [];
    api.getCompetitions();
    api.getDisciplinesAll(eventId: EVENTID);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      body: Container(
        decoration: naslovnaDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: (currentUser.accessLevel! == 0),
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
              visible: (currentUser.accessLevel! == 0),
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
              visible: (currentUser.accessLevel! == 0),
              child: ListTile(
                title: Text('Teams',
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
              visible: (currentUser.accessLevel! == 0),
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
              height: bigSpace,
            ),
            Visibility(
              visible: (currentUser.accessLevel! >= 1),
              child: ListTile(
                enabled: true,
                title: Text('Races Overview',
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
              visible: (currentUser.accessLevel! >= 2),
              child: ListTile(
                enabled: (currentUser.accessLevel! >= 2),
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
                lastUser = null;
                lastPassword = null;
                api.sendLogoutRequest().then((value) {
                  Navigator.pop(context);
                  // ClearToken();
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
      print('Finished parsing csv');

      var success = await api.sendAthletes(athletes);
      print('Finished sending athletes');
      if (success) {
        showInfoDialog(context, 'Message', 'Athletes imported', () {});
      } else {
        showInfoDialog(context, 'Server error', 'Please try again later.', () {});
      }
    } else {
      // User canceled the file selection
      print('File selection canceled.');
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
          print(cell?.value);
        }
      }
    } else {
      // User canceled the file selection
      print('File selection canceled.');
    }
  }
}
