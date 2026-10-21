import 'package:eurocup_frontend/src/users/users_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';

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
    final level = currentUser.accessLevel ?? 0;
    void go(String route) => Navigator.pushNamed(context, route);

    return Scaffold(
      appBar: appBar(title: 'Administration'),
      body: Container(
        decoration: bckDecoration(),
        child: ListView(
          children: [
            const MenuBanner(),
            MenuSection(title: 'Events', rows: [
              if (level >= 2)
                MenuRow(icon: Icons.event, title: 'Events', onTap: () => go(EventListView.routeName)),
              if (level >= 2)
                MenuRow(
                    icon: Icons.category,
                    title: 'Disciplines',
                    onTap: () => go(AdminDisciplineListView.routeName)),
              if (level >= 1)
                MenuRow(
                    icon: Icons.event_available,
                    title: 'Race Schedule Builder',
                    onTap: () => go(ScheduleEventPicker.routeName)),
            ]),
            MenuSection(title: 'Clubs and people', rows: [
              if (level >= 2)
                MenuRow(icon: Icons.shield, title: 'Clubs', onTap: () => go(ClubListView.routeName)),
              if (level >= 2)
                MenuRow(icon: Icons.flag, title: 'Teams', onTap: () => go(TeamListView.routeName)),
              if (level >= 3)
                MenuRow(icon: Icons.person, title: 'Users', onTap: () => go(UserListView.routeName)),
            ]),
            MenuSection(title: 'System', rows: [
              if (level >= 3)
                MenuRow(
                    icon: Icons.backup,
                    title: 'Database Backups',
                    onTap: () => go(DatabaseBackupView.routeName)),
              if (level >= 3)
                MenuRow(icon: Icons.vpn_key, title: 'API Keys', onTap: () => go(ApiKeysListView.routeName)),
            ]),
          ],
        ),
      ),
    );
  }
}
