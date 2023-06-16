import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class DisciplineListView extends StatefulWidget {
  const DisciplineListView({Key? key}) : super(key: key);

  static const routeName = '/discipline_list';

  @override
  State<DisciplineListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<DisciplineListView> {
  @override
  void initState() {
    super.initState();
    // setState(() {
    //   getAthletes();
    // });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final teamId = args['teamId'];
    final teamName = args['teamName'];
    return Scaffold(
      appBar: appBar(title: teamName),
      body: Container(
        // decoration: const BoxDecoration(
        //     image: DecorationImage(
        //         image: AssetImage('assets/images/bck.jpg'), fit: BoxFit.cover)),
        child: FutureBuilder(
          future: api.getTeamDisciplines(teamId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final teamDisciplines = snapshot.data!;
              print('# of Disciplines: ${disciplines.length}');
              print('# of registered Disciplines: ${teamDisciplines.length}');
              return ListView.builder(
                itemCount: disciplines.length,
                itemBuilder: (BuildContext context, int index) {
                  final discipline = disciplines[index];
                  final inactiveStatus =
                      discipline.status == "inactive" ? "(INACTIVE)" : "";
                  var competition = competitions.firstWhere(
                      (element) => element.id == discipline.eventId);
                  var eventName = competition.name!;
                  var eventColor = competitionColor[discipline.eventId! - 1];
                  var registered = false;
                  for (var element in teamDisciplines) {
                    if (element.discipline!.id == discipline.id) {
                      registered = true;
                    }
                  }
                  return Column(
                    children: [
                      ListTile(
                          tileColor: eventColor,
                          leading: Text(eventName),
                          title: Text(
                            discipline.getDisplayName() + " ${inactiveStatus}",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: Visibility(
                            visible: true, // discipline.status == "active",
                            child: Checkbox(
                                value: registered,
                                onChanged: (value) {
                                  if (value != null) {
                                    if (value) {
                                      print('register for ');
                                      api
                                          .registerCrew(teamId, discipline.id!)
                                          .then((value) {
                                        setState(() {});
                                      });
                                    } else {
                                      print('unregister for ');
                                      api
                                          .unregisterCrew(
                                              teamId, discipline.id!)
                                          .then((value) {
                                        setState(() {});
                                      });
                                    }
                                    setState(() {});
                                  }
                                }),
                          )),
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
