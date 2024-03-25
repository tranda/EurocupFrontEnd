import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/races/race_crew_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class RaceDetailView extends StatefulWidget {
  const RaceDetailView({Key? key}) : super(key: key);

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
              // print(_races);
              return ListView.builder(
                itemCount: teams.length,
                itemBuilder: (BuildContext context, int index) {
                  var competition = competitions.firstWhere(
                      (element) => element.id == discipline.eventId);
                  // var eventName = competition.name!;
                  // var eventColor =
                  //     competitionColor[discipline.eventId! - 1];
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
                  return Column(
                    children: [
                      ListTile(
                          // tileColor: Colors.blue,
                          title: Text(
                            teams[index].team!.name!,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          onTap: currentUser.accessLevel! > 0
                              ? () {
                                  Navigator.pushNamed(
                                      context, RaceCrewDetailView.routeName,
                                      arguments: {
                                        'crewId': teams[index].crew!.id,
                                        'size': size + reserves,
                                        'helmNo': helmNo,
                                        // 'title': discipline.getDisplayName()
                                        'title': teams[index].team!.name!
                                      });
                                }
                              : () {},
                          trailing: currentUser.accessLevel! > 0
                          ?const Icon(Icons.arrow_forward)
                          : null
                      ),
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
    );
  }
}
