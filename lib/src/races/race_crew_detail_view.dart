import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
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
                return ListView.builder(
                  itemCount: size,
                  itemBuilder: (context, index) {
                    var no = index + 1;
                    var drummerPrefix = no == 1 ? "(drummer)" : "";
                    var helmPrefix = no == helmNo ? "(helm)" : "";
                    var reservePrefix = no > helmNo ? "(reserve)" : "";
                    if (crewAthletes.containsKey(index)) {
                      final athlete =
                          crewAthletes[index]!['athlete']! as Athlete;
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                                "$no $drummerPrefix$helmPrefix$reservePrefix ${(crewAthletes[index]!['athlete']! as Athlete).getDisplayDetail()}",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            subtitle: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: (8.0), vertical: 8.0),
                              child: Text(athlete.category ?? ""),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AthleteDetailView.routeName,
                                  arguments: {
                                    'mode': 'r',
                                    'allowEdit': false,
                                    'athlete': athlete
                                  }).then((value) {
                                setState(() {});
                              });
                            },
                          ),
                          const Divider(
                            height: 4,
                          )
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                                "$no $drummerPrefix$helmPrefix$reservePrefix",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                          ),
                          const Divider(
                            height: 4,
                          )
                        ],
                      );
                    }
                  },
                );
              }
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }
}
