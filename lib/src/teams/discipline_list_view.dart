import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class DisciplineListView extends StatefulWidget {
  const DisciplineListView({Key? key}) : super(key: key);

  static const routeName = '/discipline_list';

  @override
  State<DisciplineListView> createState() => _DisciplineListViewState();
}

class _DisciplineListViewState extends State<DisciplineListView> {
  bool locked = false;
  List<int> registeredDisciplines = [];
  bool changes = false;

  @override
  void initState() {
    super.initState();
    // setState(() {
    //   getAthletes();
    // });
    locked = (currentUser.accessLevel! > 0) && (currentUser.accessLevel! < 3);
  }

  Future<bool> _onWillPop() async {
    return (!changes
            ? true
            : await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: null,
                  title: Text(
                    "You will loose Your changes!",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('OK'),
                    ),
                  ],
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                ),
              )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final teamId = args['teamId'];
    final teamName = args['teamName'];
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: appBar(title: teamName),
        // appBar: appBarWithAction(
        //     locked
        //         ? () {}
        //         : () {
        //             if (changes) {
        //               openDialog().then((value) {
        //                 if (value == true) {
        //                   api
        //                       .registerCrews(teamId, registeredDisciplines)
        //                       .then((v) {
        //                     Navigator.of(context).pop();
        //                   }).catchError((error) {
        //                     print('Error creating team: $error');
        //                   });
        //                 } else {}
        //               }).catchError((error) {
        //                 print('Error opening dialog: $error');
        //               });
        //             }
        //           },
        //     title: teamName,
        //     icon: Icons.save),
        body: Container(
          // decoration: const BoxDecoration(
          //     image: DecorationImage(
          //         image: AssetImage('assets/images/bck.jpg'), fit: BoxFit.cover)),
          child: FutureBuilder(
            future: api.getTeamDisciplines(teamId, EVENTID),
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
                    var eventName = '${competition.name!} ${competition.year}';
                    var eventColor = competitionColor[discipline.eventId! - 1];
                    var registered = false;
                    for (var element in teamDisciplines) {
                      if (element.discipline!.id == discipline.id) {
                        registered = true;
                        registeredDisciplines.add(discipline.id!);
                      }
                    }
                    return Column(
                      children: [
                        ListTile(
                            tileColor: eventColor,
                            leading: Text(eventName, 
                            style: Theme.of(context).textTheme.labelSmall,
                            ),
                            title: Text(
                              "${discipline.getDisplayName()} $inactiveStatus",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            trailing: Visibility(
                              visible: true, // discipline.status == "active",
                              child:
                                  Checkbox(
                                      // value: registeredDisciplines.contains(
                                          // discipline.id!), // registered,
                                          value:  registered,

                                      onChanged:
                                          // (value) {
                                          //   if (value != null && !locked) {
                                          //     if (value) {
                                          //       registeredDisciplines
                                          //           .add(discipline.id!);
                                          //       changes = true;
                                          //     } else {
                                          //       registeredDisciplines
                                          //           .remove(discipline.id!);
                                          //       changes = true;
                                          //     }
                                          //     setter(() {
                                          //       print(registeredDisciplines);
                                          //       teamDisciplines.removeWhere(
                                          //           (element) =>
                                          //               element.discipline!.id ==
                                          //               discipline.id!);
                                          //     });
                                          //   }
                                          // }
                                          (value) {
                                        if (value != null) {
                                          if (value) {
                                            print('register for ${discipline.id}');
                                            api
                                                .registerCrew(
                                                    teamId, discipline.id!)
                                                .then((value) {
                                              setState(() {});
                                            });
                                          } else {
                                            print('unregister for ${discipline.id}');
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
      ),
    );
  }

  Future<bool?> openDialog() async {
    return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              content: null,
              title: Text(
                "Save Your changes?",
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
    Navigator.of(context).pop(false);
  }

  void submit() {
    Navigator.of(context).pop(true);
  }
}
