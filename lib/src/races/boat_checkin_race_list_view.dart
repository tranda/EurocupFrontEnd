import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import 'boat_checkin_view.dart';

/// Boat marshal entry point, laid out like Current Entries: one coloured
/// header per race (number, discipline, stage, time) with its crews by lane
/// underneath. Tap a crew to open BoatCheckinView.
class BoatCheckinRaceListView extends StatefulWidget {
  const BoatCheckinRaceListView({super.key});

  static const routeName = '/boat_checkin_races';

  @override
  State<BoatCheckinRaceListView> createState() => _BoatCheckinRaceListViewState();
}

class _BoatCheckinRaceListViewState extends State<BoatCheckinRaceListView> {
  static const _blue = Color.fromARGB(255, 0, 80, 150);

  List<Competition> _events = [];
  Competition? _event;
  List<RaceResult> _races = [];
  bool _loading = true;
  bool _hideFinished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final all = await api.getCompetitions();
      final active = all.where((e) => e.isActive).toList()
        ..sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      if (!mounted) return;
      setState(() {
        _events = active;
        _event = active.isNotEmpty ? active.first : null;
      });
      await _loadRaces();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadRaces() async {
    if (_event == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final races = await api.getRaceResults(eventId: _event!.id);
      if (!mounted) return;
      setState(() {
        _races = races.where((r) => !r.isBreak && !r.isCancelled).toList()
          ..sort((a, b) => (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0));
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Error loading races:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadRaces, child: const Text('Retry')),
        ]),
      );
    } else {
      final races = _hideFinished ? _races.where((r) => !r.isFinished).toList() : _races;
      body = RefreshIndicator(
        onRefresh: _loadRaces,
        child: ListView.builder(
          itemCount: races.length + 2, // header + races + empty note
          itemBuilder: (context, index) {
            if (index == 0) return _buildHeader();
            if (index == races.length + 1) {
              return races.isEmpty ? _buildEmpty() : const SizedBox(height: smallSpace);
            }
            return _buildRace(races[index - 1]);
          },
        ),
      );
    }

    return Scaffold(
      appBar: appBar(title: 'Boat Check-in'),
      body: Container(decoration: bckDecoration(), child: body),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Boat Check-in',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (_events.isNotEmpty)
            DropdownButtonFormField<Competition?>(
              decoration: InputDecoration(
                labelText: 'Select Event',
                labelStyle: const TextStyle(color: _blue, fontWeight: FontWeight.w500),
                contentPadding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: _blue, width: 2.0),
                ),
              ),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              dropdownColor: Colors.white,
              initialValue: _event,
              items: _events
                  .map((e) => DropdownMenuItem<Competition?>(value: e, child: Text('${e.name} ${e.year}')))
                  .toList(),
              onChanged: (e) {
                if (e == null) return;
                setState(() {
                  _event = e;
                  _loading = true;
                });
                _loadRaces();
              },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _blue,
            title: const Text('Hide finished races', style: TextStyle(color: Colors.black87)),
            value: _hideFinished,
            onChanged: (v) => setState(() => _hideFinished = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final text = _event == null ? 'No active event' : 'No races (the schedule may not be published yet)';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildRace(RaceResult race) {
    final crews = [...(race.crewResults ?? <CrewResult>[])]
      ..sort((a, b) => (a.lane ?? 999).compareTo(b.lane ?? 999));
    final subtitle = [race.stage ?? '', race.raceTimeDisplay, if (race.isFinished) 'Finished']
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return Column(
      children: [
        ColoredPageHeader(
          title: race.title,
          subtitle: subtitle,
          eventId: _event?.id,
          leading: Text(
            '${race.raceNumber ?? '-'}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ),
        const Divider(height: 4),
        if (crews.isEmpty)
          const PageListItem(child: ListTile(title: Text('No crews drawn yet'))),
        ...crews.map((crew) => _buildCrew(race, crew)),
        const Divider(height: smallSpace),
      ],
    );
  }

  Widget _buildCrew(RaceResult race, CrewResult crew) {
    final crewId = crew.crewId ?? crew.crew?.id;
    final teamName = crew.crew?.team?.name ?? crew.team?.name ?? 'Crew';
    final country = crew.crew?.team?.club?.country;

    return PageListItem(
      onTap: crewId == null
          ? null
          : () => Navigator.pushNamed(context, BoatCheckinView.routeName, arguments: {
                'raceResultId': race.id,
                'crewId': crewId,
                'title': teamName,
                'stage': race.stage ?? '',
                'raceNumber': race.raceNumber,
                'eventId': _event?.id,
              }),
      child: ListTile(
        leading: Text(
          crew.lane != null && crew.lane! > 0 ? 'L${crew.lane}' : '-',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        title: Row(
          children: [
            if (country != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  '${getCountryFlag(country)} ${getCountryCode(country)}',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(child: Text(teamName, style: Theme.of(context).textTheme.displaySmall)),
          ],
        ),
        trailing: const Icon(Icons.qr_code_scanner, color: _blue),
      ),
    );
  }
}
