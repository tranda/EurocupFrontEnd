import 'dart:html' as html;
import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../common.dart';
import '../../../model/race/crew_result.dart';
import '../../../model/race/race_result.dart';
import '../../../model/schedule/crew_seed.dart';
import '../../../model/schedule/schedule_config.dart';
import '../../../model/schedule/schedule_block.dart';
import '../../../widgets/compact_icon.dart';
import '../race_color_palette.dart';

/// Grid view of all scheduled races in chronological order, with inline edit
/// of time/stage, lane assignment dialogs, and per-row delete.
class GridTab extends StatefulWidget {
  final int eventId;
  final ScheduleConfig config;

  const GridTab({super.key, required this.eventId, required this.config});

  @override
  State<GridTab> createState() => _GridTabState();
}

class _GridTabState extends State<GridTab> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<RaceResult> _races = [];
  // crews indexed by discipline_id, lazily loaded
  final Map<int, List<CrewSeed>> _crewsByDiscipline = {};
  // simple filters
  int? _filterDisciplineId;
  String? _filterStage;
  // which race rows are currently expanded
  final Set<int> _expanded = <int>{};

  int get _laneCount => widget.config.laneCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final races = await api.getRaceResults(eventId: widget.eventId, includeDrafts: true);
      races.sort(_compareForGrid);
      setState(() {
        _races = races;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _compareForGrid(RaceResult a, RaceResult b) {
    final at = a.raceTime;
    final bt = b.raceTime;
    if (at == null && bt == null) return (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0);
    if (at == null) return 1;
    if (bt == null) return -1;
    final c = at.compareTo(bt);
    return c != 0 ? c : (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0);
  }

  Future<List<CrewSeed>> _loadCrewsFor(int disciplineId) async {
    final cached = _crewsByDiscipline[disciplineId];
    if (cached != null) return cached;
    final crews = await api.getDisciplineCrewSeeds(disciplineId);
    _crewsByDiscipline[disciplineId] = crews;
    return crews;
  }

  Future<void> _onReorder(List<RaceResult> rows, int oldIndex, int newIndex) async {
    // Flutter ReorderableListView quirk: newIndex is post-removal; adjust when moving down.
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex == oldIndex) return;

    // Unified slot-swap: races AND breaks participate. The slice between the
    // old and new positions has its times rotated so the moved item picks up
    // the time at its new position and everything else slides one slot to
    // fill the gap. The backend recompute then normalizes block timing
    // (advancing the cursor by gap_seconds for races, by duration for shift
    // breaks, by zero for parallel breaks), so the on-screen result is
    // always a clean re-layout.
    //
    // This is the path that makes "drag a race past a break" work: the
    // break gets the race's old time and the race gets the break's time,
    // then recompute slots them in their new order.
    final lo = oldIndex < newIndex ? oldIndex : newIndex;
    final hi = oldIndex < newIndex ? newIndex : oldIndex;

    // Reject if any item in the slice is past SCHEDULED — finished/running
    // races can't move.
    for (var i = lo; i <= hi; i++) {
      if (rows[i].status != 'SCHEDULED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot reorder: a race in this range is running or finished.')),
        );
        return;
      }
    }

    final slotTimes = [for (var i = lo; i <= hi; i++) rows[i].raceTime];

    final reordered = List<RaceResult>.from(rows);
    final movedItem = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, movedItem);

    final updates = <MapEntry<int, DateTime>>[];
    for (var i = lo; i <= hi; i++) {
      final r = reordered[i];
      final time = slotTimes[i - lo];
      if (time == null) continue;
      if (r.id == null) continue;
      if (r.raceTime == time) continue;
      updates.add(MapEntry(r.id!, time));
    }

    if (updates.isEmpty) return;
    await _runWithBusy(() => api.reorderRaces(updates));
  }

  Future<void> _runWithBusy(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editRace(RaceResult race) async {
    final stageController = TextEditingController(text: race.stage ?? '');
    DateTime time = race.raceTime ?? DateTime.now();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Edit race #${race.raceNumber}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: stageController,
              decoration: const InputDecoration(labelText: 'Stage'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Time: '),
              Text(_formatDateTime(time)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(time),
                  );
                  if (picked != null) {
                    setLocal(() {
                      time = DateTime(time.year, time.month, time.day, picked.hour, picked.minute);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: time,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setLocal(() {
                      time = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                    });
                  }
                },
              ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result == true && race.id != null) {
      await _runWithBusy(() => api.updateRaceResultFields(
            race.id!,
            raceTime: time,
            stage: stageController.text.trim().isEmpty ? null : stageController.text.trim(),
          ));
    }
  }

  Future<void> _deleteRace(RaceResult race) async {
    final ok = await _confirm(
      'Delete race?',
      'Race #${race.raceNumber} (${race.discipline?.getDisplayName() ?? "?"} · ${race.stage ?? "?"})',
    );
    if (ok && race.id != null) {
      await _runWithBusy(() => api.deleteRaceResult(race.id!));
    }
  }

  Future<void> _assignLane(RaceResult race, int lane) async {
    if (race.id == null || race.disciplineId == null) return;
    try {
      final crews = await _loadCrewsFor(race.disciplineId!);
      final currentInLane = race.crewResults?.firstWhere(
        (cr) => cr.lane == lane,
        orElse: () => CrewResult(),
      );
      final currentCrewId = currentInLane?.crewId;

      if (!mounted) return;
      final newCrewId = await showDialog<int?>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text('Lane $lane — Race #${race.raceNumber}'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, -1), // sentinel for "empty"
              child: const Text('— Empty (clear lane) —', style: TextStyle(color: Colors.red)),
            ),
            const Divider(),
            ...crews.map((c) {
              final selected = c.crewId == currentCrewId;
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, c.crewId),
                child: Row(children: [
                  if (selected)
                    const Icon(Icons.check, size: 16, color: Colors.green)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(c.teamName ?? 'Crew ${c.crewId}')),
                  if (c.seedNumber != null)
                    Text('seed ${c.seedNumber}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ]),
              );
            }),
          ],
        ),
      );
      if (newCrewId == null) return; // cancelled
      if (newCrewId == -1 && currentCrewId != null) {
        await _runWithBusy(() => api.assignCrewToLane(race.id!, currentCrewId, null));
      } else if (newCrewId > 0 && newCrewId != currentCrewId) {
        await _runWithBusy(() => api.assignCrewToLane(race.id!, newCrewId, lane));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  /// Auto-fill this race's lanes centre-out using crew seed numbers.
  /// Trigger LaneSeeder for the discipline this race belongs to. Seeds the
  /// next un-seeded stage based on current results. Surfaces warnings /
  /// "skipped" reasons via a snackbar so the referee can see why nothing
  /// changed (e.g. "source heats not all finished").
  Future<void> _reseedNextStage(RaceResult race) async {
    if (race.disciplineId == null) return;
    try {
      final result = await api.seedNextRound(race.disciplineId!);
      if (!mounted) return;
      final warnings = result.warnings;
      final msg = warnings.isEmpty
          ? 'Next stage seeded.'
          : warnings.join(' · ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-seed failed: $e')));
    }
  }

  /// Progression stages (Repechage/Semi/Final) whose lanes are seeded from
  /// prior-round results and can be cleared to re-seed. Heats/Rounds hold
  /// registered crews and are excluded.
  bool _isProgressionStage(RaceResult race) {
    final s = (race.stage ?? '').toLowerCase();
    if (s.startsWith('heat') || s.startsWith('round')) return false;
    return s.contains('repechage') || s.contains('semi') || s.contains('final');
  }

  /// Empty a progression race's seeded crews so it can re-seed fresh.
  Future<void> _clearSeeds(RaceResult race) async {
    if (race.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear seeds?'),
        content: Text(
          'Remove the seeded crews from "${race.stage ?? 'this race'}"? '
          'It will be emptied and can be re-seeded from results.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await api.clearRaceSeeds(race.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeds cleared.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clear failed: $e')));
    }
  }

  /// Crews without a seed number get appended after seeded ones.
  ///
  /// For Round-plan stages "Round N" (N >= 1), the seed order is rotated by
  /// (N-1) before placement so crews don't sit in the same lane every round —
  /// same algorithm as the backend's ScheduleGeneratorService::roundLaneSeeding
  /// (and RacePlan::compactCentreOut). For Heats / Reps / Semis / Finals the
  /// rotation is a no-op (shift = 0).
  Future<void> _autoFillLanes(RaceResult race) async {
    if (race.id == null || race.disciplineId == null) return;
    try {
      final crews = await _loadCrewsFor(race.disciplineId!);
      if (crews.isEmpty) return;

      // Sort: seeded ascending, then unseeded by id-order.
      final sorted = [...crews];
      sorted.sort((a, b) {
        final as = a.seedNumber, bs = b.seedNumber;
        if (as == null && bs == null) return 0;
        if (as == null) return 1;
        if (bs == null) return -1;
        return as.compareTo(bs);
      });

      // Per-round rotation: only kicks in for stage names like "Round 2",
      // "Round 3". Round 1 / Heat / Rep / Semi / Final → shift = 0.
      final roundNum = _extractRoundNumber(race.stage);
      final shift = (roundNum > 1 && sorted.isNotEmpty)
          ? (roundNum - 1) % sorted.length
          : 0;
      final rotated = shift == 0
          ? sorted
          : [...sorted.sublist(shift), ...sorted.sublist(0, shift)];

      // Centre-out lane order per IDBF: for even lane counts the centre lane
      // is the LOWER of the two middle lanes (lane 2 of 4, lane 3 of 6, lane
      // 4 of 8), then alternate RIGHT, LEFT. So 4 lanes → [2,3,1,4]; 6 →
      // [3,4,2,5,1,6]. Empty lanes end up on the outside (highest lane
      // number), never lane 1. Matches the backend ScheduleGeneratorService
      // and RacePlan::compactCentreOut.
      final n = _laneCount;
      final centre = (n + 1) ~/ 2;
      final order = <int>[centre];
      for (var d = 1; d < n; d++) {
        final right = centre + d, left = centre - d;
        if (right <= n) order.add(right);
        if (left >= 1) order.add(left);
      }

      // Build assignment payload — empties for unused lanes.
      final assignments = <Map<String, dynamic>>[];
      final used = <int>{};
      for (var i = 0; i < rotated.length && i < order.length; i++) {
        assignments.add({'crew_id': rotated[i].crewId, 'lane': order[i]});
        used.add(order[i]);
      }
      // Clear any crews currently assigned to lanes we're not using.
      for (final cr in race.crewResults ?? <CrewResult>[]) {
        if (cr.crewId != null && !assignments.any((a) => a['crew_id'] == cr.crewId)) {
          assignments.add({'crew_id': cr.crewId, 'lane': null});
        }
      }

      await _runWithBusy(() => api.setCrewLanes(race.id!, assignments));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  /// "Round 2" → 2; "Round 10" → 10; everything else → 1 (so no rotation).
  int _extractRoundNumber(String? stage) {
    if (stage == null) return 1;
    final m = RegExp(r'^Round\s+(\d+)$', caseSensitive: false).firstMatch(stage.trim());
    if (m == null) return 1;
    return int.tryParse(m.group(1)!) ?? 1;
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result == true;
  }

  String _formatDateTime(DateTime t) =>
      '${t.year}-${_pad(t.month)}-${_pad(t.day)} ${_pad(t.hour)}:${_pad(t.minute)}';
  String _formatTimeOnly(DateTime t) => '${_pad(t.hour)}:${_pad(t.minute)}';
  String _formatDateOnly(DateTime t) => '${t.year}-${_pad(t.month)}-${_pad(t.day)}';
  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_races.isEmpty) {
      return const Center(child: Text('No races yet. Generate from the Plan & Seeds tab.'));
    }

    return Stack(children: [
      Column(children: [
        _filterBar(),
        const Divider(height: 1),
        Expanded(child: _grid()),
      ]),
      if (_busy)
        const Positioned.fill(
          child: ColoredBox(
            color: Color.fromARGB(60, 255, 255, 255),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ]);
  }

  Widget _filterBar() {
    final disciplines = <int, Discipline>{};
    for (final r in _races) {
      if (r.discipline?.id != null) disciplines[r.discipline!.id!] = r.discipline!;
    }
    final stages = _races.map((r) => r.stage ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color.fromARGB(255, 245, 247, 250),
      child: Row(children: [
        const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          value: _filterDisciplineId,
          hint: const Text('Discipline'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All disciplines')),
            ...disciplines.values.map((d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.getDisplayName()),
                )),
          ],
          onChanged: (v) => setState(() => _filterDisciplineId = v),
        ),
        const SizedBox(width: 12),
        DropdownButton<String?>(
          value: _filterStage,
          hint: const Text('Stage'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All stages')),
            ...stages.map((s) => DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: (v) => setState(() => _filterStage = v),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _addBreak,
          icon: const Icon(Icons.coffee, size: 18),
          label: const Text('Add break'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _exportSchedule,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export'),
        ),
        const SizedBox(width: 8),
        CompactIcon(
          Icons.refresh,
          tooltip: 'Refresh',
          onPressed: _load,
        ),
      ]),
    );
  }

  /// Flatten config days/blocks into a single list ordered like the backend
  /// orderedBlocks() — day.sort_order then block.sort_order. Cached per build.
  late final List<_BlockWithDate> _orderedBlocksCache = (() {
    final out = <_BlockWithDate>[];
    final days = [...widget.config.days]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final day in days) {
      final blocks = [...day.blocks]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final b in blocks) {
        out.add(_BlockWithDate(block: b, date: day.date));
      }
    }
    return out;
  })();

  /// First block matching the race's discipline filters (gender/distance/
  /// stage/competition). Mirrors backend findMatchingBlock so the separator
  /// boundaries line up with where placeRacesIntoBlocks dropped each race.
  ScheduleBlock? _blockForRace(RaceResult race) {
    final d = race.discipline;
    if (d == null) return null;
    for (final bd in _orderedBlocksCache) {
      if (_blockMatches(bd.block, d, race.stage)) return bd.block;
    }
    return null;
  }

  bool _blockMatches(ScheduleBlock block, dynamic discipline, String? stage) {
    final genderMap = {'M': 'Open', 'W': 'Women', 'X': 'Mixed'};
    if (block.genderFilter != null && block.genderFilter!.isNotEmpty) {
      final needles = block.genderFilter!
          .map((v) => genderMap[v.toUpperCase()] ?? v)
          .toList();
      if (!needles.contains(discipline.genderGroup)) return false;
    }
    if (block.distanceFilter != null && block.distanceFilter!.isNotEmpty) {
      final needles = block.distanceFilter!
          .map((v) => v.replaceAll(RegExp(r'\D'), ''))
          .where((v) => v.isNotEmpty)
          .toList();
      if (!needles.contains('${discipline.distance}')) return false;
    }
    if (block.stageFilter != null && block.stageFilter!.isNotEmpty) {
      final s = (stage ?? '').toLowerCase();
      if (!block.stageFilter!.any((n) => s.contains(n.toLowerCase()))) {
        return false;
      }
    }
    if (block.competitionFilter != null && block.competitionFilter!.isNotEmpty) {
      final c = (discipline.competition ?? '').toString().toLowerCase();
      final needles = block.competitionFilter!.map((v) => v.toLowerCase()).toList();
      if (!needles.contains(c)) return false;
    }
    return true;
  }

  Widget _blockSeparator(ScheduleBlock block) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFE3F2FD),
      child: Row(children: [
        const Icon(Icons.subdirectory_arrow_right, size: 16, color: Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          block.name.isNotEmpty ? block.name : 'Block',
          style: const TextStyle(
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'starts ${block.startTime} · gap ${block.gapSeconds ~/ 60} min',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ]),
    );
  }

  Widget _grid() {
    final filtered = _races.where((r) {
      if (_filterDisciplineId != null && r.disciplineId != _filterDisciplineId) return false;
      if (_filterStage != null && r.stage != _filterStage) return false;
      return true;
    }).toList();

    // Group by date string (or "Unscheduled" bucket for races with no time).
    final groups = <String, List<RaceResult>>{};
    for (final r in filtered) {
      final key = r.raceTime == null ? 'Unscheduled' : _formatDateOnly(r.raceTime!);
      (groups[key] ??= []).add(r);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'Unscheduled') return 1;
        if (b == 'Unscheduled') return -1;
        return a.compareTo(b);
      });

    // Real dates only (no "Unscheduled") for the copy-order picker.
    final availableDates = keys.where((k) => k != 'Unscheduled').toList();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final key in keys) _dateSection(key, groups[key]!, availableDates),
      ]),
    );
  }

  Widget _dateSection(String dateLabel, List<RaceResult> rows, List<String> availableDates) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color.fromARGB(255, 0, 80, 150),
          child: Row(children: [
            const Icon(Icons.event, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${rows.length} race${rows.length == 1 ? "" : "s"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            // "Copy order from another day" — useful when day 2 has the
            // same races as day 1 just at a different distance, and you
            // want them in the same sequence.
            if (dateLabel != 'Unscheduled' &&
                availableDates.where((d) => d != dateLabel).isNotEmpty)
              TextButton.icon(
                onPressed: () => _copyDayOrder(dateLabel, availableDates),
                icon: const Icon(Icons.swap_vert, color: Colors.white, size: 16),
                label: const Text(
                  'Copy order from…',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ]),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: rows.length,
          itemBuilder: (ctx, i) {
            final race = rows[i];
            final canDrag = race.status == 'SCHEDULED';
            final block = _blockForRace(race);
            final prevBlock = i == 0 ? null : _blockForRace(rows[i - 1]);
            final showSeparator = block != null && block.id != prevBlock?.id;
            final row = Row(
              children: [
                if (canDrag)
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.drag_indicator,
                        color: Color.fromARGB(255, 80, 80, 80),
                        size: 28,
                        semanticLabel: 'Drag to reorder',
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 44),
                Expanded(child: _raceCard(race)),
              ],
            );
            return Column(
              key: ValueKey('race-${race.id}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSeparator) _blockSeparator(block),
                row,
              ],
            );
          },
          onReorder: (oldIndex, newIndex) => _onReorder(rows, oldIndex, newIndex),
        ),
      ]),
    );
  }

  /// For final rounds (last round of a Rounds plan, Grand Final, etc.) the
  /// per-race `position` field is meaningless — final standings are decided
  /// by accumulated time across all rounds. Mirror what the Race Results
  /// page does: sort the FINISHED crews by finalTimeMs and overwrite
  /// `position` with the 1-based rank; clear position on non-finished crews.
  void _calculateFinalPositions(List<CrewResult> crewResults) {
    final finished = crewResults
        .where((c) => c.finalStatus == 'FINISHED' && c.finalTimeMs != null)
        .toList()
      ..sort((a, b) => a.finalTimeMs!.compareTo(b.finalTimeMs!));
    for (var i = 0; i < finished.length; i++) {
      finished[i].position = i + 1;
    }
    for (final c in crewResults) {
      if (c.finalStatus != 'FINISHED' || c.finalTimeMs == null) {
        c.position = null;
      }
    }
  }

  Widget _raceCard(RaceResult race) {
    if (race.isBreak) return _breakCard(race);
    final raceId = race.id;
    final isExpanded = raceId != null && _expanded.contains(raceId);

    // Mutate crew_results' `position` to the final-round ranking when the
    // race is a final (last round of a Rounds plan, Grand Final, etc.) so
    // _laneRow can render the same "#pos · time" badge the Race Results
    // page shows. Matches `_calculatePositions(..., isFinalRound: true)`
    // in race_results_list_view.dart.
    if (race.isFinalRound == true) {
      _calculateFinalPositions(race.crewResults ?? const []);
    }

    final crewByLane = <int, CrewResult>{};
    for (final cr in race.crewResults ?? <CrewResult>[]) {
      if (cr.lane != null) crewByLane[cr.lane!] = cr;
    }
    final filledLanes = crewByLane.length;
    final headerColor = competitionColor[0]; // deep blue, matches Race Results

    return Column(children: [
      Material(
        color: headerColor,
        child: InkWell(
          onTap: raceId == null
              ? null
              : () => setState(() {
                    if (isExpanded) {
                      _expanded.remove(raceId);
                    } else {
                      _expanded.add(raceId);
                    }
                  }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: LayoutBuilder(builder: (ctx, constraints) {
              final narrow = constraints.maxWidth < 600;
              final numCell = SizedBox(
                width: 38,
                child: Text(
                  '#${race.raceNumber ?? "—"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
              final timeCell = SizedBox(
                width: 48,
                child: Text(
                  race.raceTime == null ? '—' : _formatTimeOnly(race.raceTime!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
              final lanesCell = SizedBox(
                width: 36,
                child: Text(
                  '$filledLanes/$_laneCount',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
              final actionIcons = [
                CompactIcon(
                  Icons.auto_fix_high,
                  tooltip: 'Auto-fill lanes (centre-out by seed)',
                  onPressed: () => _autoFillLanes(race),
                  color: Colors.white,
                ),
                CompactIcon(
                  Icons.fast_forward,
                  tooltip: 'Re-seed next un-seeded stage for this discipline (uses current results)',
                  onPressed: () => _reseedNextStage(race),
                  color: Colors.white,
                ),
                if (_isProgressionStage(race))
                  CompactIcon(
                    Icons.layers_clear,
                    tooltip: 'Clear seeds (empty this stage so it can re-seed)',
                    onPressed: () => _clearSeeds(race),
                    color: Colors.white,
                  ),
                CompactIcon(
                  Icons.edit,
                  tooltip: 'Edit time/stage',
                  onPressed: () => _editRace(race),
                  color: Colors.white,
                ),
                CompactIcon(
                  Icons.delete_outline,
                  tooltip: 'Delete race',
                  onPressed: () => _deleteRace(race),
                  color: Colors.white,
                ),
                if (raceId != null)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 20,
                  ),
              ];

              if (!narrow) {
                return Row(children: [
                  numCell,
                  timeCell,
                  Expanded(child: _disciplineBadges(race)),
                  const SizedBox(width: 8),
                  _stageBadge(race.stage),
                  const SizedBox(width: 8),
                  lanesCell,
                  const SizedBox(width: 4),
                  ...actionIcons,
                ]);
              }

              // Narrow layout: stack so badges get the full row width.
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  numCell,
                  timeCell,
                  Expanded(child: _stageBadge(race.stage)),
                  const SizedBox(width: 6),
                  lanesCell,
                  ...actionIcons,
                ]),
                const SizedBox(height: 4),
                _disciplineBadges(race),
              ]);
            }),
          ),
        ),
      ),
      const Divider(height: 1),
      if (isExpanded) ...[
        for (var lane = 1; lane <= _laneCount; lane++)
          _laneRow(race, lane, crewByLane[lane]),
        _progressionRow(race),
      ],
      const Divider(height: smallSpace),
    ]);
  }

  // One-line "where do these crews go next" rule. Reads progressionNote first
  // (admin override) and falls back to progressionRule (auto-derived by the
  // server). Hidden when both are empty so blocks without rules (e.g. Grand
  // Final → 'Final standings.') stay clean.
  Widget _progressionRow(RaceResult race) {
    final note = race.progressionNote?.trim() ?? '';
    final auto = race.progressionRule?.trim() ?? '';
    final text = note.isNotEmpty ? note : auto;
    final isOverride = note.isNotEmpty;
    if (text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Expanded(
            child: Text(
              'No progression rule',
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
          CompactIcon(
            Icons.edit_note,
            tooltip: 'Set progression rule',
            onPressed: () => _editProgressionNote(race),
            color: Colors.grey[600],
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOverride ? Colors.amber.shade50 : Colors.blue.shade50,
        border: Border(
          left: BorderSide(
            color: isOverride ? Colors.amber.shade700 : Colors.blue.shade700,
            width: 3,
          ),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(
          isOverride ? Icons.edit_note : Icons.arrow_forward,
          size: 14,
          color: isOverride ? Colors.amber.shade800 : Colors.blue.shade700,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[800]),
          ),
        ),
        CompactIcon(
          Icons.edit,
          tooltip: isOverride ? 'Edit override (clear to revert to auto)' : 'Override progression rule',
          onPressed: () => _editProgressionNote(race),
          color: Colors.grey[700],
        ),
      ]),
    );
  }

  Future<void> _editProgressionNote(RaceResult race) async {
    final raceId = race.id;
    if (raceId == null) return;
    final controller = TextEditingController(text: race.progressionNote ?? '');
    final auto = race.progressionRule ?? '';
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Progression rule'),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (auto.isNotEmpty) ...[
              Text('Auto rule:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: Text(auto, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],
            Text('Override (leave empty to use auto rule):',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(''),
            child: const Text('Clear override'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return; // cancelled
    try {
      await api.updateRaceResultFields(raceId, progressionNote: result);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  /// Whether to show the accumulated/summed time beside the per-race time.
  /// Mirrors race_results_list_view._isLastRound: only round-based final rounds
  /// accumulate. Heat-based finals (Grand/Minor/Tail Final) show the single
  /// race time alone — summing one race with itself is meaningless.
  bool _showAccumulated(RaceResult race) {
    if (race.showAccumulatedTime != null) return race.showAccumulatedTime!;
    final stage = race.stage?.trim().toLowerCase() ?? '';
    return stage.contains('round') && (race.isFinalRound ?? false);
  }

  Widget _laneRow(RaceResult race, int lane, CrewResult? crewResult) {
    final teamName = crewResult?.crew?.team?.name ?? crewResult?.team?.name;
    final hasContent = crewResult != null && teamName != null;
    final country = crewResult?.crew?.team?.club?.country;

    final status = crewResult?.status;
    final finalStatus = crewResult?.finalStatus;
    final isFinalView = _showAccumulated(race);
    final hasPerRaceResult = hasContent
        && (crewResult.timeMs != null
            || status == 'FINISHED'
            || status == 'DNS'
            || status == 'DNF'
            || status == 'DSQ');
    final hasFinalResult = hasContent
        && isFinalView
        && (crewResult.finalTimeMs != null || finalStatus != null);
    final position = crewResult?.position;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: ListTile(
        onTap: () => _assignLane(race, lane),
        leading: _positionOrLaneCircle(
          lane: lane,
          position: position,
          isFinalView: isFinalView,
          hasResult: hasPerRaceResult || hasFinalResult,
          hasContent: hasContent,
        ),
        title: Row(children: [
          if (hasContent && country != null)
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
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: Text(
              hasContent ? teamName : '— empty —',
              style: TextStyle(
                color: hasContent ? Colors.black87 : Colors.grey,
                fontStyle: hasContent ? FontStyle.normal : FontStyle.italic,
                fontSize: 16,
                fontWeight: hasContent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ]),
        subtitle: Text(
          'Lane $lane',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        trailing: !hasContent
            ? const Icon(Icons.add, size: 18, color: Colors.grey)
            : _resultTrailing(
                race: race,
                crewResult: crewResult,
                isFinalView: isFinalView,
                hasPerRaceResult: hasPerRaceResult,
                hasFinalResult: hasFinalResult,
              ),
      ),
    );
  }

  /// Position chip on the left of the lane row. Matches the Race Results
  /// page's circle: for final rounds it's a coloured fill (gold/silver/
  /// bronze/blue) with the position number; for non-final rounds (heats,
  /// reps, etc.) it's a transparent fill with a coloured border + coloured
  /// number. Falls back to the lane number when no result is in yet.
  Widget _positionOrLaneCircle({
    required int lane,
    required int? position,
    required bool isFinalView,
    required bool hasResult,
    required bool hasContent,
  }) {
    Color bg, border, fg;
    String label;
    if (hasResult && position != null) {
      final base = _positionColor(position);
      if (isFinalView) {
        bg = base;
        border = Colors.transparent;
        fg = Colors.white;
      } else {
        bg = Colors.transparent;
        border = base;
        fg = base;
      }
      label = '$position';
    } else {
      // No result yet — show lane.
      bg = hasContent ? Colors.blue.shade50 : Colors.grey.shade100;
      border = hasContent ? Colors.blue.shade300 : Colors.grey.shade300;
      fg = Colors.black54;
      label = '$lane';
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  /// Trailing chip(s). Final rounds get TWO stacked badges — per-race time
  /// (lighter green) plus accumulated/summed time (darker green) — exactly
  /// like the Race Results page. Non-final rounds get a single badge.
  /// Delays below the badge appear when the crew is behind first place.
  Widget _resultTrailing({
    required RaceResult race,
    required CrewResult crewResult,
    required bool isFinalView,
    required bool hasPerRaceResult,
    required bool hasFinalResult,
  }) {
    if (!hasPerRaceResult && !hasFinalResult) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade400,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Registered',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    Widget badge(String text, Color bg, {String delay = ''}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (delay.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                delay,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
        ],
      );
    }

    if (isFinalView && hasFinalResult) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge(
            crewResult.displayTime,
            _statusColor(crewResult.status),
            delay: _calcCurrentRoundDelay(crewResult, race),
          ),
          const SizedBox(width: 8),
          badge(
            crewResult.displayFinalTime,
            _statusColorTotal(crewResult.finalStatus ?? crewResult.status),
            delay: _calcFinalDelay(crewResult, race),
          ),
        ],
      );
    }

    // Per-race only.
    return badge(
      crewResult.displayTime,
      _statusColor(crewResult.status),
      delay: _calcCurrentRoundDelay(crewResult, race),
    );
  }

  Color _positionColor(int position) {
    switch (position) {
      case 1: return Colors.amber;
      case 2: return Colors.grey;
      case 3: return Colors.brown;
      default: return Colors.blue;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'FINISHED': return Colors.green;
      case 'DNS': return Colors.orange;
      case 'DNF': return Colors.red;
      case 'DSQ': return Colors.purple;
      case null: return Colors.blue;
      default: return Colors.grey;
    }
  }

  Color _statusColorTotal(String? status) {
    switch (status) {
      case 'FINISHED': return Colors.green.shade700;
      case 'DNS': return Colors.orange.shade700;
      case 'DNF': return Colors.red.shade700;
      case 'DSQ': return Colors.purple.shade700;
      case null: return Colors.blue.shade700;
      default: return Colors.grey.shade700;
    }
  }

  String _calcCurrentRoundDelay(CrewResult crewResult, RaceResult race) {
    final pos = crewResult.position;
    if (pos == null || pos == 1 || crewResult.timeMs == null) return '';
    final firstMs = race.crewResults
        ?.where((c) => c.position == 1 && c.timeMs != null)
        .firstOrNull
        ?.timeMs;
    if (firstMs == null) return '';
    final delaySec = (crewResult.timeMs! - firstMs) / 1000.0;
    return '+${delaySec.toStringAsFixed(2)}s';
  }

  String _calcFinalDelay(CrewResult crewResult, RaceResult race) {
    final pos = crewResult.position;
    if (pos == null || pos == 1) return '';
    final isAcc = _showAccumulated(race);
    int? current;
    int? first;
    if (isAcc && crewResult.finalTimeMs != null) {
      current = crewResult.finalTimeMs;
      first = race.crewResults
          ?.where((c) => c.position == 1 && c.finalTimeMs != null)
          .firstOrNull
          ?.finalTimeMs;
    } else if (crewResult.timeMs != null) {
      current = crewResult.timeMs;
      first = race.crewResults
          ?.where((c) => c.position == 1 && c.timeMs != null)
          .firstOrNull
          ?.timeMs;
    }
    if (current == null || first == null) return '';
    final delaySec = (current - first) / 1000.0;
    return '+${delaySec.toStringAsFixed(2)}s';
  }

  /// Renders the discipline as a row of colored word-badges:
  /// [Boat] [Age] [Gender] [Distance]. Each word gets its category colour
  /// from the event's color_map (or the default palette).
  Widget _disciplineBadges(RaceResult race) {
    final d = race.discipline;
    final cm = widget.config.colorMap;
    final tokens = <MapEntry<String, String>>[];
    if ((d?.boatGroup ?? '').isNotEmpty) {
      tokens.add(MapEntry('boat', d!.boatGroup!));
    }
    if ((d?.ageGroup ?? '').isNotEmpty) {
      tokens.add(MapEntry('age', d!.ageGroup!));
    }
    if ((d?.genderGroup ?? '').isNotEmpty) {
      tokens.add(MapEntry('gender', d!.genderGroup!));
    }
    if (d?.distance != null) {
      tokens.add(MapEntry('distance', '${d!.distance}m'));
    }
    final competition = d?.competition;
    if (tokens.isEmpty && (competition == null || competition.isEmpty)) {
      return const Text(
        'Unknown',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final t in tokens) _wordBadge(cm, t.key, t.value),
        if (competition != null && competition.isNotEmpty) ...[
          const SizedBox(width: 2),
          _competitionBadge(competition),
        ],
      ],
    );
  }

  Widget _stageBadge(String? stage) {
    if (stage == null || stage.isEmpty) return const SizedBox.shrink();
    return _wordBadge(widget.config.colorMap, 'stage', stage, displayValue: stage);
  }

  /// Renders a single colored word-badge. The colour comes from the
  /// resolved category palette; the displayed text is the raw value
  /// (or `displayValue` if the lookup key needs to be normalized — e.g.
  /// "Round 1" displayed but looked up as "Round").
  Widget _wordBadge(
    Map<String, Map<String, String>> colorMap,
    String category,
    String value, {
    String? displayValue,
  }) {
    final lookupKey = category == 'stage'
        ? RaceColorPalette.stageType(value)
        : value;
    final bg = RaceColorPalette.resolve(colorMap, category, lookupKey);
    final fg = bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayValue ?? value,
        softWrap: false,
        overflow: TextOverflow.clip,
        maxLines: 1,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _competitionBadge(String competition) {
    final color = competitionBadgeColor(competition);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border.all(color: color.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        competition,
        softWrap: false,
        overflow: TextOverflow.clip,
        maxLines: 1,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color.shade700),
      ),
    );
  }

  // --- Break entries (lunch, ceremonies, etc.) ---

  Widget _breakCard(RaceResult brk) {
    // Distinct palette per mode: amber for shift (changes the schedule),
    // slate-grey for parallel (informational only).
    final isShift = brk.shiftSubsequent;
    final headerColor = isShift ? const Color(0xFFD97706) : const Color(0xFF6B7280);
    final duration = brk.durationSeconds ?? 0;
    final durationLabel = _formatDuration(duration);
    final modeLabel = isShift ? 'shifts later races' : 'parallel';
    final icon = isShift ? Icons.coffee : Icons.celebration;

    // Wrap in Column with the same trailing dividers as race cards so spacing
    // between consecutive grid rows is consistent.
    return Column(children: [
      Container(
        color: headerColor,
        child: ListTile(
          leading: Icon(icon, color: Colors.white, size: 24),
          title: Row(children: [
            Text(
              brk.raceTime == null ? '—' : _formatTimeOnly(brk.raceTime!),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                brk.label ?? brk.stage ?? 'Break',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ]),
          subtitle: Text(
            '$durationLabel  ·  $modeLabel',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            CompactIcon(
              Icons.edit,
              tooltip: 'Edit break',
              onPressed: () => _editBreak(brk),
              color: Colors.white,
            ),
            CompactIcon(
              Icons.delete_outline,
              tooltip: 'Delete break',
              onPressed: () => _deleteBreak(brk),
              color: Colors.white,
            ),
          ]),
        ),
      ),
      const Divider(height: 4),
      const Divider(height: smallSpace),
    ]);
  }

  /// Pick a source day and ask the backend to reorder this (target) day to
  /// follow the source day's race sequence. Matches by boat+age+gender+stage
  /// (distance ignored), so day 2's 500m races line up with day 1's 200m
  /// races of the same boat/age/gender/stage.
  Future<void> _copyDayOrder(String targetDay, List<String> allDates) async {
    final otherDays = allDates.where((d) => d != targetDay).toList();
    if (otherDays.isEmpty) return;

    String? picked = otherDays.first;
    final source = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Copy race order from another day'),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                'Target: $targetDay',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                'Races on the target day will be re-timed to follow the '
                'source day\'s order, matched by boat+age+gender+stage '
                '(distance ignored).',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: picked,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Source day'),
                items: [
                  for (final d in otherDays)
                    DropdownMenuItem<String>(value: d, child: Text(d)),
                ],
                onChanged: (v) => setSt(() => picked = v),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_vert),
              label: const Text('Apply'),
              onPressed: () => Navigator.pop(ctx, picked),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    await _runWithBusy(() async {
      final stats = await api.copyDayOrder(
        widget.eventId,
        sourceDay: source,
        targetDay: targetDay,
      );
      if (!mounted) return;
      final m = stats['matched'] ?? 0;
      final us = stats['unmatched_source'] ?? 0;
      final ut = stats['unmatched_target'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reordered $m race(s). '
            '$us source-only · $ut target-only (kept).'),
      ));
    });
  }

  Future<void> _exportSchedule() async {
    // Collect distinct dates currently in the grid for the day filter.
    final dates = <String>{};
    for (final r in _races) {
      if (r.raceTime != null) dates.add(_formatDateOnly(r.raceTime!));
    }
    final dateList = dates.toList()..sort();

    final choice = await showDialog<_ExportChoice>(
      context: context,
      builder: (ctx) => _ExportDialog(dates: dateList),
    );
    if (choice == null) return;

    await _runWithBusy(() async {
      final result = await api.exportSchedule(
        widget.eventId,
        format: choice.format,
        day: choice.day,
        includeCrews: choice.includeCrews,
      );
      final bytes = result['bytes'] as Uint8List;
      final filename = result['filename'] as String;
      final contentType = result['contentType'] as String;
      final blob = html.Blob([bytes], contentType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    });
  }

  Future<void> _addBreak() async {
    final draft = await _showBreakDialog();
    if (draft == null) return;
    await _runWithBusy(() async {
      await api.createScheduleBreak(
        widget.eventId,
        time: draft.time,
        durationSeconds: draft.durationSeconds,
        label: draft.label,
        shiftSubsequent: draft.shiftSubsequent,
      );
    });
  }

  Future<void> _editBreak(RaceResult brk) async {
    if (brk.id == null) return;
    final draft = await _showBreakDialog(initial: brk);
    if (draft == null) return;
    await _runWithBusy(() async {
      await api.updateScheduleBreak(
        brk.id!,
        time: draft.time,
        durationSeconds: draft.durationSeconds,
        label: draft.label,
        shiftSubsequent: draft.shiftSubsequent,
      );
    });
  }

  Future<void> _deleteBreak(RaceResult brk) async {
    if (brk.id == null) return;
    final ok = await _confirm(
      'Delete break?',
      brk.shiftSubsequent
          ? '"${brk.label ?? "Break"}" will be removed and later races will move back by ${_formatDuration(brk.durationSeconds ?? 0)}.'
          : '"${brk.label ?? "Break"}" will be removed. Race times are not affected.',
    );
    if (!ok) return;
    await _runWithBusy(() => api.deleteScheduleBreak(brk.id!));
  }

  Future<_BreakDraft?> _showBreakDialog({RaceResult? initial}) async {
    final labelController =
        TextEditingController(text: initial?.label ?? initial?.stage ?? 'Lunch break');
    DateTime time = initial?.raceTime ?? _suggestBreakStart();
    int durationMinutes = ((initial?.durationSeconds ?? 1800) / 60).round();
    bool shiftSubsequent = initial?.shiftSubsequent ?? true;
    final durationController =
        TextEditingController(text: durationMinutes.toString());

    return showDialog<_BreakDraft?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(initial == null ? 'Add break' : 'Edit break'),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  helperText: 'e.g. Lunch break, Medal ceremony',
                ),
              ),
              const SizedBox(height: 12),
              // Shift breaks: date matters (which day the break is on), time
              // does not (slot in the day's block sequence is set by drag and
              // canonicalised by the server recompute). Parallel breaks below
              // get both date and time inputs because they sit at a fixed clock.
              if (shiftSubsequent) ...[
                Row(children: [
                  const Text('Day: '),
                  Text(_formatDateOnly(time)),
                  const Spacer(),
                  CompactIcon(
                    Icons.calendar_today,
                    tooltip: 'Pick day',
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: time,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setLocal(() {
                          time = DateTime(picked.year, picked.month, picked.day,
                              time.hour, time.minute);
                        });
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(children: [
                    Icon(Icons.drag_indicator, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        initial == null
                            ? 'Added at the end of the day — drag it into position on the grid.'
                            : 'Time set by position — drag on the grid to move.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                      ),
                    ),
                  ]),
                ),
              ],
              if (!shiftSubsequent)
                Row(children: [
                  const Text('Start: '),
                  Text(_formatDateTime(time)),
                  const Spacer(),
                  CompactIcon(
                    Icons.access_time,
                    tooltip: 'Pick time',
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(time),
                      );
                      if (picked != null) {
                        setLocal(() {
                          time = DateTime(time.year, time.month, time.day,
                              picked.hour, picked.minute);
                        });
                      }
                    },
                  ),
                  CompactIcon(
                    Icons.calendar_today,
                    tooltip: 'Pick date',
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: time,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setLocal(() {
                          time = DateTime(picked.year, picked.month, picked.day,
                              time.hour, time.minute);
                        });
                      }
                    },
                  ),
                ]),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mode',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.coffee, size: 16),
                    label: Text('Shift races'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.celebration, size: 16),
                    label: Text('Parallel'),
                  ),
                ],
                selected: {shiftSubsequent},
                onSelectionChanged: (sel) =>
                    setLocal(() => shiftSubsequent = sel.first),
              ),
              const SizedBox(height: 6),
              Text(
                shiftSubsequent
                    ? 'Inserting this break pushes later same-day races back by its duration.'
                    : 'Sits alongside racing. Use for medal ceremonies, side events, etc.',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final mins = int.tryParse(durationController.text.trim());
                if (labelController.text.trim().isEmpty || mins == null || mins <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Label and a positive duration are required.')),
                  );
                  return;
                }
                Navigator.pop(
                  ctx,
                  _BreakDraft(
                    time: time,
                    durationSeconds: mins * 60,
                    label: labelController.text.trim(),
                    shiftSubsequent: shiftSubsequent,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Default-start for a new break: end of last race in the current view, else 12:00 today.
  DateTime _suggestBreakStart() {
    final scheduled = _races
        .where((r) => r.raceTime != null && r.status == 'SCHEDULED')
        .toList()
      ..sort((a, b) => a.raceTime!.compareTo(b.raceTime!));
    if (scheduled.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 12, 0);
    }
    final last = scheduled.last.raceTime!;
    return last.add(const Duration(minutes: 15));
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 min';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

}

class _BlockWithDate {
  final ScheduleBlock block;
  final DateTime date;
  const _BlockWithDate({required this.block, required this.date});
}

class _ExportChoice {
  final String format; // 'pdf' | 'xlsx' | 'csv' | 'txt'
  final String? day;   // 'YYYY-MM-DD' or null = all days
  final bool includeCrews;
  const _ExportChoice({
    required this.format,
    this.day,
    this.includeCrews = false,
  });
}

class _ExportDialog extends StatefulWidget {
  final List<String> dates;
  const _ExportDialog({required this.dates});

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String _format = 'csv';
  String? _day; // null = all days
  bool _includeCrews = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export schedule'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: _format,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Format'),
            items: const [
              DropdownMenuItem(value: 'pdf', child: Text('PDF')),
              DropdownMenuItem(value: 'xlsx', child: Text('Excel (XLSX)')),
              DropdownMenuItem(value: 'csv', child: Text('CSV')),
              DropdownMenuItem(value: 'txt', child: Text('Plain text')),
            ],
            onChanged: (v) => setState(() => _format = v ?? 'csv'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _day,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Day'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All days')),
              for (final d in widget.dates)
                DropdownMenuItem<String?>(value: d, child: Text(d)),
            ],
            onChanged: (v) => setState(() => _day = v),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _includeCrews,
            onChanged: (v) => setState(() => _includeCrews = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Include crews (start list)'),
            subtitle: const Text(
              'Off = race plan only. On = lane-by-lane team assignments.',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Download'),
          onPressed: () => Navigator.pop(
            context,
            _ExportChoice(
              format: _format,
              day: _day,
              includeCrews: _includeCrews,
            ),
          ),
        ),
      ],
    );
  }
}

class _BreakDraft {
  final DateTime time;
  final int durationSeconds;
  final String label;
  final bool shiftSubsequent;
  _BreakDraft({
    required this.time,
    required this.durationSeconds,
    required this.label,
    required this.shiftSubsequent,
  });
}
