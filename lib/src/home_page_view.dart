import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/login_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import 'model/user.dart';
import 'common.dart';
import 'api_helper.dart' as api;
import 'teams/team_list_view.dart';

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
    api.getCompetitions();
    api.getDisciplinesAll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      // appBar: AppBar(
      //   title: const Text('Home Page'),
      // ),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/naslovna-bck.jpg'),
                fit: BoxFit.cover)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // const SizedBox(height: 400),
            ListTile(
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
            ListTile(
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
            const SizedBox(
              height: bigSpace,
            ),
            ListTile(
              enabled: (currentUser.accessLevel! >= 2),
              title: Text('Settings',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.left),
              onTap: () {
                Navigator.pushNamed(context, TeamListView.routeName);
              },
              leading: const Icon(
                Icons.play_arrow,
                color: Color.fromARGB(255, 0, 80, 150),
              ),
            ),
            ListTile(
              enabled: true,
              title: Text('Log out',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.left),
              onTap: () {
                api.sendLogoutRequest().then((value) {
                  Navigator.pop(context);
                  clearToken();
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
