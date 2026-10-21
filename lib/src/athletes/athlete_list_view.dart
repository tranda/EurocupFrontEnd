import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/athletes/athlete_detail_view.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/athlete/athlete.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
                  Navigator.pushNamed(context, AthleteDetailView.routeName,
                      arguments: {'mode': 'm', 'athlete': Athlete()}).then((value) {
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
              final children = <Widget>[
                PageTitleBlock(title: 'Athletes (${athletes.length})'),
              ];
              if (athletes.isEmpty) {
                children.add(const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No athletes yet')),
                ));
              }
              for (final group in _groupAthletesByCategory(athletes)) {
                children.add(ColoredPageHeader(
                    title: '${group.key} (${group.value.length})'));
                children.add(const Divider(height: 4));
                for (final athlete in group.value) {
                  final coach = athlete.coach! ? ' (Coach)' : "";
                  final photoUrl = athlete.photo != null && athlete.photo!.isNotEmpty
                      ? "https://$imagePrefix/${athlete.photo}"
                      : "";
                  children.add(PageListItem(
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
                    child: ListTile(
                      leading: _athleteAvatar(photoUrl, athlete.certificate != null),
                      title: Text(
                          '${athlete.firstName} ${athlete.lastName}$coach',
                          style: Theme.of(context).textTheme.displaySmall),
                      subtitle: Text(athlete.category ?? ""),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                  ));
                }
                children.add(pageSectionGap);
              }
              return ListView(children: children);
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }
}

/// Groups athletes by category, ordered like [disciplineAgeGroups]; unknown
/// categories follow alphabetically, athletes without a category go last.
List<MapEntry<String, List<Athlete>>> _groupAthletesByCategory(
    List<Athlete> athletes) {
  const noCategory = 'No category';
  final Map<String, List<Athlete>> groups = {};
  for (final athlete in athletes) {
    final cat = (athlete.category == null || athlete.category!.trim().isEmpty)
        ? noCategory
        : athlete.category!;
    groups.putIfAbsent(cat, () => []).add(athlete);
  }
  int rank(String cat) {
    if (cat == noCategory) return 1 << 30;
    final i = disciplineAgeGroups.indexOf(cat);
    return i >= 0 ? i : disciplineAgeGroups.length;
  }

  final keys = groups.keys.toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.toLowerCase().compareTo(b.toLowerCase());
    });
  return [for (final k in keys) MapEntry(k, groups[k]!)];
}
