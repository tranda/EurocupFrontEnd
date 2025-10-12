
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/race/team.dart';
import 'discipline_list_view.dart';

class TeamListView extends StatefulWidget {
  const TeamListView({super.key});

  static const routeName = '/team_list';

  @override
  State<TeamListView> createState() => ListViewState();
}

class ListViewState extends State<TeamListView> {
  bool locked = false;
  late TextEditingController controller;
  late Future<List<Team>> dataFuture;
  List<Team> list = [];
  List<Club> clubs = [];

  String teamName = "";

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    // Allow team creation for club managers (0) and higher access levels (1+)
    locked = false;
    dataFuture = api.getTeams(currentUser.accessLevel!, activeOnly: true);

    // Load clubs if user has access level > 0 (referee, event manager, admin)
    if (currentUser.accessLevel! > 0) {
      api.getClubs(activeOnly: true).then((value) {
        setState(() {
          clubs = value;
        });
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithAction(
          locked
              ? () {}
              : () {
                  openDialog().then((value) {
                    if (value != null && value['name'] != null && value['name'].isNotEmpty) {
                      api.createTeam(value['name'], clubId: value['clubId']).then((v) {
                        setState(() {
                          teamName = value['name'];
                          dataFuture = api.getTeams(currentUser.accessLevel!, activeOnly: true);
                        });
                        // Debug: team created
                      }).catchError((error) {
                        // Error: team creation failed
                      });
                    }
                  }).catchError((error) {
                    // Error: dialog failed
                  });
                },
          title: "Team List",
          icon: Icons.add),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final teams = snapshot.data!;
              // Debug: teams list
              return ListView.builder(
                itemCount: teams.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      ListTile(
                          // tileColor: Colors.blue,
                          title: Row(
                            children: [
                              if (teams[index].club?.country != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    '${getCountryFlag(teams[index].club!.country)} ${getCountryCode(teams[index].club!.country)}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  teams[index].name!,
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                                context, DisciplineListView.routeName,
                                arguments: {
                                  'teamId': teams[index].id,
                                  'teamName': teams[index].name
                                }).then((value) {
                              setState(() {});
                            });
                          },
                          trailing: const Icon(Icons.arrow_forward)),
                      const Divider(
                        height: 4,
                      ),
                      const Divider(
                        height: smallSpace,
                      )
                    ],
                  );
                },
              );
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> openDialog() async {
    Club? selectedClub;

    return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Create Team"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: buildStandardInputDecoration("Enter team name"),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    // Show club selector for users with access level > 0
                    if (currentUser.accessLevel! > 0) ...[
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setDialogState) {
                          return DropdownButtonFormField<Club>(
                            initialValue: selectedClub,
                            decoration: buildStandardInputDecoration("Select Club"),
                            hint: const Text("Select Club"),
                            items: clubs.map((Club club) {
                              return DropdownMenuItem<Club>(
                                value: club,
                                child: Text(club.name ?? ''),
                              );
                            }).toList(),
                            onChanged: (Club? value) {
                              setDialogState(() {
                                selectedClub = value;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
                actions: <Widget>[
                  TextButton(onPressed: cancel, child: const Text("Cancel")),
                  TextButton(
                    onPressed: () => submit(selectedClub),
                    child: const Text("OK")
                  ),
                ],
              actionsAlignment: MainAxisAlignment.spaceBetween,
            ));
  }

  void cancel() {
    Navigator.of(context).pop();
    controller.clear();
  }

  void submit(Club? selectedClub) {
    Navigator.of(context).pop({
      'name': controller.text,
      'clubId': selectedClub?.id,
    });
    controller.clear();
  }
}
