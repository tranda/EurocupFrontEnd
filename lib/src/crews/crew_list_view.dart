import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/crews/crew_detail_view.dart';
import 'package:eurocup_frontend/src/model/race/discipline_crew.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/race/race.dart';

class CrewListView extends StatefulWidget {
  const CrewListView({super.key});

  static const routeName = '/crew_list';

  @override
  State<CrewListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<CrewListView> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<Race>> _getActiveEventDisciplines() async {
    final activeEvents = competitions.where((c) => c.isActive).toList();
    List<Race> allRaces = [];
    for (var event in activeEvents) {
      final races = await api.getDisciplinesCombined(event.id!);
      allRaces.addAll(races);
    }
    return allRaces;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Crew List'),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: _getActiveEventDisciplines(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final races = snapshot.data!;
              // One section per event + boat group (Standard / Small).
              final Map<String, List<Race>> groups = {};
              for (final race in races) {
                groups
                    .putIfAbsent('${race.discipline?.eventId}|${race.discipline?.boatGroup ?? ''}', () => [])
                    .add(race);
              }
              final children = <Widget>[const PageTitleBlock(title: 'Crew List')];
              groups.forEach((key, groupRaces) {
                final first = groupRaces.first.discipline!;
                final competition = competitions.firstWhere(
                    (element) => element.id == first.eventId);
                final eventName = '${competition.name!} ${competition.year}';
                final boatGroup = first.boatGroup ?? '';
                final rows = <Widget>[];
                for (final race in groupRaces) {
                  for (final disciplineCrew in race.disciplineCrews ?? <DisciplineCrew>[]) {
                    rows.add(_buildCrewRow(context, race, disciplineCrew, competition));
                  }
                }
                children.addAll([
                  ColoredPageHeader(
                    title: boatGroup.isEmpty
                        ? '$eventName (${rows.length})'
                        : '$eventName · $boatGroup (${rows.length})',
                    eventId: first.eventId,
                  ),
                  const Divider(height: 4),
                  ...rows,
                  pageSectionGap,
                ]);
              });
              return ListView(children: children);
            }
            return (const Text('No data'));
          },
        ),
      ),
    );
  }

  Widget _buildCrewRow(BuildContext context, Race race, DisciplineCrew disciplineCrew, Competition competition) {
    const standardSize = 22;
    const smallSize = 12;
    final locked = !competition.isCrewEntriesOpen;
    final isStandard = race.discipline!.boatGroup == "Standard";
    final size = isStandard ? standardSize : smallSize;
    final reserves = isStandard ? competition.standardReserves! : competition.smallReserves!;
    final helmNo = isStandard ? standardSize : smallSize;
    return PageListItem(
      onTap: () {
        Navigator.of(context).pushNamed(CrewDetailView.routeName, arguments: {
          'crewId': disciplineCrew.crew!.id,
          'size': size + reserves,
          'helmNo': helmNo,
          'title': race.discipline!.getDisplayName(),
          'locked': locked,
          'teamName': disciplineCrew.team?.name,
          'eventId': race.discipline!.eventId,
        }).then((value) {
          setState(() {});
        });
      },
      child: ListTile(
        title: Text(
          race.discipline!.getDisplayName(),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              CountryBadge(country: disciplineCrew.team?.club?.country),
              Flexible(child: Text(disciplineCrew.team!.name!)),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(label: "${disciplineCrew.crew!.capacity}/$size+$reserves"),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}
