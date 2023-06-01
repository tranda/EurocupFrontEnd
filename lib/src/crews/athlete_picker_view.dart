import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class AthletePickerView extends StatelessWidget {
  const AthletePickerView({super.key});
  static const routeName = '/athlete_picker';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final crewId = args['crewId'];
    return Scaffold(
      appBar: AppBar(title: const Text('Pick an Athlete')),
      body: FutureBuilder(
        future: api.getAthletesForClub(args['crewId']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final _athletes = snapshot.data!;
            return ListView.builder(
                itemCount: _athletes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_athletes[index].firstName!),
                    onTap: () {
                      api.InsertCrewAthlete(
                          index, crewId, _athletes[index].id!);
                      Navigator.of(context).pop();
                    },
                  );
                });
          }
          return (const Text('No data'));
        },
      ),
    );
  }
}
