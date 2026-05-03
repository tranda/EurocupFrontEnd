import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../common.dart';
import '../../../model/race/crew_result.dart';
import '../../../model/race/race_result.dart';
import '../../../model/schedule/crew_seed.dart';
import '../../../model/schedule/schedule_config.dart';

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
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
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
        for (final r in rows) _raceCard(r),
      ]),
    );
  }

  Widget _raceCard(RaceResult race) {
    final raceId = race.id;
    final isExpanded = raceId != null && _expanded.contains(raceId);
    final crewByLane = <int, CrewResult>{};
    for (final cr in race.crewResults ?? <CrewResult>[]) {
      if (cr.lane != null) crewByLane[cr.lane!] = cr;
    }
    final filledLanes = crewByLane.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(children: [
        InkWell(
          onTap: raceId == null ? null : () => setState(() {
            if (isExpanded) {
              _expanded.remove(raceId);
            } else {
              _expanded.add(raceId);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#${race.raceNumber ?? "—"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  race.raceTime == null ? '—' : _formatTimeOnly(race.raceTime!),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Row(children: [
                  Flexible(
                    child: Text(
                      race.discipline?.getDisplayName() ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (race.discipline?.competition != null &&
                      race.discipline!.competition!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _competitionBadge(race.discipline!.competition!),
                  ],
                ]),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  race.stage ?? '—',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$filledLanes/$_laneCount',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              _compactIcon(
                Icons.auto_fix_high,
                tooltip: 'Auto-fill lanes (centre-out by seed)',
                onPressed: () => _autoFillLanes(race),
              ),
              _compactIcon(
                Icons.edit,
                tooltip: 'Edit time/stage',
                onPressed: () => _editRace(race),
              ),
              _compactIcon(
                Icons.delete_outline,
                tooltip: 'Delete race',
                color: Colors.red,
                onPressed: () => _deleteRace(race),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ]),
          ),
        ),
        if (isExpanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                TextButton.icon(
                  onPressed: () => _autoFillLanes(race),
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Auto-fill lanes'),
                ),
                const Spacer(),
              ]),
              for (var lane = 1; lane <= _laneCount; lane++)
                _laneRow(race, lane, crewByLane[lane]),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _laneRow(RaceResult race, int lane, CrewResult? crewResult) {
    final teamName = crewResult?.crew?.team?.name ?? crewResult?.team?.name;
    final hasContent = crewResult != null && teamName != null;
    return InkWell(
      onTap: () => _assignLane(race, lane),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(children: [
          Container(
            width: 36,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasContent
                  ? const Color.fromARGB(255, 0, 80, 150)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'L$lane',
              style: TextStyle(
                color: hasContent ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasContent ? teamName : '— empty —',
              style: TextStyle(
                color: hasContent ? Colors.black87 : Colors.grey,
                fontStyle: hasContent ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          const Icon(Icons.edit, size: 14, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _compactIcon(
    IconData icon, {
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? Colors.black54),
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
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color.shade700),
      ),
    );
  }

}
