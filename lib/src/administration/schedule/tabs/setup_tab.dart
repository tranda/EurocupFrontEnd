import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:flutter/material.dart';

import '../../../model/schedule/event_day.dart';
import '../../../model/schedule/schedule_block.dart';
import '../../../model/schedule/schedule_config.dart';
import '../../../widgets/compact_icon.dart';
import '../../../widgets/page_template.dart';
import '../color_map_editor.dart';

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
  late int _defaultRounds;
  late int _minCrewsPerRace;
  late TextEditingController _hullsSmallCtl;
  late TextEditingController _hullsStandardCtl;
  late TextEditingController _longMaxSmallCtl;
  late TextEditingController _longMaxStandardCtl;
  // Blur-save: onEditingComplete/onSubmitted only fire on Enter (esp. on web),
  // so clicking away or switching tabs would otherwise drop an unsaved edit.
  // These nodes commit the field the moment it loses focus.
  late FocusNode _hullsSmallFocus;
  late FocusNode _hullsStandardFocus;
  late FocusNode _longMaxSmallFocus;
  late FocusNode _longMaxStandardFocus;
  // Last persisted values for the hull/limit fields. These save passively (no
  // full-page reload), so we can't lean on widget.config to dedupe repeat
  // blurs — track what we last wrote and only PUT on a real change.
  late String _savedHullsSmall;
  late String _savedHullsStandard;
  late int _savedLongMaxSmall;
  late int _savedLongMaxStandard;
  bool _saving = false;

  /// Text for a nullable limit: empty when unset/0 (unlimited).
  static String _limitText(int? v) => (v == null || v == 0) ? '' : v.toString();

  @override
  void initState() {
    super.initState();
    _laneCount = widget.config.laneCount;
    _defaultRounds = widget.config.defaultRounds;
    _minCrewsPerRace = widget.config.minCrewsPerRace;
    _hullsSmallCtl = TextEditingController(text: widget.config.hullsSmall);
    _hullsStandardCtl = TextEditingController(text: widget.config.hullsStandard);
    _longMaxSmallCtl = TextEditingController(text: _limitText(widget.config.longRaceMaxSmall));
    _longMaxStandardCtl = TextEditingController(text: _limitText(widget.config.longRaceMaxStandard));
    _savedHullsSmall = widget.config.hullsSmall;
    _savedHullsStandard = widget.config.hullsStandard;
    _savedLongMaxSmall = widget.config.longRaceMaxSmall ?? 0;
    _savedLongMaxStandard = widget.config.longRaceMaxStandard ?? 0;

    // Commit each field on blur (focus loss), not just on Enter.
    _hullsSmallFocus = FocusNode()
      ..addListener(() {
        if (!_hullsSmallFocus.hasFocus) _saveHullsSmall(_hullsSmallCtl.text.trim());
      });
    _hullsStandardFocus = FocusNode()
      ..addListener(() {
        if (!_hullsStandardFocus.hasFocus) _saveHullsStandard(_hullsStandardCtl.text.trim());
      });
    _longMaxSmallFocus = FocusNode()
      ..addListener(() {
        if (!_longMaxSmallFocus.hasFocus) _saveLongMaxSmall(_longMaxSmallCtl.text);
      });
    _longMaxStandardFocus = FocusNode()
      ..addListener(() {
        if (!_longMaxStandardFocus.hasFocus) _saveLongMaxStandard(_longMaxStandardCtl.text);
      });
  }

  @override
  void dispose() {
    _hullsSmallCtl.dispose();
    _hullsStandardCtl.dispose();
    _longMaxSmallCtl.dispose();
    _longMaxStandardCtl.dispose();
    _hullsSmallFocus.dispose();
    _hullsStandardFocus.dispose();
    _longMaxSmallFocus.dispose();
    _longMaxStandardFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SetupTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.laneCount != widget.config.laneCount) {
      _laneCount = widget.config.laneCount;
    }
    if (oldWidget.config.defaultRounds != widget.config.defaultRounds) {
      _defaultRounds = widget.config.defaultRounds;
    }
    if (oldWidget.config.minCrewsPerRace != widget.config.minCrewsPerRace) {
      _minCrewsPerRace = widget.config.minCrewsPerRace;
    }
    if (oldWidget.config.hullsSmall != widget.config.hullsSmall) {
      _hullsSmallCtl.text = widget.config.hullsSmall;
      _savedHullsSmall = widget.config.hullsSmall;
    }
    if (oldWidget.config.hullsStandard != widget.config.hullsStandard) {
      _hullsStandardCtl.text = widget.config.hullsStandard;
      _savedHullsStandard = widget.config.hullsStandard;
    }
    if (oldWidget.config.longRaceMaxSmall != widget.config.longRaceMaxSmall) {
      _longMaxSmallCtl.text = _limitText(widget.config.longRaceMaxSmall);
      _savedLongMaxSmall = widget.config.longRaceMaxSmall ?? 0;
    }
    if (oldWidget.config.longRaceMaxStandard != widget.config.longRaceMaxStandard) {
      _longMaxStandardCtl.text = _limitText(widget.config.longRaceMaxStandard);
      _savedLongMaxStandard = widget.config.longRaceMaxStandard ?? 0;
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

  Future<void> _saveDefaultRounds(int v) async {
    setState(() => _defaultRounds = v);
    await _runWithLoading(() => api.updateScheduleConfig(widget.eventId, defaultRounds: v));
  }

  Future<void> _saveMinCrewsPerRace(int v) async {
    setState(() => _minCrewsPerRace = v);
    await _runWithLoading(() => api.updateScheduleConfig(widget.eventId, minCrewsPerRace: v));
  }

  /// Persist a change without the full-page reload that _runWithLoading does.
  /// Hull/limit settings only affect the next generation, not existing races,
  /// so there's nothing to refetch — just PUT and report failures. Returns true
  /// on success so callers can update their last-saved marker.
  Future<bool> _savePassive(Future<void> Function() task) async {
    try {
      await task();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
      return false;
    }
  }

  Future<void> _saveHullsSmall(String v) async {
    if (v == _savedHullsSmall) return;
    if (await _savePassive(() => api.updateScheduleConfig(widget.eventId, hullsSmall: v))) {
      _savedHullsSmall = v;
    }
  }

  Future<void> _saveHullsStandard(String v) async {
    if (v == _savedHullsStandard) return;
    if (await _savePassive(() => api.updateScheduleConfig(widget.eventId, hullsStandard: v))) {
      _savedHullsStandard = v;
    }
  }

  /// Parse a limit field: blank / non-numeric / negative → 0 (unlimited).
  int _parseLimit(String v) => int.tryParse(v.trim())?.clamp(0, 255) ?? 0;

  Future<void> _saveLongMaxSmall(String v) async {
    final parsed = _parseLimit(v);
    if (parsed == _savedLongMaxSmall) return;
    if (await _savePassive(() => api.updateScheduleConfig(widget.eventId, longRaceMaxSmall: parsed))) {
      _savedLongMaxSmall = parsed;
    }
  }

  Future<void> _saveLongMaxStandard(String v) async {
    final parsed = _parseLimit(v);
    if (parsed == _savedLongMaxStandard) return;
    if (await _savePassive(() => api.updateScheduleConfig(widget.eventId, longRaceMaxStandard: parsed))) {
      _savedLongMaxStandard = parsed;
    }
  }

  Future<void> _saveColorMap(Map<String, Map<String, String>> v) async {
    await _runWithLoading(() => api.updateScheduleConfig(widget.eventId, colorMap: v));
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
              CompactIcon(
                Icons.calendar_today,
                tooltip: 'Pick date',
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

  Future<void> _copyBlocksFrom(EventDay targetDay) async {
    final otherDays = widget.config.days
        .where((d) => d.id != targetDay.id)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (otherDays.isEmpty) return;

    final source = await showDialog<EventDay>(
      context: context,
      builder: (ctx) {
        EventDay? picked = otherDays.first;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('Copy blocks from another day'),
            content: SizedBox(
              width: 360,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Target: ${targetDay.date.toIso8601String().substring(0, 10)}'
                  '${(targetDay.name ?? "").isEmpty ? "" : " (${targetDay.name})"}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Existing blocks on the target day will be REPLACED.',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EventDay>(
                  value: picked,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Source day'),
                  items: [
                    for (final d in otherDays)
                      DropdownMenuItem<EventDay>(
                        value: d,
                        child: Text(
                          '${d.date.toIso8601String().substring(0, 10)}'
                          '${(d.name ?? "").isEmpty ? "" : " — ${d.name}"}'
                          ' (${d.blocks.length} block${d.blocks.length == 1 ? "" : "s"})',
                        ),
                      ),
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
                icon: const Icon(Icons.content_copy),
                label: const Text('Copy'),
                onPressed: () => Navigator.pop(ctx, picked),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    await _runWithLoading(() async {
      final copied = await api.copyBlocksFromDay(targetDay.id, source.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Copied $copied block(s) from '
            '${source.date.toIso8601String().substring(0, 10)} to '
            '${targetDay.date.toIso8601String().substring(0, 10)}.'),
      ));
    });
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
    final gapController = TextEditingController(
        text: _formatGapMinutes(initial?.gapSeconds ?? 240));
    // Normalize legacy short codes (M/W/X) to canonical long form so the
    // dialog selects the right chips and saving cleans up old values.
    const genderMap = {'M': 'Open', 'W': 'Women', 'X': 'Mixed'};
    const validGenders = {'Open', 'Women', 'Mixed'};
    final genders = <String>{
      for (final g in initial?.genderFilter ?? const <String>[])
        if (validGenders.contains(genderMap[g] ?? g)) (genderMap[g] ?? g),
    };
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
                decoration: const InputDecoration(labelText: 'Gap (minutes)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Gender filter (none = any)',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ),
              Wrap(spacing: 6, children: [
                for (final g in const ['Open', 'Women', 'Mixed'])
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
                final gapMinutes = double.tryParse(gapController.text.trim());
                if (nameController.text.trim().isEmpty || gapMinutes == null) return;
                final gap = (gapMinutes * 60).round();
                Navigator.pop(
                  ctx,
                  _BlockDraft(
                    name: nameController.text.trim(),
                    startTime: startTimeController.text.trim(),
                    gapSeconds: gap,
                    genderFilter: genders.toList(),
                    distanceFilter: _parseListOrEmpty(distancesController.text),
                    stageFilter: _parseListOrEmpty(stagesController.text),
                    competitionFilter: _parseListOrEmpty(competitionsController.text),
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

  List<String> _parseListOrEmpty(String raw) {
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String _formatGapMinutes(int seconds) {
    final minutes = seconds / 60.0;
    if (minutes == minutes.truncateToDouble()) {
      return minutes.toInt().toString();
    }
    return minutes.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.config.days.toList()..sort((a, b) => a.date.compareTo(b.date));
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Boats: lane count + fleet hulls + long-distance limit
          ColoredPageHeader(
            title: 'Boats',
            subtitle: 'Lanes, fleet hulls and long-distance limits',
            eventId: widget.eventId,
          ),
          _section([
            _laneCountField(),
            _hint('Fleet (hull letters): comma list per boat group, e.g. "D,E,F". '
                'Empty = no rotation. Placement respects turnaround = fleet size × gap.'),
            _fleetFields(),
            _hint('Long-distance team limit (>1000m): max teams (boats) per '
                'long-distance race, per boat group. Blank or 0 = unlimited (one '
                'Final). Above the limit the field splits into balanced flights '
                '("Final 1", "Final 2", …).'),
            _longDistanceFields(),
          ]),
          pageSectionGap,

          // Plan rules: rounds + min crews per race
          ColoredPageHeader(
            title: 'Plan rules',
            subtitle: 'Rounds and minimum crews per race',
            eventId: widget.eventId,
          ),
          _section([
            _defaultRoundsField(),
            _hint('Rounds are applied when registered crews ≤ lanes (no heats / semis needed).'),
            _minCrewsPerRaceField(),
            _hint('Disciplines with fewer crews than this are auto-marked inactive '
                'after every registration import.'),
          ]),
          pageSectionGap,

          // Race row colours (ColorMapEditor draws its own Card; flatten it
          // so it sits on the page background like the other sections).
          ColoredPageHeader(title: 'Race row colours', eventId: widget.eventId),
          Theme(
            data: Theme.of(context).copyWith(
              cardTheme: const CardThemeData(
                color: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(),
              ),
            ),
            child: ColorMapEditor(
              value: widget.config.colorMap,
              onChanged: _saveColorMap,
              enabled: !_saving,
            ),
          ),
          pageSectionGap,

          // Days and blocks
          ColoredPageHeader(
            title: 'Days and blocks',
            subtitle: 'Race days and their time blocks',
            eventId: widget.eventId,
          ),
          if (days.isEmpty)
            _section([_hint('No days yet. Add a day to start defining blocks.')]),
          for (final day in days) ...[
            _dayHeader(day),
            _dayBlocks(day),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _addDay,
                icon: const Icon(Icons.add),
                label: const Text('Add Day'),
              ),
            ),
          ),
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

  /// Fields under a section bar: h16/v12 padding, 12px between fields.
  Widget _section(List<Widget> fields) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            fields[i],
          ],
        ],
      ),
    );
  }

  /// Small grey explanatory text under a section bar.
  Widget _hint(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54));
  }

  /// Outlined dropdown matching pageFieldDecoration.
  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return InputDecorator(
      decoration: pageFieldDecoration(label).copyWith(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _laneCountField() {
    return _dropdownField<int>(
      label: 'Lane count',
      value: _laneCount,
      items: [
        for (final n in const [3, 4, 5, 6, 8, 9])
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
    );
  }

  Widget _fleetFields() {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _hullsSmallCtl,
          focusNode: _hullsSmallFocus,
          enabled: !_saving,
          decoration: pageFieldDecoration('Small hulls').copyWith(hintText: 'D,E,F'),
          textInputAction: TextInputAction.next,
          onEditingComplete: () => _saveHullsSmall(_hullsSmallCtl.text.trim()),
          onSubmitted: (v) => _saveHullsSmall(v.trim()),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: _hullsStandardCtl,
          focusNode: _hullsStandardFocus,
          enabled: !_saving,
          decoration: pageFieldDecoration('Standard hulls').copyWith(hintText: 'A,B,C'),
          textInputAction: TextInputAction.done,
          onEditingComplete: () => _saveHullsStandard(_hullsStandardCtl.text.trim()),
          onSubmitted: (v) => _saveHullsStandard(v.trim()),
        ),
      ),
    ]);
  }

  Widget _longDistanceFields() {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _longMaxSmallCtl,
          focusNode: _longMaxSmallFocus,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          decoration: pageFieldDecoration('Small max teams').copyWith(hintText: 'unlimited'),
          textInputAction: TextInputAction.next,
          onEditingComplete: () => _saveLongMaxSmall(_longMaxSmallCtl.text),
          onSubmitted: (v) => _saveLongMaxSmall(v),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: _longMaxStandardCtl,
          focusNode: _longMaxStandardFocus,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          decoration: pageFieldDecoration('Standard max teams').copyWith(hintText: 'unlimited'),
          textInputAction: TextInputAction.done,
          onEditingComplete: () => _saveLongMaxStandard(_longMaxStandardCtl.text),
          onSubmitted: (v) => _saveLongMaxStandard(v),
        ),
      ),
    ]);
  }

  Widget _defaultRoundsField() {
    return _dropdownField<int>(
      label: 'Rounds',
      value: _defaultRounds,
      items: [
        for (final n in const [1, 2, 3, 4, 5, 6])
          DropdownMenuItem(value: n, child: Text('$n round${n == 1 ? "" : "s"}')),
      ],
      onChanged: _saving ? null : (v) {
        if (v != null) _saveDefaultRounds(v);
      },
    );
  }

  Widget _minCrewsPerRaceField() {
    return _dropdownField<int>(
      label: 'Min crews per race',
      value: _minCrewsPerRace,
      items: [
        for (final n in const [1, 2, 3, 4, 5, 6, 7, 8])
          DropdownMenuItem(value: n, child: Text('$n crew${n == 1 ? "" : "s"}')),
      ],
      onChanged: _saving ? null : (v) {
        if (v != null) _saveMinCrewsPerRace(v);
      },
    );
  }

  Widget _dayHeader(EventDay day) {
    final dateStr = day.date.toIso8601String().substring(0, 10);
    final hasName = day.name?.isNotEmpty == true;
    return ColoredPageHeader(
      title: hasName ? day.name! : dateStr,
      subtitle: hasName ? dateStr : null,
      eventId: widget.eventId,
      leading: const Icon(Icons.event, color: Colors.white),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.config.days.length > 1)
          CompactIcon(
            Icons.content_copy,
            tooltip: 'Copy blocks from another day',
            onPressed: () => _copyBlocksFrom(day),
            color: Colors.white,
          ),
        CompactIcon(
          Icons.edit,
          tooltip: 'Edit day',
          onPressed: () => _editDay(day),
          color: Colors.white,
        ),
        CompactIcon(
          Icons.delete_outline,
          tooltip: 'Delete day',
          onPressed: () => _deleteDay(day),
          color: Colors.white,
        ),
      ]),
    );
  }

  Widget _dayBlocks(EventDay day) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (day.blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No blocks yet.', style: TextStyle(color: Colors.grey)),
          ),
        for (int i = 0; i < day.blocks.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _blockTile(day.blocks[i]),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _addBlock(day),
            icon: const Icon(Icons.add),
            label: const Text('Add Block'),
          ),
        ),
      ]),
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
        '${block.startTime.substring(0, 5)}  ·  every ${_formatGapMinutes(block.gapSeconds)} min'
        '${filterLines.isEmpty ? "" : "\n${filterLines.join("  ·  ")}"}',
      ),
      isThreeLine: filterLines.isNotEmpty,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        CompactIcon(
          Icons.edit,
          tooltip: 'Edit block',
          onPressed: () => _editBlock(block),
        ),
        CompactIcon(
          Icons.delete_outline,
          tooltip: 'Delete block',
          onPressed: () => _deleteBlock(block),
          color: Colors.red,
        ),
      ]),
    );
  }
}

class _BlockDraft {
  final String name;
  final String startTime;
  final int gapSeconds;
  final List<String> genderFilter;
  final List<String> distanceFilter;
  final List<String> stageFilter;
  final List<String> competitionFilter;
  _BlockDraft({
    required this.name,
    required this.startTime,
    required this.gapSeconds,
    this.genderFilter = const [],
    this.distanceFilter = const [],
    this.stageFilter = const [],
    this.competitionFilter = const [],
  });
}
