import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/crews/crew_detail_view.dart';
import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/race/race.dart';

class CrewListView extends StatefulWidget {
  const CrewListView({Key? key}) : super(key: key);

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
      body: FutureBuilder(
        future: api.getDisciplines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final _races = snapshot.data!;
            print(_races);
            return ListView.builder(
              itemCount: _races.length,
              itemBuilder: (BuildContext context, int index) {
                final race = _races[index];
                print(race);

                var eventName =
                    race.discipline!.eventId == 1 ? "Eurocup" : "Festival";
                var eventColor =
                    race.discipline!.eventId == 1 ? eurocupColor : festivalColor;
                return Column(
                  children: [
                    ListTile(
                      tileColor: eventColor,
                      title: Text(
                        race.discipline!.getDisplayName(),
                        style: Theme.of(context).textTheme.headline2,
                      ),
                      trailing: Text(
                        eventName,
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    ),
                    const Divider(
                      height: 4,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          List.generate(race.disciplineCrews!.length, (index) {
                        DisciplineCrew disciplineCrew =
                            race.disciplineCrews![index];
                        var size = (race.discipline!.boatGroup == "Standard"
                            ? 24
                            : 13);
                        var helmNo = (race.discipline!.boatGroup == "Standard"
                            ? 22
                            : 12);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: horizontalPadding),
                                  child: Text(
                                    disciplineCrew.team!.name!,
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                      CrewDetailView.routeName,
                                      arguments: {
                                        'crewId': disciplineCrew.crew!.id,
                                        'size': size,
                                        'helmNo': helmNo,
                                        'title':
                                            race.discipline!.getDisplayName()
                                      });
                                },
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
    );
  }
}
