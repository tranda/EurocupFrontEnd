import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../common.dart';
import '../../../model/race/crew_result.dart';
import '../../../model/race/race_result.dart';
import '../../../model/schedule/crew_seed.dart';
import '../../../model/schedule/schedule_config.dart';
import '../../../widgets/compact_icon.dart';

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

    final moved = rows[oldIndex];

    // Breaks don't participate in race slot-swap. Dragging a break re-times it:
    // the break-update endpoint un-shifts/re-shifts for shift mode and is a
    // no-op (just changes the time) for parallel mode.
    if (moved.isBreak) {
      await _retimeBreakOnDrag(rows, oldIndex, newIndex);
      return;
    }

    // RACES: slot-swap among RACES ONLY. All breaks (shift or parallel) are
    // bystanders on race drag — they keep their times and the race "flows
    // around" them. Breaks are moved by dragging the break itself, which calls
    // the break-update endpoint (handles parallel = no shift, shift = re-balance).
    final raceItems = <RaceResult>[];
    final raceItemRowsIdx = <int>[]; // rows[] index for each raceItem
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].isBreak) continue;
      raceItems.add(rows[i]);
      raceItemRowsIdx.add(i);
    }

    final movedRaceOld = raceItemRowsIdx.indexOf(oldIndex);
    if (movedRaceOld < 0) return; // shouldn't happen — moved is a race here

    // In the post-move rows list, count races up to (but not including) newIndex
    // — that's the moved race's position in raceItems.
    final reorderedRows = List<RaceResult>.from(rows)
      ..removeAt(oldIndex)
      ..insert(newIndex, moved);
    var movedRaceNew = 0;
    for (var i = 0; i < newIndex; i++) {
      if (!reorderedRows[i].isBreak) movedRaceNew++;
    }
    if (movedRaceNew == movedRaceOld) return;

    final lo = movedRaceOld < movedRaceNew ? movedRaceOld : movedRaceNew;
    final hi = movedRaceOld < movedRaceNew ? movedRaceNew : movedRaceOld;

    // Block reorder if any race in the slice isn't SCHEDULED.
    for (var k = lo; k <= hi; k++) {
      if (raceItems[k].status != 'SCHEDULED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot reorder: a race in this range is running or finished.')),
        );
        return;
      }
    }

    // Slot-swap within the race-only slice.
    final slotTimes = [for (var k = lo; k <= hi; k++) raceItems[k].raceTime];
    final reorderedRaces = List<RaceResult>.from(raceItems);
    final movedItem = reorderedRaces.removeAt(movedRaceOld);
    reorderedRaces.insert(movedRaceNew, movedItem);

    final updates = <MapEntry<int, DateTime>>[];
    for (var k = lo; k <= hi; k++) {
      final r = reorderedRaces[k];
      final time = slotTimes[k - lo];
      if (time == null) continue;
      if (r.raceTime == time) continue;
      if (r.id == null) continue;
      updates.add(MapEntry(r.id!, time));
    }

    if (updates.isEmpty) return;
    await _runWithBusy(() => api.reorderRaces(updates));
  }

  /// Set the break's time to the time of the row at its dropped position.
  /// Falls back to (previous row time + 1 min) if dropped at the end.
  Future<void> _retimeBreakOnDrag(List<RaceResult> rows, int oldIndex, int newIndex) async {
    final moved = rows[oldIndex];
    if (moved.id == null) return;

    final reordered = List<RaceResult>.from(rows)
      ..removeAt(oldIndex)
      ..insert(newIndex, moved);

    DateTime? newTime;
    for (var i = newIndex + 1; i < reordered.length; i++) {
      if (reordered[i].raceTime != null) {
        newTime = reordered[i].raceTime;
        break;
      }
    }
    if (newTime == null) {
      for (var i = newIndex - 1; i >= 0; i--) {
        if (reordered[i].raceTime != null) {
          newTime = reordered[i].raceTime!.add(const Duration(minutes: 1));
          break;
        }
      }
    }

    if (newTime == null || newTime == moved.raceTime) return;
    await _runWithBusy(() => api.updateScheduleBreak(moved.id!, time: newTime!));
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
  /// Crews without a seed number get appended after seeded ones.
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

      // Centre-out lane order, e.g. 4 lanes → [3,2,4,1]; 6 → [4,3,5,2,6,1].
      final n = _laneCount;
      final centre = ((n + 1) / 2).ceil();
      final order = <int>[centre];
      for (var d = 1; d < n; d++) {
        final left = centre - d, right = centre + d;
        if (left >= 1) order.add(left);
        if (right <= n) order.add(right);
      }

      // Build assignment payload — empties for unused lanes.
      final assignments = <Map<String, dynamic>>[];
      final used = <int>{};
      for (var i = 0; i < sorted.length && i < order.length; i++) {
        assignments.add({'crew_id': sorted[i].crewId, 'lane': order[i]});
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
        CompactIcon(
          Icons.refresh,
          tooltip: 'Refresh',
          onPressed: _load,
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

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final key in keys) _dateSection(key, groups[key]!),
      ]),
    );
  }

  Widget _dateSection(String dateLabel, List<RaceResult> rows) {
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
            return Row(
              key: ValueKey('race-${race.id}'),
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
          },
          onReorder: (oldIndex, newIndex) => _onReorder(rows, oldIndex, newIndex),
        ),
      ]),
    );
  }

  Widget _raceCard(RaceResult race) {
    if (race.isBreak) return _breakCard(race);
    final raceId = race.id;
    final isExpanded = raceId != null && _expanded.contains(raceId);
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
            child: Row(children: [
              SizedBox(
                width: 38,
                child: Text(
                  '#${race.raceNumber ?? "—"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  race.raceTime == null ? '—' : _formatTimeOnly(race.raceTime!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  race.discipline?.getDisplayName() ?? 'Unknown',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (race.discipline?.competition != null &&
                  race.discipline!.competition!.isNotEmpty) ...[
                const SizedBox(width: 6),
                _competitionBadge(race.discipline!.competition!),
              ],
              const SizedBox(width: 8),
              SizedBox(
                width: 78,
                child: Text(
                  race.stage ?? '',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '$filledLanes/$_laneCount',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              CompactIcon(
                Icons.auto_fix_high,
                tooltip: 'Auto-fill lanes (centre-out by seed)',
                onPressed: () => _autoFillLanes(race),
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
            ]),
          ),
        ),
      ),
      const Divider(height: 1),
      if (isExpanded)
        for (var lane = 1; lane <= _laneCount; lane++)
          _laneRow(race, lane, crewByLane[lane]),
      const Divider(height: smallSpace),
    ]);
  }

  Widget _laneRow(RaceResult race, int lane, CrewResult? crewResult) {
    final teamName = crewResult?.crew?.team?.name ?? crewResult?.team?.name;
    final hasContent = crewResult != null && teamName != null;
    final country = crewResult?.crew?.team?.club?.country;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: ListTile(
        onTap: () => _assignLane(race, lane),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasContent ? Colors.blue.shade50 : Colors.grey.shade100,
            border: Border.all(
              color: hasContent ? Colors.blue.shade300 : Colors.grey.shade300,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '-',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
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
        trailing: hasContent
            ? Container(
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
              )
            : const Icon(Icons.add, size: 18, color: Colors.grey),
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
