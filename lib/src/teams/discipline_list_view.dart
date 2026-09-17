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

  int? _teamId;
  late Future<List<Race>> _disciplinesFuture;
  final Set<int> _registeredIds = {};
  final Set<int> _loadingIds = {};

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the disciplines future ONCE so that later setState() calls
    // (e.g. toggling a single row) don't recreate it and force a full reload.
    if (_teamId == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      _teamId = args['teamId'];
      // Inactive teams (or teams of an inactive club) cannot apply for races.
      // Admins (accessLevel >= 3) can still open and modify.
      final bool teamInactive = args['teamInactive'] == true;
      final bool isAdmin = (currentUser.accessLevel ?? 0) >= 3;
      if (teamInactive && !isAdmin) {
        locked = true;
      }
      _disciplinesFuture = _loadDisciplines(_teamId!);
    }
  }

  Future<List<Race>> _loadDisciplines(int teamId) async {
    final races = await _getTeamDisciplinesForActiveEvents(teamId);
    _registeredIds
      ..clear()
      ..addAll(races
          .where((r) => r.discipline?.id != null)
          .map((r) => r.discipline!.id!));
    return races;
  }

  Future<void> _toggleDiscipline(int teamId, int id) async {
    if (_loadingIds.contains(id)) return;
    final wasRegistered = _registeredIds.contains(id);
    // Show a small spinner on this row only.
    setState(() => _loadingIds.add(id));
    try {
      if (wasRegistered) {
        await api.unregisterCrew(teamId, id);
      } else {
        await api.registerCrew(teamId, id);
      }
      // Update just this row's state locally — no full re-fetch.
      setState(() {
        if (wasRegistered) {
          _registeredIds.remove(id);
        } else {
          _registeredIds.add(id);
        }
        _loadingIds.remove(id);
      });
    } catch (e) {
      setState(() => _loadingIds.remove(id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update. Please try again.')),
        );
      }
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
            future: _disciplinesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
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
                    final registered = _registeredIds.contains(discipline.id);
                    final isLoading = _loadingIds.contains(discipline.id);
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
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                                  ),
                                ),
                                if (discipline.competition != null &&
                                    discipline.competition!.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  _competitionBadge(discipline.competition!),
                                ],
                              ],
                            ),
                            trailing: SizedBox(
                              width: 28,
                              height: 28,
                              child: isLoading
                                  // Only this row shows a loader while its
                                  // register/unregister request is in flight.
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : locked
                                      // When locked, show status only.
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
                                      // When not locked, tapping toggles it.
                                      : GestureDetector(
                                          onTap: () => _toggleDiscipline(
                                              teamId, discipline.id!),
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
