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
      final disciplines = await api.getDisciplinesAll(eventId: widget.eventId);
      _progressionByDiscipline.clear();
      _optionsByDiscipline.clear();
      for (final d in disciplines) {
        if (d.id == null) continue;
        try {
          final prog = await api.getDisciplineProgression(d.id!);
          _progressionByDiscipline[d.id!] = prog;
          if (prog.crewCount >= 2 && prog.laneCount != null) {
            _optionsByDiscipline[d.id!] =
                await api.getDisciplineRacePlanOptions(d.id!);
          }
        } catch (_) {
          // Skip per-discipline errors; UI shows "—".
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

  Future<void> _generate() async {
    final ok = await _confirm(
      'Generate Schedule',
      'This deletes all existing scheduled races for this event and rebuilds them. Continue?',
    );
    if (!ok) return;
    setState(() => _generating = true);
    try {
      final result = await api.generateSchedule(widget.eventId);
      setState(() => _lastResult = result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Generated ${result.racesCreated} races · '
            '${result.warnings.length} warning(s)'),
      ));
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
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color.fromARGB(255, 240, 245, 252),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: Color.fromARGB(255, 0, 80, 150)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Generates the full schedule for all disciplines below.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _generating ? null : _generate,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Generate Schedule'),
        ),
      ]),
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _disciplines.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _disciplineRow(_disciplines[i]),
      ),
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
