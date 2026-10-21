import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
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
              return ListView(
                children: [
                  PageTitleBlock(title: 'Clubs req ADEL (${clubs.length})'),
                  if (clubs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No clubs found')),
                    )
                  else ...[
                    ColoredPageHeader(
                        title: 'Clubs requiring ADEL (${clubs.length})'),
                    const Divider(height: 4),
                    for (final club in clubs)
                      PageListItem(
                        onTap: () {
                          Navigator.pushNamed(
                              context, ClubAthleteListView.routeName,
                              arguments: {
                                'clubId': club.id,
                                'title': club.name!
                              }).then((value) {
                            setState(() {});
                          });
                        },
                        child: ListTile(
                          title: Row(
                            children: [
                              CountryBadge(country: club.country),
                              Expanded(
                                child: Text(
                                  club.name ?? '',
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                        ),
                      ),
                    pageSectionGap,
                  ],
                ],
              );
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }
}
