import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/athletes/athlete_detail_view.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'image_widget_web.dart' if (dart.library.io) 'package:flutter/material.dart';

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

  Widget _athleteAvatar(String photoUrl, bool hasCertificate) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: photoUrl.isNotEmpty
              ? (kIsWeb ? null : NetworkImage(photoUrl))
              : null,
          child: photoUrl.isNotEmpty && kIsWeb
              ? ClipOval(child: WebImage(imageUrl: photoUrl, width: 48, height: 48))
              : photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 28, color: Colors.grey)
                  : null,
        ),
        if (hasCertificate)
          Positioned(
            bottom: 0,
            right: 0,
            child: Icon(Icons.verified, size: 16, color: Colors.green.shade600),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithAction(
          locked
              ? () {}
              : () {
                  context.push(AthleteDetailView.routeName,
                      extra: {'mode': 'm', 'athlete': Athlete()}).then((value) {
                    setState(() {});
                  });
                },
          title: 'Athlete List',
          icon: Icons.add),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder<List<Athlete>>(
          future: api.getAthletesForClub(currentUser.clubId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final athletes = snapshot.data!;
              // Debug: athletes list
              return ListView.builder(
                itemCount: athletes.length,
                itemBuilder: (BuildContext context, int index) {
                  final athlete = athletes[index];
                  // Debug: athlete data
                  final coach = athlete.coach! ? ' (Coach)' : "";

                  final photoUrl = athlete.photo != null && athlete.photo!.isNotEmpty
                      ? "https://$imagePrefix/${athlete.photo}"
                      : "";

                  return Column(
                    children: [
                      ListTile(
                        leading: _athleteAvatar(photoUrl, athlete.certificate != null),
                          title: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                '${athlete.firstName} ${athlete.lastName} $coach',
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                          ),
                          onTap: () {
                            context.push(
          AthleteDetailView.routeName,
                                extra: {
                                  'mode': 'r',
                                  'allowEdit': !locked,
                                  'athlete': athlete
                                }).then((value) {
                              setState(() {});
                            });
                          },
                          subtitle: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: (8.0), vertical: 8.0),
                            child: Text(athlete.category ?? ""),
                          ),
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
