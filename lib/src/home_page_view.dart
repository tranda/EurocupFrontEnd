import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/races/discipline_race_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
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
    api.getDisciplinesAll();
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
}
