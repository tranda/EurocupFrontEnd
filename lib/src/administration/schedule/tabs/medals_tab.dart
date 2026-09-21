import 'dart:math';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../widgets.dart';

const Color _brandBlue = Color.fromARGB(255, 0, 80, 150);

// Fixed racing crew sizes (IDBF): standard = 20 paddlers + drummer + helm,
// small = 10 + drummer + helm. Reserves are added on top, per event config.
const int _standardCrew = 22;
const int _smallCrew = 12;

/// Medals-to-prepare calculator. For each racing category (a crew's own
/// discipline, so combined categories score separately) with >= 2 crews on the
/// approved schedule, medals = min(crews, 3) places x (crew size + reserves).
class MedalsTab extends StatefulWidget {
  final int eventId;
  final int standardReserves;
  final int smallReserves;

  const MedalsTab({
    super.key,
    required this.eventId,
    required this.standardReserves,
    required this.smallReserves,
  });

  @override
  State<MedalsTab> createState() => _MedalsTabState();
}

class _MedalRow {
  final String name;
  final bool small;
  final int crews; // distinct crews entered
  int get places => min(crews, 3); // podium spots that get a medal
  int perCrew(int stdRes, int smallRes) =>
      small ? _smallCrew + smallRes : _standardCrew + stdRes;
  _MedalRow(this.name, this.small, this.crews);
}

class _MedalsTabState extends State<MedalsTab> {
  late Future<List<_MedalRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  int get _stdRes => widget.standardReserves;
  int get _smallRes => widget.smallReserves;

  static bool _isSmall(String? boatGroup) =>
      (boatGroup ?? '').toLowerCase().contains('small');

  Future<List<_MedalRow>> _load() async {
    final races = await api.getRaceResults(
      eventId: widget.eventId,
      includeDrafts: true,
    );

    // category discipline_id -> (distinct crew ids, boat, best-known name)
    final crewsByCat = <int, Set<int>>{};
    final smallByCat = <int, bool>{};
    final nameByCat = <int, String>{};

    for (final r in races.where((r) => r.entryType == 'race')) {
      final raceSmall = _isSmall(r.discipline?.boatGroup);
      final raceName = r.discipline?.getDisplayName();
      for (final cr in (r.crewResults ?? const [])) {
        if ((cr.lane ?? 0) < 1) continue; // only lane-assigned crews count
        final catId = cr.crew?.disciplineId ?? r.disciplineId;
        final crewId = cr.crewId ?? cr.crew?.id;
        if (catId == null || crewId == null) continue;

        crewsByCat.putIfAbsent(catId, () => <int>{}).add(crewId);
        // Boat is shared within a combined race; seed from the race we saw.
        smallByCat.putIfAbsent(catId, () => raceSmall);
        // Prefer the name/boat from the race whose discipline IS this category.
        if (r.disciplineId == catId && raceName != null) {
          nameByCat[catId] = raceName;
          smallByCat[catId] = raceSmall;
        } else {
          nameByCat.putIfAbsent(catId, () => raceName ?? 'Category $catId');
        }
      }
    }

    final rows = <_MedalRow>[];
    for (final entry in crewsByCat.entries) {
      rows.add(_MedalRow(
        nameByCat[entry.key] ?? 'Category ${entry.key}',
        smallByCat[entry.key] ?? false,
        entry.value.length,
      ));
    }
    // Standard first, then by name.
    rows.sort((a, b) {
      if (a.small != b.small) return a.small ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: bckDecoration(),
      child: FutureBuilder<List<_MedalRow>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load: ${snap.error}'));
          }
          final all = snap.data ?? [];
          final counted = all.where((r) => r.crews >= 2).toList();
          final excluded = all.length - counted.length;
          return _buildBody(counted, excluded);
        },
      ),
    );
  }

  Widget _buildBody(List<_MedalRow> rows, int excluded) {
    // Totals
    int stdRaces = 0, stdCrews = 0, stdMedals = 0;
    int smlRaces = 0, smlCrews = 0, smlMedals = 0;
    int gold = 0, silver = 0, bronze = 0;
    for (final r in rows) {
      final per = r.perCrew(_stdRes, _smallRes);
      final medals = r.places * per;
      if (r.small) {
        smlRaces++;
        smlCrews += r.places;
        smlMedals += medals;
      } else {
        stdRaces++;
        stdCrews += r.places;
        stdMedals += medals;
      }
      gold += per; // 1st always awarded (>=2 crews)
      silver += per; // 2nd always awarded (>=2 crews)
      if (r.places >= 3) bronze += per; // 3rd only when >=3 crews
    }
    final total = stdMedals + smlMedals;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Medals to prepare',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(
          'Approved races with 2+ crews. Per crew: Standard $_standardCrew'
          '${_stdRes > 0 ? " + $_stdRes reserve" : ""} = ${_standardCrew + _stdRes}, '
          'Small $_smallCrew${_smallRes > 0 ? " + $_smallRes reserve" : ""} '
          '= ${_smallCrew + _smallRes}.',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _summaryCard('Standard', stdRaces, stdCrews, stdMedals)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Small', smlRaces, smlCrews, smlMedals)),
        ]),
        const SizedBox(height: 12),
        _totalCard(total, gold, silver, bronze),
        if (excluded > 0) ...[
          const SizedBox(height: 8),
          Text('$excluded categor${excluded == 1 ? "y" : "ies"} excluded (fewer than 2 crews).',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
        const SizedBox(height: 20),
        _table(rows),
      ],
    );
  }

  Widget _summaryCard(String label, int races, int crews, int medals) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label boat',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _brandBlue)),
        const SizedBox(height: 6),
        Text('$medals',
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87)),
        const Text('medals', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text('$races race${races == 1 ? "" : "s"} · $crews podium crews',
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ]),
    );
  }

  Widget _totalCard(int total, int gold, int silver, int bronze) {
    Widget chip(String label, int n, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withValues(alpha: 0.5)),
          ),
          child: Text('$label $n',
              style: TextStyle(fontWeight: FontWeight.w600, color: c)),
        );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _brandBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total medals',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        Text('$total',
            style: const TextStyle(
                color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          chip('🥇 Gold', gold, const Color(0xFFB8860B)),
          chip('🥈 Silver', silver, const Color(0xFF708090)),
          chip('🥉 Bronze', bronze, const Color(0xFF8C5A2B)),
        ]),
      ]),
    );
  }

  Widget _table(List<_MedalRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: _brandBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(children: [
            Expanded(flex: 5, child: Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('Boat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            SizedBox(width: 48, child: Text('Crews', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            SizedBox(width: 64, child: Text('Medals', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ]),
        ),
        for (int i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: i.isEven ? Colors.white : Colors.blue.shade50.withValues(alpha: 0.4),
            child: Row(children: [
              Expanded(flex: 5, child: Text(rows[i].name, style: const TextStyle(fontSize: 13))),
              Expanded(flex: 2, child: Text(rows[i].small ? 'Small' : 'Standard', style: const TextStyle(fontSize: 13))),
              SizedBox(width: 48, child: Text('${rows[i].crews}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
              SizedBox(
                width: 64,
                child: Text('${rows[i].places * rows[i].perCrew(_stdRes, _smallRes)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No medal categories yet (need 2+ crews on the schedule).'),
          ),
      ]),
    );
  }
}
