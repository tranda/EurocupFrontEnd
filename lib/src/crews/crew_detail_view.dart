import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/athlete/athlete.dart';

class CrewDetailView extends StatefulWidget {
  const CrewDetailView({Key? key}) : super(key: key);
  static const routeName = '/crew_detail';

  @override
  State<CrewDetailView> createState() => _CrewDetailViewState();
}

class _CrewDetailViewState extends State<CrewDetailView> {
  late Crew crew;

  @override
  Widget build(BuildContext context) {
    // Map<int, Athlete> crewAthletes;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    int size = args['size'];
    int crewId = args['crewId'];
    int helmNo = args['helmNo'];
    String title = args['title'];

    return Scaffold(
      appBar: appBar(title: title),
      body: FutureBuilder(
        future: api.getCrewAthletesForCrew(crewId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final _crewAthletes = snapshot.data!;
            return ListView.builder(
              itemCount: size,
              itemBuilder: (context, index) {
                var no = index + 1;
                var drummerPrefix = no == 1 ? "(drummer)" : "";
                var helmPrefix = no == helmNo ? "(helm)" : "";
                var reservePrefix = no > helmNo ? "(reserve)" : "";
                if (_crewAthletes.containsKey(index)) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                            "$no $drummerPrefix$helmPrefix$reservePrefix ${(_crewAthletes[index]!['athlete']! as Athlete).getDisplayName()}",
                            style: Theme.of(context).textTheme.bodyText1),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            api
                                .deleteCrewAthlete(_crewAthletes[index]!['id'])
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
                            style: Theme.of(context).textTheme.bodyText1),
                        onTap: () {
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
          return (const Text('No data'));
        },
      ),
    );
  }
}
