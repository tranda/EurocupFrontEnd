import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:eurocup_frontend/src/crews/crew_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

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
    api.getCompetitions();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      // appBar: AppBar(
      //   title: const Text('Home Page'),
      // ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: bigSpace),
          ListTile(
            title: Text('Athletes',
                style: Theme.of(context).textTheme.headline1,
                textAlign: TextAlign.center),
            onTap: () {
              Navigator.restorablePushNamed(context, AthleteListView.routeName);
            },
          ),
          ListTile(
            title: Text('Crews',
                style: Theme.of(context).textTheme.headline1,
                textAlign: TextAlign.center),
            onTap: () {
              Navigator.restorablePushNamed(context, CrewListView.routeName);
            },
          ),
          ListTile(
            enabled: false,
            title: Text('Settings',
                style: Theme.of(context).textTheme.headline1,
                textAlign: TextAlign.center),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
