import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../model/schedule/event_day.dart';
import '../../../model/schedule/schedule_block.dart';
import '../../../model/schedule/schedule_config.dart';

/// Setup tab: lane count + days + blocks editor.
class SetupTab extends StatefulWidget {
  final int eventId;
  final ScheduleConfig config;
  final Future<void> Function() onChanged;

  const SetupTab({
    super.key,
    required this.eventId,
    required this.config,
    required this.onChanged,
  });

  @override
  State<SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends State<SetupTab> {
  late int _laneCount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _laneCount = widget.config.laneCount;
  }

  @override
  void didUpdateWidget(covariant SetupTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.laneCount != widget.config.laneCount) {
      _laneCount = widget.config.laneCount;
    }
  }

  Future<void> _runWithLoading(Future<void> Function() task) async {
    setState(() => _saving = true);
    try {
      await task();
      await widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveLaneCount(int v) async {
    setState(() => _laneCount = v);
    await _runWithLoading(() => api.updateScheduleConfig(widget.eventId, laneCount: v));
  }

  Future<void> _addDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await _runWithLoading(
      () => api.createEventDay(widget.eventId, date: picked).then((_) {}),
    );
  }

  Future<void> _editDay(EventDay day) async {
    final nameController = TextEditingController(text: day.name ?? '');
    DateTime date = day.date;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit Day'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Date: '),
              Text(date.toIso8601String().substring(0, 10)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setLocal(() => date = picked);
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
    if (result == true) {
      await _runWithLoading(() => api.updateEventDay(
            day.id,
            date: date,
            name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
          ));
    }
  }

  Future<void> _deleteDay(EventDay day) async {
    final ok = await _confirmDelete('Delete day "${day.name ?? day.date.toIso8601String().substring(0, 10)}"? '
        'All blocks under this day will also be deleted.');
    if (ok) await _runWithLoading(() => api.deleteEventDay(day.id));
  }

  Future<void> _addBlock(EventDay day) async {
    final block = await _showBlockDialog();
    if (block == null) return;
    await _runWithLoading(() => api.createScheduleBlock(
          day.id,
          name: block.name,
          startTime: block.startTime,
          gapSeconds: block.gapSeconds,
          genderFilter: block.genderFilter,
          distanceFilter: block.distanceFilter,
          stageFilter: block.stageFilter,
          competitionFilter: block.competitionFilter,
        ).then((_) {}));
  }

  Future<void> _editBlock(ScheduleBlock block) async {
    final updated = await _showBlockDialog(initial: block);
    if (updated == null) return;
    await _runWithLoading(() => api.updateScheduleBlock(
          block.id,
          name: updated.name,
          startTime: updated.startTime,
          gapSeconds: updated.gapSeconds,
          genderFilter: updated.genderFilter,
          distanceFilter: updated.distanceFilter,
          stageFilter: updated.stageFilter,
          competitionFilter: updated.competitionFilter,
        ));
  }

  Future<void> _deleteBlock(ScheduleBlock block) async {
    final ok = await _confirmDelete('Delete block "${block.name}"?');
    if (ok) await _runWithLoading(() => api.deleteScheduleBlock(block.id));
  }

  Future<bool> _confirmDelete(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
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

  Future<_BlockDraft?> _showBlockDialog({ScheduleBlock? initial}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final startTimeController =
        TextEditingController(text: initial?.startTime.substring(0, 5) ?? '09:00');
    final gapController =
        TextEditingController(text: (initial?.gapSeconds ?? 240).toString());
    final genders = <String>{...?initial?.genderFilter};
    final distancesController =
        TextEditingController(text: initial?.distanceFilter?.join(', ') ?? '');
    final stagesController =
        TextEditingController(text: initial?.stageFilter?.join(', ') ?? '');
    final competitionsController =
        TextEditingController(text: initial?.competitionFilter?.join(', ') ?? '');

    return showDialog<_BlockDraft>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(initial == null ? 'Add Block' : 'Edit Block'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(labelText: 'Start time (HH:mm)'),
              ),
              TextField(
                controller: gapController,
                decoration: const InputDecoration(labelText: 'Gap (seconds)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Gender filter (none = any)',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ),
              Wrap(spacing: 6, children: [
                for (final g in ['M', 'W', 'X'])
                  FilterChip(
                    label: Text(g),
                    selected: genders.contains(g),
                    onSelected: (sel) => setLocal(() {
                      sel ? genders.add(g) : genders.remove(g);
                    }),
                  ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: distancesController,
                decoration: const InputDecoration(
                  labelText: 'Distance filter (comma-separated, blank = any)',
                  helperText: 'e.g. 200m, 500m',
                ),
              ),
              TextField(
                controller: stagesController,
                decoration: const InputDecoration(
                  labelText: 'Stage filter (comma-separated, blank = any)',
                  helperText: 'e.g. Heat, Round, Final',
                ),
              ),
              TextField(
                controller: competitionsController,
                decoration: const InputDecoration(
                  labelText: 'Competition filter (comma-separated, blank = any)',
                  helperText: 'e.g. Club, Corporate, Festival, Schools',
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final gap = int.tryParse(gapController.text.trim());
                if (nameController.text.trim().isEmpty || gap == null) return;
                Navigator.pop(
                  ctx,
                  _BlockDraft(
                    name: nameController.text.trim(),
                    startTime: startTimeController.text.trim(),
                    gapSeconds: gap,
                    genderFilter: genders.isEmpty ? null : genders.toList(),
                    distanceFilter: _parseList(distancesController.text),
                    stageFilter: _parseList(stagesController.text),
                    competitionFilter: _parseList(competitionsController.text),
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

  List<String>? _parseList(String raw) {
    final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _laneCountCard(),
          const SizedBox(height: 16),
          ...widget.config.days.map(_dayCard),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _addDay,
            icon: const Icon(Icons.add),
            label: const Text('Add Day'),
          ),
          const SizedBox(height: 80),
        ],
      ),
      if (_saving)
        const Positioned.fill(
          child: ColoredBox(
            color: Color.fromARGB(60, 255, 255, 255),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ]);
  }

  Widget _laneCountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.straighten, color: Color.fromARGB(255, 0, 80, 150)),
          const SizedBox(width: 12),
          const Text('Lane count', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          DropdownButton<int>(
            value: _laneCount,
            items: [
              for (final n in const [3, 4, 6, 8, 9])
                DropdownMenuItem(
                  value: n,
                  child: Text(
                    '$n lanes${(n == 4 || n == 6 || n == 8) ? "" : " (no IDBF plan)"}',
                  ),
                ),
            ],
            onChanged: _saving ? null : (v) {
              if (v != null) _saveLaneCount(v);
            },
          ),
        ]),
      ),
    );
  }

  Widget _dayCard(EventDay day) {
    final dateStr = day.date.toIso8601String().substring(0, 10);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.event, color: Color.fromARGB(255, 0, 80, 150)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                day.name?.isNotEmpty == true ? '${day.name} · $dateStr' : dateStr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _editDay(day)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteDay(day),
            ),
          ]),
          const Divider(),
          if (day.blocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No blocks yet.', style: TextStyle(color: Colors.grey)),
            ),
          ...day.blocks.map(_blockTile),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _addBlock(day),
              icon: const Icon(Icons.add),
              label: const Text('Add Block'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _blockTile(ScheduleBlock block) {
    final filterLines = <String>[];
    if (block.genderFilter?.isNotEmpty == true) {
      filterLines.add('Gender: ${block.genderFilter!.join(", ")}');
    }
    if (block.distanceFilter?.isNotEmpty == true) {
      filterLines.add('Distance: ${block.distanceFilter!.join(", ")}');
    }
    if (block.stageFilter?.isNotEmpty == true) {
      filterLines.add('Stage: ${block.stageFilter!.join(", ")}');
    }
    if (block.competitionFilter?.isNotEmpty == true) {
      filterLines.add('Competition: ${block.competitionFilter!.join(", ")}');
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(block.name),
      subtitle: Text(
        '${block.startTime.substring(0, 5)}  ·  every ${block.gapSeconds}s'
        '${filterLines.isEmpty ? "" : "\n${filterLines.join("  ·  ")}"}',
      ),
      isThreeLine: filterLines.isNotEmpty,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.edit), onPressed: () => _editBlock(block)),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteBlock(block),
        ),
      ]),
    );
  }
}

class _BlockDraft {
  final String name;
  final String startTime;
  final int gapSeconds;
  final List<String>? genderFilter;
  final List<String>? distanceFilter;
  final List<String>? stageFilter;
  final List<String>? competitionFilter;
  _BlockDraft({
    required this.name,
    required this.startTime,
    required this.gapSeconds,
    this.genderFilter,
    this.distanceFilter,
    this.stageFilter,
    this.competitionFilter,
  });
}
