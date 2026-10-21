import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/athlete/athlete.dart';

class CrewDetailView extends StatefulWidget {
  const CrewDetailView({super.key});
  static const routeName = '/crew_detail';

  @override
  State<CrewDetailView> createState() => _CrewDetailViewState();
}

class _CrewDetailViewState extends State<CrewDetailView> {
  late Crew crew;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  bool checkMix(
      Map<int, Map<String, dynamic>> crewAthletes, int size, int helmNo) {
    int countMale = 0;
    int countFemale = 0;
    crewAthletes.forEach((key, value) {
      var athlete = crewAthletes[key]!['athlete']! as Athlete;
      if (key != 0 && key < helmNo - 1) {
        if (athlete.gender == "Male") {
          countMale += 1;
        } else {
          countFemale += 1;
        }
      }
    });
    // Debug: male #: $countMale, female #: $countFemale
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Map<int, Athlete> crewAthletes;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    int size = args['size'];
    int crewId = args['crewId'];
    int helmNo = args['helmNo'];
    String title = args['title'];
    bool locked = args['locked'];
    // Optional, only used for the page header.
    final String? teamName = args['teamName'] as String?;
    final int? eventId = args['eventId'] as int?;

    return Scaffold(
      appBar: appBar(title: title),
      // appBar: appBarWithAction(
      //   () {
      //     Navigator.pushNamed(context, CrewDetailPrint.routeName, arguments: {
      //       'crewId': crewId,
      //       'size': size, // + reserves,
      //       'helmNo': helmNo,
      //       'title': title
      //     });
      //   },
      //   title: title,
      //   icon: Icons.print,
      // ),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: api.getCrewAthletesForCrew(crewId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                var crewAthletes = snapshot.data!;
                checkMix(crewAthletes, size, helmNo);
                // Debug: crew athletes data
                final filled = crewAthletes.keys.where((k) => k >= 0 && k < size).length;
                return ListView(
                  children: [
                    PageTitleBlock(
                      title: teamName ?? title,
                      children: [
                        if (teamName != null)
                          Text(title,
                              style: const TextStyle(color: pageBlue, fontSize: 16, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center),
                      ],
                    ),
                    ColoredPageHeader(
                      title: 'Crew ($filled/$size)',
                      subtitle: locked ? 'Crew entries are closed' : 'Tap an empty seat to add an athlete',
                      eventId: eventId,
                    ),
                    const Divider(height: 4),
                    for (var index = 0; index < size; index++)
                      _buildSeatRow(context, crewAthletes, index, helmNo, crewId, locked),
                    pageSectionGap,
                  ],
                );
              }
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }

  /// DRUMMER / HELM / RESERVE badge, same look as the boat check-in roster.
  Widget _roleBadge(String role) {
    final isReserve = role == 'reserve';
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isReserve ? Colors.grey.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isReserve ? Colors.grey : Colors.blue.shade200),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isReserve ? Colors.grey.shade800 : Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildSeatRow(BuildContext context, Map<int, Map<String, dynamic>> crewAthletes, int index,
      int helmNo, int crewId, bool locked) {
    final no = index + 1;
    final String role = no == 1
        ? 'drummer'
        : no == helmNo
            ? 'helm'
            : no > helmNo
                ? 'reserve'
                : 'paddler';
    final leading = SizedBox(
      width: 32,
      child: Text('$no', style: Theme.of(context).textTheme.displaySmall),
    );

    if (crewAthletes.containsKey(index)) {
      final athlete = crewAthletes[index]!['athlete']! as Athlete;
      return PageListItem(
        child: ListTile(
          leading: leading,
          title: Row(children: [
            if (role != 'paddler') _roleBadge(role),
            Expanded(
              child: Text(athlete.getDisplayName(), style: Theme.of(context).textTheme.displaySmall),
            ),
          ]),
          subtitle: Text("${athlete.category}"),
          trailing: IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: locked
                ? () {}
                : () {
                    api.deleteCrewAthlete(crewAthletes[index]!['id']).then((value) {
                      setState(() {});
                    });
                  },
          ),
        ),
      );
    }

    return PageListItem(
      child: ListTile(
        leading: leading,
        title: Row(children: [
          if (role != 'paddler') _roleBadge(role),
          Expanded(
            child: Text(
              'Empty seat',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ]),
        trailing: locked ? null : const Icon(Icons.person_add_alt_1, color: Colors.blue),
        onTap: locked
            ? () {}
            : () {
                Navigator.of(context).pushNamed(AthletePickerView.routeName, arguments: {
                  'crewId': crewId,
                  'no': index
                }).then((value) {
                  setState(() {});
                });
              },
      ),
    );
  }
}
