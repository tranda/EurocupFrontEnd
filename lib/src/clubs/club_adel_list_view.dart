import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/club/club.dart';
import 'club_athlete_list_view.dart';

class ClubAdelListView extends StatefulWidget {
  const ClubAdelListView({super.key});

  static const routeName = '/club_adel_list';

  @override
  State<ClubAdelListView> createState() => ListViewState();
}

class ListViewState extends State<ClubAdelListView> {
  late Future<List<Club>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = api.getClubsForAdel(adelOnly: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: FutureBuilder(
            future: dataFuture, // api.getClubs(1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                return Text('Club List (${snapshot.data!.length})');
              }
              return const Text('Club list');
            },
          ),
        ),
      ),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: dataFuture, // api.getClubs(1),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final clubs = snapshot.data!;
              // Debug: clubs list
              return ListView.builder(
                itemCount: clubs.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      ListTile(
                          // tileColor: Colors.blue,
                          title: Row(
                            children: [
                              if (clubs[index].country != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    '${getCountryFlag(clubs[index].country)} ${getCountryCode(clubs[index].country)}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  clubs[index].name!,
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                                context, ClubAthleteListView.routeName,
                                arguments: {
                                  'clubId': clubs[index].id,
                                  'title': clubs[index].name!
                                }).then((value) {
                              setState(() {});
                            });
                          },
                          trailing: const Icon(Icons.arrow_forward)),
                      const Divider(
                        height: 4,
                      ),
                      const Divider(
                        height: smallSpace,
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
