import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../clubs/club_details_view.dart';
import '../model/athlete/athlete.dart';
import 'crew_detail_print.dart';

class CrewDetailView extends StatefulWidget {
  const CrewDetailView({Key? key}) : super(key: key);
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
    print('male #: $countMale, female #: $countFemale');
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
                // print (crewAthletes);
                return ListView.builder(
                  itemCount: size,
                  itemBuilder: (context, index) {
                    var no = index + 1;
                    var drummerPrefix = no == 1 ? "(drummer)" : "";
                    var helmPrefix = no == helmNo ? "(helm)" : "";
                    var reservePrefix = no > helmNo ? "(reserve)" : "";
                    if (crewAthletes.containsKey(index)) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                                "$no $drummerPrefix$helmPrefix$reservePrefix ${(crewAthletes[index]!['athlete']! as Athlete).getDisplayName()}",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            subtitle: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: (8.0), vertical: 8.0),
                              child: Text("${(crewAthletes[index]!['athlete']! as Athlete).category}"),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: locked
                                  ? () {}
                                  : () {
                                      api
                                          .deleteCrewAthlete(
                                              crewAthletes[index]!['id'])
                                          .then((value) {
                                        setState(() {});
                                      });
                                    },
                            ),
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
                            onTap: locked
                                ? () {}
                                : () {
                                    Navigator.of(context).pushNamed(
                                        AthletePickerView.routeName,
                                        arguments: {
                                          'crewId': crewId,
                                          'no': index
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
