import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crew Detail'),
      ),
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
                if (_crewAthletes.containsKey(index)) {
                  return ListTile(
                    title: Text("$no " + drummerPrefix + helmPrefix + " " + _crewAthletes[index]!['athlete']!.firstName!),
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
                  );
                } else {
                  return ListTile(
                    title: Text("$no " + drummerPrefix + helmPrefix),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          AthletePickerView.routeName,
                          arguments: {'crewId': crewId, 'no': index}).then((value) {
                        setState(() {});
                      });
                    },
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
