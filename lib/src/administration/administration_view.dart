import 'package:eurocup_frontend/src/users/users_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import '../clubs/club_list_view.dart';
import '../common.dart';
import '../model/user.dart';
import '../teams/team_list_view.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({super.key});
  static const routeName = '/administration_page';

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  final User user = currentUser;
  @override
  void initState() {
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
              visible: currentUser.accessLevel! >= 3,
              child: ListTile(
                title: Text('Users',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, UserListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: currentUser.accessLevel! >= 3,
              child: ListTile(
                title: Text('Events',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {},
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: currentUser.accessLevel! >= 2,
              child: ListTile(
                title: Text('Clubs',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, ClubListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: currentUser.accessLevel! >= 3,
              child: ListTile(
                title: Text('Teams',
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
