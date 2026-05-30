import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../common.dart';
import '../../../model/schedule/crew_seed.dart';
import '../../../model/schedule/discipline_progression.dart';
import '../../../model/schedule/generation_result.dart';
import '../../../widgets/compact_icon.dart';

/// Per-discipline race plan override + crew seeds editor.
class PlanAndSeedsTab extends StatefulWidget {
  final int eventId;

  const PlanAndSeedsTab({super.key, required this.eventId});

  @override
  State<PlanAndSeedsTab> createState() => _PlanAndSeedsTabState();
}

class _PlanAndSeedsTabState extends State<PlanAndSeedsTab> {
  bool _loading = true;
  bool _generating = false;
  String? _error;
  List<Discipline> _disciplines = [];
  final Map<int, DisciplineProgressionInfo> _progressionByDiscipline = {};
  final Map<int, List<String>> _optionsByDiscipline = {};
  /// disciplineId → 'YYYY-MM-DD' the discipline's races land on (predicted
  /// from block filter matches). Null = no matching block.
  final Map<int, String?> _dayByDiscipline = {};
  GenerationResult? _lastResult;

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
      // Single bulk call — returns active disciplines + their progression
      // + race-plan options in one payload. Replaces the previous 2N+1
      // chatty pattern.
      final rows = await api.getPlanAndSeedsBulk(widget.eventId);
      _progressionByDiscipline.clear();
      _optionsByDiscipline.clear();
      _dayByDiscipline.clear();
      final disciplines = <Discipline>[];
      for (final row in rows) {
        disciplines.add(row.discipline);
        final id = row.discipline.id;
        if (id == null) continue;
        _progressionByDiscipline[id] = row.progression;
        _dayByDiscipline[id] = row.predictedDay;
        if (row.options.isNotEmpty) {
          _optionsByDiscipline[id] = row.options;
        }
      }
      setState(() {
        _disciplines = disciplines;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generate({bool clean = false, String? day}) async {
    final scope = day == null ? 'whole event' : 'day $day';
    final ok = await _confirm(
      clean ? 'Clean Generate' : 'Generate Schedule',
      clean
          ? 'Wipe ALL existing races for $scope AND ignore any manual '
              'drag-reorders — rebuild from scratch using block filters '
              'and IDBF seeding. Continue?'
          : 'Rebuild races for $scope, preserving manual drag-reorders '
              'where stages still match. Continue?',
    );
    if (!ok) return;
    setState(() => _generating = true);
    try {
      final result = await api.generateSchedule(
        widget.eventId,
        clean: clean,
        day: day,
      );
      setState(() => _lastResult = result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${clean ? "Clean-generated" : "Generated"} '
            '${result.racesCreated} races${day == null ? "" : " for $day"} · '
            '${result.warnings.length} warning(s)'),
      ));
      await _load(); // refresh predicted-day grouping in case blocks changed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _regenerate(int disciplineId) async {
    final ok = await _confirm(
      'Regenerate Discipline',
      'Replace all scheduled races for this discipline?',
    );
    if (!ok) return;
    setState(() => _generating = true);
    try {
      final result = await api.regenerateDisciplineSchedule(disciplineId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Regenerated · ${result.warnings.length} warning(s)'),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _seedNextRound(int disciplineId) async {
    setState(() => _generating = true);
    try {
      final result = await api.seedNextRound(disciplineId);
      if (!mounted) return;
      final msg = result.crewLanesAssigned > 0
          ? 'Seeded ${result.crewLanesAssigned} lanes'
          : (result.warnings.isNotEmpty ? result.warnings.first : 'Nothing to seed');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
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
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _changePlan(int disciplineId, String? newCode) async {
    try {
      if (newCode == 'CUSTOM') {
        final existing = _progressionByDiscipline[disciplineId]?.customStages ?? const [];
        final stages = await _editCustomStages(existing);
        if (stages == null) return; // cancelled — don't change anything
        await api.updateDisciplineProgression(disciplineId, 'CUSTOM', customStages: stages);
      } else {
        await api.updateDisciplineProgression(disciplineId, newCode);
      }
      final updated = await api.getDisciplineProgression(disciplineId);
      setState(() => _progressionByDiscipline[disciplineId] = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _editCustomStagesFor(int disciplineId) async {
    final existing = _progressionByDiscipline[disciplineId]?.customStages ?? const [];
    final stages = await _editCustomStages(existing);
    if (stages == null) return;
    try {
      await api.updateDisciplineProgression(disciplineId, 'CUSTOM', customStages: stages);
      final updated = await api.getDisciplineProgression(disciplineId);
      setState(() => _progressionByDiscipline[disciplineId] = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<List<String>?> _editCustomStages(List<String> initial) async {
    final controller = TextEditingController(
      text: initial.isEmpty ? 'Round 1\nRound 2\nFinal' : initial.join('\n'),
    );
    final result = await showDialog<List<String>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom stages'),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'One stage per line. The generator creates one race per stage; '
              'lanes stay empty so you assign crews manually in the Grid.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final stages = controller.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (stages.isEmpty) {
                ScaffoldMessenger.of(ctx)
                    .showSnackBar(const SnackBar(content: Text('Add at least one stage.')));
                return;
              }
              Navigator.pop(ctx, stages);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _openSeeds(Discipline d) async {
    if (d.id == null) return;
    try {
      final seeds = await api.getDisciplineCrewSeeds(d.id!);
      if (!mounted) return;
      final updated = await showDialog<List<CrewSeed>?>(
        context: context,
        builder: (ctx) => _SeedsDialog(
          disciplineName: d.getDisplayName(),
          seeds: seeds,
        ),
      );
      if (updated == null) return;
      if (updated.isEmpty) {
        // sentinel for "reset"
        await api.resetDisciplineCrewSeeds(d.id!);
      } else {
        await api.updateDisciplineCrewSeeds(d.id!, updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeds saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

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

    return Stack(children: [
      Column(children: [
        _generatorBar(),
        if (_lastResult != null && _lastResult!.warnings.isNotEmpty) _warningsBanner(),
        const Divider(height: 1),
        Expanded(child: _disciplinesList()),
      ]),
      if (_generating)
        const Positioned.fill(
          child: ColoredBox(
            color: Color.fromARGB(60, 255, 255, 255),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ]);
  }

  Widget _generatorBar() {
    final cleanBtn = OutlinedButton.icon(
      onPressed: _generating ? null : () => _generate(clean: true),
      icon: const Icon(Icons.cleaning_services, color: Colors.red),
      label: const Text(
        'Clean Generate',
        style: TextStyle(color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.red.shade300),
      ),
    );
    final mainBtn = ElevatedButton.icon(
      onPressed: _generating ? null : _generate,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Generate Schedule'),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color.fromARGB(255, 240, 245, 252),
      child: LayoutBuilder(builder: (ctx, constraints) {
        // Below ~640px the buttons stack under the description so the text
        // doesn't get squeezed into a vertical character column on phones.
        final narrow = constraints.maxWidth < 640;
        if (narrow) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: const [
              Icon(Icons.auto_awesome, color: Color.fromARGB(255, 0, 80, 150)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Generates the full schedule for all disciplines below.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [cleanBtn, mainBtn],
            ),
          ]);
        }
        return Row(children: [
          const Icon(Icons.auto_awesome, color: Color.fromARGB(255, 0, 80, 150)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Generates the full schedule for all disciplines below.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          cleanBtn,
          const SizedBox(width: 8),
          mainBtn,
        ]);
      }),
    );
  }

  Widget _warningsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade50,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            '${_lastResult!.warnings.length} warning(s)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ]),
        const SizedBox(height: 8),
        ..._lastResult!.warnings.take(8).map((w) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text('• $w', style: const TextStyle(fontSize: 12)),
            )),
        if (_lastResult!.warnings.length > 8)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 4),
            child: Text(
              '… and ${_lastResult!.warnings.length - 8} more.',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
      ]),
    );
  }

  Widget _disciplinesList() {
    if (_disciplines.isEmpty) {
      return const Center(child: Text('No disciplines for this event.'));
    }

    // Group disciplines by predicted day. Within a day, keep original order.
    // Unscheduled (no matching block) go last under a "— unscheduled —" header.
    const noDay = '__no_day__';
    final byDay = <String, List<Discipline>>{};
    for (final d in _disciplines) {
      final day = (_dayByDiscipline[d.id] ?? noDay).toString();
      byDay.putIfAbsent(day, () => []).add(d);
    }
    final orderedKeys = byDay.keys.toList()
      ..sort((a, b) {
        if (a == noDay) return 1;
        if (b == noDay) return -1;
        return a.compareTo(b);
      });

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: orderedKeys.length,
        itemBuilder: (_, dayIdx) {
          final key = orderedKeys[dayIdx];
          final disciplinesInDay = byDay[key]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dayHeader(key, disciplinesInDay.length, isUnscheduled: key == noDay),
              for (var i = 0; i < disciplinesInDay.length; i++) ...[
                _disciplineRow(disciplinesInDay[i]),
                if (i < disciplinesInDay.length - 1) const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _dayHeader(String day, int count, {bool isUnscheduled = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isUnscheduled
          ? const Color(0xFF6B7280)
          : const Color.fromARGB(255, 0, 80, 150),
      child: Row(children: [
        Icon(
          isUnscheduled ? Icons.help_outline : Icons.event,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          isUnscheduled ? 'Unscheduled (no matching block)' : day,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '· $count discipline${count == 1 ? "" : "s"}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Spacer(),
        if (!isUnscheduled) ...[
          TextButton.icon(
            onPressed: _generating ? null : () => _generate(day: day),
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
            label: const Text(
              'Generate day',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ]),
    );
  }

  Widget _competitionBadge(String competition) {
    final color = competitionBadgeColor(competition);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border.all(color: color.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        competition,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.shade700),
      ),
    );
  }

  Widget _disciplineRow(Discipline d) {
    final prog = d.id == null ? null : _progressionByDiscipline[d.id];
    final options = d.id == null ? null : _optionsByDiscipline[d.id];
    final crewCount = prog?.crewCount ?? d.teamsCount ?? 0;
    final effective = prog?.effectiveCode ?? '—';
    final isOverride = prog?.overrideCode != null;
    final headerColor = competitionColor[0];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        color: headerColor,
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(
                    d.getDisplayName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (d.competition != null && d.competition!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _competitionBadge(d.competition!),
                ],
              ]),
              Text(
                '$crewCount crews',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ]),
          ),
          if (prog?.overrideCode == 'CUSTOM')
            CompactIcon(
              Icons.edit_note,
              tooltip: 'Edit custom stages',
              onPressed: d.id == null ? null : () => _editCustomStagesFor(d.id!),
              color: Colors.white,
            ),
          CompactIcon(
            Icons.format_list_numbered,
            tooltip: 'Edit seeds',
            onPressed: d.id == null ? null : () => _openSeeds(d),
            color: Colors.white,
          ),
          CompactIcon(
            Icons.fast_forward,
            tooltip: 'Seed next round (after prior round results entered)',
            onPressed: d.id == null ? null : () => _seedNextRound(d.id!),
            color: Colors.white,
          ),
          CompactIcon(
            Icons.refresh,
            tooltip: 'Regenerate this discipline',
            onPressed: d.id == null ? null : () => _regenerate(d.id!),
            color: Colors.white,
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text(
              'Plan: ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Expanded(
              child: (options == null || options.isEmpty)
                  ? Text(effective, style: const TextStyle(fontWeight: FontWeight.w600))
                  : DropdownButton<String?>(
                      isExpanded: true,
                      value: prog?.overrideCode,
                      hint: Text('Auto: ${prog?.autoPickCode ?? "—"}'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— Auto —')),
                        ...options.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c == prog?.autoPickCode ? '$c (auto)' : c),
                            )),
                      ],
                      onChanged: (v) => _changePlan(d.id!, v),
                    ),
            ),
            if (isOverride)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('overridden',
                    style: TextStyle(fontSize: 10, color: Colors.orange)),
              ),
          ]),
          if (prog?.overrideCode == 'CUSTOM' && (prog?.customStages?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Stages: ${prog!.customStages!.join(", ")}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ]),
      ),
    ]);
  }
}

class _SeedsDialog extends StatefulWidget {
  final String disciplineName;
  final List<CrewSeed> seeds;

  const _SeedsDialog({required this.disciplineName, required this.seeds});

  @override
  State<_SeedsDialog> createState() => _SeedsDialogState();
}

class _SeedsDialogState extends State<_SeedsDialog> {
  late List<CrewSeed> _seeds;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _seeds = widget.seeds.map((s) => CrewSeed(
          crewId: s.crewId,
          teamId: s.teamId,
          teamName: s.teamName,
          seedNumber: s.seedNumber,
        )).toList();
    _controllers = _seeds
        .map((s) => TextEditingController(text: s.seedNumber?.toString() ?? ''))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final n = _seeds.length;
    final assigned = <int>{};
    for (var i = 0; i < n; i++) {
      final raw = _controllers[i].text.trim();
      if (raw.isEmpty) {
        _seeds[i].seedNumber = null;
        continue;
      }
      final v = int.tryParse(raw);
      if (v == null || v < 1 || v > n) {
        _showSnack('Seed for ${_seeds[i].teamName} must be 1..$n');
        return;
      }
      if (!assigned.add(v)) {
        _showSnack('Seed $v is used more than once');
        return;
      }
      _seeds[i].seedNumber = v;
    }
    Navigator.pop(context, _seeds);
  }

  void _reset() {
    Navigator.pop(context, <CrewSeed>[]); // empty list = reset sentinel
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Seeds — ${widget.disciplineName}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(children: [
            const Text(
              '1 = top seed → centre lanes per IDBF. Empty = auto-fill on generate.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _seeds.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text(_seeds[i].teamName ?? 'Crew ${_seeds[i].crewId}')),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _controllers[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true, hintText: '—'),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: const Text('Reset (random)')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
