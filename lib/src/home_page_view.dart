import 'package:eurocup_frontend/src/athletes/athlete_list_view.dart';
import 'package:flutter/material.dart';

import 'model/user.dart';
import 'common.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const routeName = '/home_page';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User user = currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(
          onPressed: () {
            Navigator.restorablePushNamed(context, AthleteListView.routeName);
          },
          child: const Text('Athletes'),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Crews'),
        ),
      ]),
    );
  }
}
