
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

  String teamName = "";

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    locked = currentUser.accessLevel != 0;
    dataFuture = api.getTeams(currentUser.accessLevel!, activeOnly: true);
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
                    if (value != null && value.isNotEmpty) {
                      api.createTeam(value).then((v) {
                        setState(() {
                          teamName = value;
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
                          title: Text(
                            teams[index].name!,
                            style: Theme.of(context).textTheme.displaySmall,
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

  Future<String?> openDialog() async {
    return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Team Name:"),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: buildStandardInputDecoration("Enter team name"),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                actions: <Widget>[
                  TextButton(onPressed: cancel, child: const Text("Cancel")),
                  TextButton(onPressed: submit, child: const Text("OK")),
                ],
              actionsAlignment: MainAxisAlignment.spaceBetween,
            ));
  }

  void cancel() {
    Navigator.of(context).pop();
    controller.clear();
  }

  void submit() {
    Navigator.of(context).pop(controller.text);
    controller.clear();
  }
}
