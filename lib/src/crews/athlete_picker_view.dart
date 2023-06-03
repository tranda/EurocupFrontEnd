import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class AthletePickerView extends StatelessWidget {
  const AthletePickerView({super.key});
  static const routeName = '/athlete_picker';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final crewId = args['crewId'];
    final no = args['no'];
    return Scaffold(
      appBar: appBar(title: 'Pick an Athlete'),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/bck.jpg'), fit: BoxFit.cover)),
        child: FutureBuilder(
          future: api.getEligibleAthletesForCrew(args['crewId']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final athletes = snapshot.data!;
              return ListView.builder(
                  itemCount: athletes.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(athletes[index].getDisplayName(),
                              style: Theme.of(context).textTheme.displaySmall),
                          onTap: () {
                            api.insertCrewAthlete(
                                no, crewId, athletes[index].id!);
                            Navigator.of(context).pop();
                          },
                        ),
                        const Divider(
                          height: 4,
                        )
                      ],
                    );
                  });
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }
}
