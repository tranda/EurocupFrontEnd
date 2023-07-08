import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/clubs/club_details_view.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import '../athletes/athlete_detail_view.dart';

class ClubAthleteListView extends StatefulWidget {
  ClubAthleteListView({super.key});

  static const routeName = '/club_athlete_list';
  final List<Athlete> athletes = List.empty();

  @override
  State<ClubAthleteListView> createState() => _ClubAthleteListViewState();
}

class _ClubAthleteListViewState extends State<ClubAthleteListView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    int clubId = args['clubId'];
    String title = args['title'];

    return Scaffold(
      appBar: appBarWithAction(
        () {
          Navigator.pushNamed(context, ClubDetailView.routeName,
              arguments: {'clubId': clubId, 'title': title});
        },
        title: title,
        icon: Icons.info,
      ),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder<List<Athlete>>(
          future: api.getAthletesForClub(clubId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final athletes = snapshot.data!;

              return ListView.builder(
                itemCount: athletes.length,
                itemBuilder: (BuildContext context, int index) {
                  final athlete = athletes[index];

                  return Column(
                    children: [
                      ListTile(
                          leading: Text(
                            athlete.eurocup ?? "",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
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
                                  'allowEdit': false,
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
