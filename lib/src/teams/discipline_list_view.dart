import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/race/race.dart';

class DisciplineListView extends StatefulWidget {
  const DisciplineListView({super.key});

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
    try {
      // Check if any active competition has open entries
      var activeCompetitions = competitions.where((c) => c.isActive).toList();
      bool anyEntriesOpen = activeCompetitions.any((c) => c.isRaceEntriesOpen);

      // Check for null values before using them
      if (currentUser.accessLevel != null) {
        bool accessLevelRestriction = (currentUser.accessLevel! > 0) && (currentUser.accessLevel! < 3);
        bool dateRestriction = (currentUser.accessLevel! < 3) && !anyEntriesOpen;

        locked = accessLevelRestriction || dateRestriction;
      } else {
        locked = true; // Default to locked if access level is not set
      }
    } catch (e) {
      locked = true; // Default to locked on error
    }
  }

  Future<List<Race>> _getTeamDisciplinesForActiveEvents(int teamId) async {
    final activeEvents = competitions.where((c) => c.isActive).toList();
    List<Race> allRaces = [];
    for (var event in activeEvents) {
      final races = await api.getTeamDisciplines(teamId, event.id!);
      allRaces.addAll(races);
    }
    return allRaces;
  }

  Widget _competitionBadge(String competition) {
    final color = competitionBadgeColor(competition);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        competition,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade800,
        ),
      ),
    );
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
            future: _getTeamDisciplinesForActiveEvents(teamId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                final teamDisciplines = snapshot.data!;
                // Filter disciplines to only show those from active events
                final activeEventIds = competitions.where((c) => c.isActive).map((c) => c.id).toSet();
                final activeDisciplines = disciplines.where((d) => activeEventIds.contains(d.eventId)).toList();
                // Debug: discipline counts
                return ListView.builder(
                  itemCount: activeDisciplines.length,
                  itemBuilder: (BuildContext context, int index) {
                    final discipline = activeDisciplines[index];
                    final inactiveStatus =
                        discipline.status == "inactive" ? "(INACTIVE)" : "";
                    var competition = competitions.firstWhere(
                        (element) => element.id == discipline.eventId);
                    var eventName = '${competition.name!} ${competition.year}';
                    var eventColor = competitionColor.isNotEmpty && discipline.eventId! <= competitionColor.length 
                        ? competitionColor[discipline.eventId! - 1] 
                        : Colors.transparent;
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
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "${discipline.getDisplayName()} $inactiveStatus",
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                if (discipline.competition != null &&
                                    discipline.competition!.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  _competitionBadge(discipline.competition!),
                                ],
                              ],
                            ),
                            trailing: locked
                                // When locked, show check marks for registered disciplines
                                ? (registered
                                    ? Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green.shade200,
                                        size: 28,
                                      )
                                    : const Icon(
                                        Icons.radio_button_unchecked,
                                        color: Colors.grey,
                                        size: 28,
                                      ))
                                // When not locked, show interactive check mark icons
                                : GestureDetector(
                                    onTap: () {
                                      if (registered) {
                                        // Debug: unregister discipline
                                        api
                                            .unregisterCrew(
                                                teamId, discipline.id!)
                                            .then((value) {
                                          setState(() {});
                                        });
                                      } else {
                                        // Debug: register discipline
                                        api
                                            .registerCrew(
                                                teamId, discipline.id!)
                                            .then((value) {
                                          setState(() {});
                                        });
                                      }
                                      setState(() {});
                                    },
                                    child: registered
                                        ? Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.green.shade200,
                                            size: 28,
                                          )
                                        : const Icon(
                                            Icons.radio_button_unchecked,
                                            color: Colors.grey,
                                            size: 28,
                                          ),
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
