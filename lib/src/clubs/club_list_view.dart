import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import '../model/club/club.dart';
import 'club_athlete_list_view.dart';

class ClubListView extends StatefulWidget {
  const ClubListView({Key? key}) : super(key: key);

  static const routeName = '/club_list';

  @override
  State<ClubListView> createState() => ListViewState();
}

class ListViewState extends State<ClubListView> {
  late Future<List<Club>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = api.getClubs(1);
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
              // print(_races);
              return ListView.builder(
                itemCount: clubs.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      ListTile(
                          // tileColor: Colors.blue,
                          title: Text(
                            clubs[index].name!,
                            style: Theme.of(context).textTheme.displaySmall,
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
