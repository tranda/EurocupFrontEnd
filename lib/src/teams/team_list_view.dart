
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
  Club? _selectedClub;

  String teamName = "";

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    // Allow team creation for club managers (0) and higher access levels (1+)
    locked = false;
    // This is the team management page (also reached via Club -> Teams), so it
    // loads inactive teams too, allowing them to be reactivated. Other views
    // pass activeOnly: true to hide inactive teams and reduce noise.
    dataFuture = _loadTeams();

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

  /// Loads teams for the management page, including inactive ones so they can
  /// be reactivated here.
  Future<List<Team>> _loadTeams() {
    return api.getTeams(currentUser.accessLevel!, activeOnly: false);
  }

  /// Admins may manage any team; club managers may manage their own club's teams.
  bool _canManage(Team team) {
    final level = currentUser.accessLevel ?? 0;
    if (level >= 2) return true;
    return currentUser.clubId != null && currentUser.clubId == team.clubId;
  }

  Future<void> _toggleActive(BuildContext context, Team team, bool active) async {
    try {
      await api.setTeamActive(team.id!, active);
      setState(() {
        dataFuture = _loadTeams();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(active
                ? 'Team "${team.name}" reactivated'
                : 'Team "${team.name}" marked inactive'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update team status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeactivate(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Mark Team Inactive'),
          content: Text(
            'Mark "${team.name}" as inactive?\n\n'
            'It will be hidden from team listings and registration, but kept '
            'for historical records. You can reactivate it here at any time.',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _toggleActive(context, team, false);
              },
              child: const Text('Mark Inactive'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final int? filterClubId = routeArgs is Map ? routeArgs['clubId'] as int? : null;
    final String pageTitle = (routeArgs is Map && routeArgs['title'] is String)
        ? routeArgs['title'] as String
        : "Team List";

    return Scaffold(
      appBar: appBarWithAction(
          locked
              ? () {}
              : () {
                  openDialog(forcedClubId: filterClubId).then((value) {
                    if (value != null && value['name'] != null && value['name'].isNotEmpty) {
                      api.createTeam(value['name'], clubId: value['clubId']).then((v) {
                        setState(() {
                          teamName = value['name'];
                          dataFuture = _loadTeams();
                        });
                      }).catchError((error) {
                        // Error: team creation failed
                      });
                    }
                  }).catchError((error) {
                    // Error: dialog failed
                  });
                },
          title: pageTitle,
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
              final teams = filterClubId != null
                  ? snapshot.data!.where((t) => t.clubId == filterClubId).toList()
                  : snapshot.data!;
              // Sort teams: active teams from active clubs first, inactive last.
              teams.sort((a, b) {
                final aActive = (a.active ?? true) && (a.club?.active ?? false);
                final bActive = (b.active ?? true) && (b.club?.active ?? false);
                if (aActive == bActive) return 0;
                return aActive ? -1 : 1;
              });
              // Debug: teams list
              return ListView.builder(
                itemCount: teams.length,
                itemBuilder: (BuildContext context, int index) {
                  final team = teams[index];
                  final isTeamInactive = team.active == false;
                  final isInactiveClub = team.club?.active == false;
                  // Inactive teams/clubs are not clickable for non-admins;
                  // admins (accessLevel >= 3) can still open and modify.
                  final isAdmin = (currentUser.accessLevel ?? 0) >= 3;
                  final blockOpen =
                      (isTeamInactive || isInactiveClub) && !isAdmin;
                  return Opacity(
                    opacity: (isInactiveClub || isTeamInactive) ? 0.5 : 1.0,
                    child: Column(
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
                          subtitle: (teams[index].club?.name != null && teams[index].club!.name!.isNotEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    teams[index].club!.name!,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: blockOpen
                              ? null
                              : () {
                            Navigator.pushNamed(
                                context, DisciplineListView.routeName,
                                arguments: {
                                  'teamId': teams[index].id,
                                  'teamName': teams[index].name,
                                  // A team is "inactive" for registration if the
                                  // team itself or its club is marked inactive.
                                  'teamInactive': isTeamInactive || isInactiveClub,
                                }).then((value) {
                              setState(() {});
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_canManage(team))
                                IconButton(
                                  icon: Icon(
                                    isTeamInactive ? Icons.visibility_off : Icons.visibility,
                                    color: isTeamInactive ? Colors.orange : Colors.green,
                                  ),
                                  tooltip: isTeamInactive
                                      ? 'Inactive — tap to reactivate'
                                      : 'Active — tap to mark inactive',
                                  onPressed: () {
                                    if (isTeamInactive) {
                                      _toggleActive(context, team, true);
                                    } else {
                                      _confirmDeactivate(context, team);
                                    }
                                  },
                                ),
                              if (currentUser.accessLevel != null && currentUser.accessLevel! >= 2) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditDialog(context, teams[index]);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showDeleteConfirmation(context, teams[index]);
                                  },
                                ),
                              ],
                              const Icon(Icons.arrow_forward),
                            ],
                          )),
                      const Divider(
                        height: 4,
                      ),
                      const Divider(
                        height: smallSpace,
                      )
                    ],
                  ),
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

  Future<Map<String, dynamic>?> openDialog({int? forcedClubId}) async {
    _selectedClub = null;
    final bool showClubPicker = forcedClubId == null && currentUser.accessLevel! > 0;

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
                    // Show club selector only when the club isn't already scoped by the route.
                    if (showClubPicker) ...[
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setDialogState) {
                          return DropdownButtonFormField<Club>(
                            initialValue: _selectedClub,
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
                                _selectedClub = value;
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
                    onPressed: () => submit(forcedClubId ?? _selectedClub?.id),
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

  void submit(int? clubId) {
    Navigator.of(context).pop({
      'name': controller.text,
      'clubId': clubId,
    });
    controller.clear();
  }

  void _showEditDialog(BuildContext context, Team team) {
    final editController = TextEditingController(text: team.name ?? '');
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename Team'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: buildStandardInputDecoration('Team name'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = editController.text.trim();
                if (newName.isEmpty || newName == team.name) {
                  Navigator.pop(dialogContext);
                  return;
                }
                Navigator.pop(dialogContext);
                try {
                  await api.updateTeam(team.id!, newName);
                  setState(() {
                    dataFuture = _loadTeams();
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Team renamed to "$newName"')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to rename team: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Team'),
          content: Text(
            'Are you sure you want to delete "${team.name}"?\n\nThis action cannot be undone.',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await api.deleteTeam(team.id!);
                  // Refresh the list
                  setState(() {
                    dataFuture = _loadTeams();
                  });
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Team "${team.name}" deleted successfully')),
                    );
                  }
                } catch (e) {
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete team: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
