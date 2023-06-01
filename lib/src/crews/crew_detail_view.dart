import 'package:eurocup_frontend/src/crews/athlete_picker_view.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
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
                if (_crewAthletes.containsKey(index)) {
                  return ListTile(
                    title: Text(_crewAthletes[index]!.firstName!),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        api.deleteCrewAthlete(_crewAthletes[index]!
                            .id!); //TODO: ne znam sta je taj id
                      },
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text('$index'),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                          AthletePickerView.routeName,
                          arguments: {'crewId': crewId}).then((value) {
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
