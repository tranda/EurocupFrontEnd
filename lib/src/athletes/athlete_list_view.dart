import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/athletes/athlete_detail_view.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/model/event/event.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

class AthleteListView extends StatefulWidget {
  AthleteListView({super.key});

  static const routeName = '/athlete_list';
  final List<Athlete> athletes = List.empty();

  @override
  State<AthleteListView> createState() => _AthleteListViewState();
}

class _AthleteListViewState extends State<AthleteListView> {
  @override
  bool locked = false;

  @override
  void initState() {
    super.initState();
    var competition = competitions.first;
    // locked = DateTime.now().isAfter(competition.nameEntriesLock!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithAction(
          locked
              ? () {}
              : () {
                  Navigator.pushNamed(context, AthleteDetailView.routeName,
                      arguments: {'mode': 'm', 'athlete': Athlete()}).then((value) {
                    setState(() {});
                  });
                },
          title: 'Athlete List',
          icon: Icons.add),
      body: Container(
        // decoration: const BoxDecoration(
        //     image: DecorationImage(
        //         image: AssetImage('assets/images/bck.jpg'),
        //         fit: BoxFit.cover)),
        child: FutureBuilder<List<Athlete>>(
          future: api.getAthletesForClub(currentUser.clubId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final athletes = snapshot.data!;
              // print(_athletes);
              return ListView.builder(
                itemCount: athletes.length,
                itemBuilder: (BuildContext context, int index) {
                  final athlete = athletes[index];
                  // print(athlete);

                  return Column(
                    children: [
                      ListTile(
                          title: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                '${athlete.firstName} ${athlete.lastName}',
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                                context, AthleteDetailView.routeName,
                                arguments: {
                                  'mode': 'r',
                                  'allowEdit': !locked,
                                  'athlete': athlete
                                }).then((value) {
                              setState(() {});
                            });
                          },
                          trailing: const Icon(Icons.arrow_forward)),
                      const Divider(
                        height: 4,
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
