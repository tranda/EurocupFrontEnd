import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/crews/crew_detail_view.dart';
import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/race/race.dart';
import 'discipline_list_view.dart';

class TeamListView extends StatefulWidget {
  const TeamListView({Key? key}) : super(key: key);

  static const routeName = '/team_list';

  @override
  State<TeamListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<TeamListView> {
  @override
  void initState() {
    super.initState();
    // setState(() {
    //   getAthletes();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Team List'),
      body: Container(
        // decoration: const BoxDecoration(
        //     image: DecorationImage(
        //         image: AssetImage('assets/images/bck.jpg'), fit: BoxFit.cover)),
        child: FutureBuilder(
          future: api.getTeamsAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final teams = snapshot.data!;
              // print(_races);
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
                            // currentAthlete = athlete;
                            Navigator.pushNamed(
                                context, DisciplineListView.routeName,
                                arguments: {'teamId': teams[index].id, 'teamName': teams[index].name}).then((value) {
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
}
