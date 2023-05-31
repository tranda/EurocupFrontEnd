import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;


class CrewListView extends StatelessWidget {
  const CrewListView({Key? key}) : super(key: key);
  
  static const routeName = '/crew_list';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crew List'),
      ),
      body: FutureBuilder(future: api.getDisciplines(), builder: (context, snapshot) {
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

                return Column(
                  children: [
                    ListTile(
                        title: Text(race.discipline!.getDisplayName()),
                        ),
                      Column(children: List.generate(race.disciplineCrews!.length, (index) {
                        DisciplineCrew crew = race.disciplineCrews![index];
                        return Row(children: [
                          Text(crew.team!.name!),
                        ]);
                      }),),
                      const Divider()
                  ],
                );
              },
            );
          }
          return (const Text('No data'));
      },),
    );
  }
}
