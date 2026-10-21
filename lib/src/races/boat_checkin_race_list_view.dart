import 'package:eurocup_frontend/src/model/event/event.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import 'boat_checkin_view.dart';

/// Boat marshal entry point: races of the active event, in race order.
/// Tap a race → its crews → BoatCheckinView.
class BoatCheckinRaceListView extends StatefulWidget {
  const BoatCheckinRaceListView({super.key});

  static const routeName = '/boat_checkin_races';

  @override
  State<BoatCheckinRaceListView> createState() => _BoatCheckinRaceListViewState();
}

class _BoatCheckinRaceListViewState extends State<BoatCheckinRaceListView> {
  List<Competition> _events = [];
  Competition? _event;
  List<RaceResult> _races = [];
  bool _loading = true;
  bool _hideFinished = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final all = await api.getCompetitions();
    final active = all.where((e) => e.isActive).toList()
      ..sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    if (!mounted) return;
    setState(() {
      _events = active;
      _event = active.isNotEmpty ? active.first : null;
    });
    await _loadRaces();
  }

  Future<void> _loadRaces() async {
    if (_event == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final races = await api.getRaceResults(eventId: _event!.id);
    if (!mounted) return;
    setState(() {
      _races = races.where((r) => !r.isBreak && !r.isCancelled).toList()
        ..sort((a, b) => (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final races = _hideFinished ? _races.where((r) => !r.isFinished).toList() : _races;

    return Scaffold(
      appBar: appBar(title: 'Boat Check-in'),
      body: Container(
        decoration: bckDecoration(),
        child: Column(
          children: [
            if (_events.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<Competition>(
                  isExpanded: true,
                  value: _event,
                  items: _events
                      .map((e) => DropdownMenuItem(value: e, child: Text('${e.name ?? ''} ${e.year ?? ''}')))
                      .toList(),
                  onChanged: (e) {
                    setState(() => _event = e);
                    _loadRaces();
                  },
                ),
              ),
            SwitchListTile(
              title: const Text('Hide finished races'),
              value: _hideFinished,
              onChanged: (v) => setState(() => _hideFinished = v),
            ),
            const Divider(height: 1),
            Expanded(child: _buildList(races)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<RaceResult> races) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_event == null) return const Center(child: Text('No active event'));
    if (races.isEmpty) {
      return const Center(child: Text('No races (the schedule may not be published yet)'));
    }

    return RefreshIndicator(
      onRefresh: _loadRaces,
      child: ListView.separated(
        itemCount: races.length,
        separatorBuilder: (_, __) => const Divider(height: 4),
        itemBuilder: (context, index) {
          final race = races[index];
          final time = race.raceTimeDisplay;
          return ListTile(
            leading: CircleAvatar(child: Text('${race.raceNumber ?? '-'}')),
            title: Text(race.title, style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text([race.stage ?? '', time, if (race.isFinished) 'Finished']
                .where((s) => s.isNotEmpty)
                .join(' · ')),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => Navigator.pushNamed(context, BoatCheckinCrewListView.routeName,
                arguments: {'raceResultId': race.id}),
          );
        },
      ),
    );
  }
}

/// Crews of one race, by lane. Tap a crew to start scanning.
class BoatCheckinCrewListView extends StatefulWidget {
  const BoatCheckinCrewListView({super.key});

  static const routeName = '/boat_checkin_crews';

  @override
  State<BoatCheckinCrewListView> createState() => _BoatCheckinCrewListViewState();
}

class _BoatCheckinCrewListViewState extends State<BoatCheckinCrewListView> {
  int? _raceResultId;
  RaceResult? _race;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_raceResultId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _raceResultId = args?['raceResultId'] as int?;
    _load();
  }

  Future<void> _load() async {
    if (_raceResultId == null) {
      setState(() => _loading = false);
      return;
    }
    final race = await api.getRaceResult(_raceResultId!);
    if (!mounted) return;
    setState(() {
      _race = race;
      _loading = false;
    });
  }

  /// Crews actually drawn into this race. The API also lists every crew of
  /// the discipline (for heats that includes crews racing in other heats),
  /// so keep only crews with a lane when lanes exist.
  List<CrewResult> _crews(RaceResult race) {
    final all = race.crewResults ?? [];
    final withLane = all.where((c) => c.lane != null && c.lane! > 0).toList();
    final crews = withLane.isNotEmpty ? withLane : all;
    crews.sort((a, b) => (a.lane ?? 999).compareTo(b.lane ?? 999));
    return crews;
  }

  @override
  Widget build(BuildContext context) {
    final race = _race;
    final title = race == null ? 'Race' : 'Race ${race.raceNumber ?? ''} · ${race.stage ?? ''}';

    return Scaffold(
      appBar: appBar(title: title),
      body: Container(
        decoration: bckDecoration(),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : race == null
                ? const Center(child: Text('Race not found'))
                : _buildList(race),
      ),
    );
  }

  Widget _buildList(RaceResult race) {
    final crews = _crews(race);
    if (crews.isEmpty) return const Center(child: Text('No crews in this race'));

    return ListView.separated(
      itemCount: crews.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 4),
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            title: Text(race.title, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(race.raceTimeDisplay),
          );
        }
        final crew = crews[index - 1];
        final crewId = crew.crewId ?? crew.crew?.id;
        final teamName = crew.crew?.team?.name ?? crew.team?.name ?? 'Crew';
        return ListTile(
          leading: CircleAvatar(child: Text(crew.lane != null && crew.lane! > 0 ? '${crew.lane}' : '-')),
          title: Text(teamName, style: Theme.of(context).textTheme.bodyLarge),
          trailing: const Icon(Icons.qr_code_scanner),
          onTap: crewId == null
              ? null
              : () => Navigator.pushNamed(context, BoatCheckinView.routeName, arguments: {
                    'raceResultId': race.id,
                    'crewId': crewId,
                    'title': teamName,
                    'stage': race.stage ?? '',
                  }),
        );
      },
    );
  }
}
