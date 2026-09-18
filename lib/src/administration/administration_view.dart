import 'package:eurocup_frontend/src/users/users_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import '../clubs/club_adel_list_view.dart';
import '../clubs/club_list_view.dart';
import '../common.dart';
import '../model/user.dart';
import '../teams/team_list_view.dart';
import 'database_backup_view.dart';
import 'api_keys_list_view.dart';
import 'event_list_view.dart';
import 'discipline_list_view.dart';
import 'schedule/schedule_event_picker.dart';

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
              visible: (currentUser.accessLevel ?? 0) >= 3,
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
              visible: (currentUser.accessLevel ?? 0) >= 3,
              child: ListTile(
                title: Text('Events',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, EventListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? 0) >= 3,
              child: ListTile(
                title: Text('Disciplines',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, AdminDisciplineListView.routeName);
                },
                leading: const Icon(
                  Icons.play_arrow,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? 0) >= 3,
              child: ListTile(
                title: Text('Race Schedule Builder',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, ScheduleEventPicker.routeName);
                },
                leading: const Icon(
                  Icons.event_available,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? 0) >= 2,
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
              visible: (currentUser.accessLevel ?? 0) >= 3,
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
            Visibility(
              visible: (currentUser.accessLevel ?? 0) >= 3,
              child: ListTile(
                title: Text('Database Backups',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, DatabaseBackupView.routeName);
                },
                leading: const Icon(
                  Icons.backup,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: (currentUser.accessLevel ?? 0) >= 3,
              child: ListTile(
                title: Text('API Keys',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, ApiKeysListView.routeName);
                },
                leading: const Icon(
                  Icons.vpn_key,
                  color: Color.fromARGB(255, 0, 80, 150),
                ),
              ),
            ),
            Visibility(
              visible: false, // (currentUser.accessLevel ?? 0) >= 2,
              child: ListTile(
                title: Text('Clubs req ADEL',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.left),
                onTap: () {
                  Navigator.pushNamed(context, ClubAdelListView.routeName);
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
