import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/races/race_crew_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class RaceDetailView extends StatefulWidget {
  const RaceDetailView({super.key});

  static const routeName = '/race_detail';

  @override
  State<RaceDetailView> createState() => ListViewState();
}

class ListViewState extends State<RaceDetailView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final disciplineId = args['disciplineId'];
    final discipline =
        disciplines.firstWhere((element) => element.id == disciplineId);
    return Scaffold(
      appBar: appBar(title: discipline.getDisplayName()),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: api.getTeamsForDisciplines(disciplineId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final teams = snapshot.data!;
              var competition = competitions.firstWhere(
                  (element) => element.id == discipline.eventId);
              var standardSize = 22;
              var smallSize = 12;
              var size = (discipline.boatGroup == "Standard"
                  ? standardSize
                  : smallSize);
              var reserves = (discipline.boatGroup == "Standard"
                  ? competition.standardReserves!
                  : competition.smallReserves!);
              var helmNo = discipline.boatGroup == "Standard"
                  ? standardSize
                  : smallSize;
              final canOpen = currentUser.accessLevel! > 0;
              return ListView(
                children: [
                  PageTitleBlock(
                    title: discipline.getDisplayName(),
                    children: [
                      Text('${competition.name ?? ''} ${competition.year ?? ''}'.trim(),
                          style: const TextStyle(color: pageBlue, fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ],
                  ),
                  ColoredPageHeader(
                    title: 'Teams (${teams.length})',
                    eventId: discipline.eventId,
                  ),
                  const Divider(height: 4),
                  for (final entry in teams)
                    PageListItem(
                      child: ListTile(
                          title: Row(
                            children: [
                              CountryBadge(country: entry.team?.club?.country),
                              Expanded(
                                child: Text(
                                  entry.team!.name!,
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            ],
                          ),
                          onTap: canOpen
                              ? () {
                                  Navigator.pushNamed(
                                      context, RaceCrewDetailView.routeName,
                                      arguments: {
                                        'crewId': entry.crew!.id,
                                        'size': size + reserves,
                                        'helmNo': helmNo,
                                        // 'title': discipline.getDisplayName()
                                        'title': entry.team!.name!,
                                        // Optional, header only.
                                        'discipline': discipline.getDisplayName(),
                                        'eventId': discipline.eventId,
                                      });
                                }
                              : () {},
                          trailing: canOpen ? const Icon(Icons.arrow_forward) : null),
                    ),
                  pageSectionGap,
                ],
              );
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }
}
