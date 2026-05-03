import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../model/race/crew_result.dart';
import '../../../model/race/discipline.dart';
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 240, 245, 252)),
          columns: [
            const DataColumn(label: Text('#')),
            const DataColumn(label: Text('Time')),
            const DataColumn(label: Text('Discipline')),
            const DataColumn(label: Text('Stage')),
            for (var lane = 1; lane <= _laneCount; lane++)
              DataColumn(label: Text('L$lane')),
            const DataColumn(label: Text('')),
          ],
          rows: filtered.map(_buildRow).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(RaceResult race) {
    final crewByLane = <int, CrewResult>{};
    for (final cr in race.crewResults ?? <CrewResult>[]) {
      if (cr.lane != null) crewByLane[cr.lane!] = cr;
    }

    return DataRow(cells: [
      DataCell(Text(race.raceNumber?.toString() ?? '—')),
      DataCell(Text(race.raceTime == null ? '—' : _formatTimeOnly(race.raceTime!))),
      DataCell(SizedBox(
        width: 160,
        child: Text(race.discipline?.getDisplayName() ?? '—', overflow: TextOverflow.ellipsis),
      )),
      DataCell(Text(race.stage ?? '—')),
      for (var lane = 1; lane <= _laneCount; lane++)
        DataCell(_laneCell(race, lane, crewByLane[lane])),
      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          tooltip: 'Edit time/stage',
          onPressed: () => _editRace(race),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          tooltip: 'Delete race',
          onPressed: () => _deleteRace(race),
        ),
      ])),
    ]);
  }

  Widget _laneCell(RaceResult race, int lane, CrewResult? crewResult) {
    final teamName = crewResult?.crew?.team?.name ?? crewResult?.team?.name;
    final hasContent = crewResult != null && teamName != null;
    return InkWell(
      onTap: () => _assignLane(race, lane),
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: hasContent
            ? Text(teamName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)
            : const Text('—', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
