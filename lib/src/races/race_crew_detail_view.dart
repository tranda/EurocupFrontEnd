import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../athletes/athlete_detail_view.dart';
import '../model/athlete/athlete.dart';


class RaceCrewDetailView extends StatefulWidget {
  const RaceCrewDetailView({super.key});
  static const routeName = '/race_crew_detail';

  @override
  State<RaceCrewDetailView> createState() => _RaceCrewDetailViewState();
}

class _RaceCrewDetailViewState extends State<RaceCrewDetailView> {
  late Crew crew;
  List<Athlete> listAthlete = [];

  @override
  void initState() {
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
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    int size = args['size'];
    int crewId = args['crewId'];
    int helmNo = args['helmNo'];
    String title = args['title'];
    // Optional, only used for the page header.
    final String? disciplineName = args['discipline'] as String?;
    final int? eventId = args['eventId'] as int?;

    return Scaffold(
      appBar: appBar(title: title),
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
                listAthlete = crewAthletes.values
                    .map<Athlete>((innerMap) => innerMap['athlete'] as Athlete)
                    .toList();
                // Debug: check mix validation
                final filled = crewAthletes.keys.where((k) => k >= 0 && k < size).length;
                return ListView(
                  children: [
                    PageTitleBlock(
                      title: title,
                      children: [
                        if (disciplineName != null)
                          Text(disciplineName,
                              style: const TextStyle(color: pageBlue, fontSize: 16, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center),
                      ],
                    ),
                    ColoredPageHeader(title: 'Crew ($filled/$size)', eventId: eventId),
                    const Divider(height: 4),
                    for (var index = 0; index < size; index++)
                      _buildSeatRow(context, crewAthletes, index, helmNo),
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

  Widget _buildSeatRow(
      BuildContext context, Map<int, Map<String, dynamic>> crewAthletes, int index, int helmNo) {
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
              child: Text(athlete.getDisplayDetail(), style: Theme.of(context).textTheme.displaySmall),
            ),
          ]),
          subtitle: Text(athlete.category ?? ""),
          onTap: () {
            Navigator.pushNamed(context, AthleteDetailView.routeName, arguments: {
              'mode': 'r',
              'allowEdit': false,
              'athlete': athlete
            }).then((value) {
              setState(() {});
            });
          },
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
      ),
    );
  }
}
