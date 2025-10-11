import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/crews/crew_detail_view.dart';
import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class CrewListView extends StatefulWidget {
  const CrewListView({super.key});

  static const routeName = '/crew_list';

  @override
  State<CrewListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<CrewListView> {
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
      appBar: appBar(title: 'Crew List'),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: api.getDisciplinesCombined(EVENTID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final races = snapshot.data!;
              // Debug: races list
              return ListView.builder(
                itemCount: races.length,
                itemBuilder: (BuildContext context, int index) {
                  final race = races[index];
                  // Debug: race data
                  var competition = competitions.firstWhere(
                      (element) => element.id == race.discipline?.eventId);
                  var eventName = '${competition.name!} ${competition.year}';
                  var eventColor =
                      competitionColor[race.discipline!.eventId! - 1];
                  var standardSize = 22;
                  var smallSize = 12;
                  var locked = !competition.isCrewEntriesOpen;

                  return Column(
                    children: [
                      Container(
                        color: eventColor,
                        child: ListTile(
                          leading: Text(
                            eventName,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          title: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              race.discipline!.getDisplayName(),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 4,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(race.disciplineCrews!.length,
                            (index) {
                          DisciplineCrew disciplineCrew =
                              race.disciplineCrews![index];
                          var size = (race.discipline!.boatGroup == "Standard"
                              ? standardSize
                              : smallSize);
                          var reserves =
                              (race.discipline!.boatGroup == "Standard"
                                  ? competition.standardReserves!
                                  : competition.smallReserves!);
                          var helmNo = race.discipline!.boatGroup == "Standard"
                              ? standardSize
                              : smallSize;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                  title: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: verticalPadding),
                                    child: Text(
                                      disciplineCrew.team!.name!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        CrewDetailView.routeName,
                                        arguments: {
                                          'crewId': disciplineCrew.crew!.id,
                                          'size': size + reserves,
                                          'helmNo': helmNo,
                                          'title':
                                              race.discipline!.getDisplayName(),
                                          'locked': locked
                                        }).then((value) {
                                      setState(() {});
                                    });
                                  },
                                  leading: Text(
                                    "${disciplineCrew.crew!.capacity}/$size+$reserves",
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward)),
                              const Divider()
                            ],
                          );
                        }),
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
