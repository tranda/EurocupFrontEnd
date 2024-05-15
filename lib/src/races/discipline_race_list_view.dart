import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/races/race_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class DisciplineRaceListView extends StatefulWidget {
  const DisciplineRaceListView({Key? key}) : super(key: key);

  static const routeName = '/disciplineRace_list';

  @override
  State<DisciplineRaceListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<DisciplineRaceListView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Disciplines'),
      body: Container(
        // decoration: const BoxDecoration(
        //     image: DecorationImage(
        //         image: AssetImage('assets/images/bck.jpg'), fit: BoxFit.cover)),
        child: FutureBuilder(
          future: api.getDisciplinesAll(eventId: EVENTID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final allDisciplines = snapshot.data!;
              print('# of Disciplines: ${allDisciplines.length}');
              return ListView.builder(
                itemCount: allDisciplines.length,
                itemBuilder: (BuildContext context, int index) {
                  final discipline = allDisciplines[index];
                  final active = discipline.status == "active";
                  final inactiveStatus =
                      discipline.status == "inactive" ? "(INACTIVE)" : "";
                  var competition = competitions.firstWhere(
                      (element) => element.id == discipline.eventId);
                  var eventName = '${competition.name!} ${competition.year}';
                  var eventColor = competitionColor[discipline.eventId! - 1];

                  return Column(
                    children: [
                      Visibility(
                        visible: active,
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, RaceDetailView.routeName,
                                    arguments: {'disciplineId': discipline.id});
                              },
                              tileColor: eventColor,
                              leading: Text(eventName,
                              style: Theme.of(context).textTheme.labelSmall,),
                              title: Text(
                                "${discipline.getDisplayName()} $inactiveStatus (${discipline.teamsCount})",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              trailing: const Icon(Icons.arrow_forward),
                            ),
                            const Divider(
                              height: 4,
                            ),
                            const Divider(
                              height: smallSpace,
                            )
                          ],
                        ),
                      ),
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
