import 'package:flutter/material.dart';

import '../../api_helper.dart' as api;

/// Dry-run preview of a schedule regenerate. The operator sees races
/// grouped by day exactly as they'd be committed, then chooses Apply
/// (fires the real generate) or Cancel (dismisses, nothing happens).
///
/// Nothing is written during preview — the backend runs the placement
/// pass inside a rolled-back transaction, including the auto-snapshot
/// row, so opening this dialog is completely side-effect-free.
class SchedulePreviewDialog extends StatelessWidget {
  final api.SchedulePreview preview;

  const SchedulePreviewDialog({super.key, required this.preview});

  /// Returns true when the operator confirmed Apply.
  static Future<bool> show(BuildContext context, api.SchedulePreview p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => SchedulePreviewDialog(preview: p),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final r = preview.result;
    return AlertDialog(
      title: const Text('Preview: proposed schedule'),
      content: SizedBox(
        width: 720,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(context),
            const SizedBox(height: 8),
            if (r.warnings.isNotEmpty) ...[
              const Text('Warnings',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...r.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('· $w',
                        style: TextStyle(
                            color: Colors.amber.shade900, fontSize: 12)),
                  )),
              const SizedBox(height: 8),
            ],
            const Divider(),
            Expanded(child: _daysList()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _summaryRow(BuildContext context) {
    final r = preview.result;
    final total = preview.totalRaces;
    return Row(children: [
      _chip('${r.racesCreated} created', Colors.blue),
      const SizedBox(width: 6),
      _chip('$total on grid', Colors.teal),
      const SizedBox(width: 6),
      if (r.crewLanesAssigned > 0)
        _chip('${r.crewLanesAssigned} lanes', Colors.deepPurple),
      const Spacer(),
      const Text('nothing written until Apply',
          style: TextStyle(color: Colors.grey, fontSize: 11)),
    ]);
  }

  Widget _chip(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          border: Border.all(color: c),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
      );

  Widget _daysList() {
    if (preview.days.isEmpty) {
      return const Center(
        child: Text('No races in preview.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      children: [
        for (final d in preview.days) _dayCard(d),
      ],
    );
  }

  Widget _dayCard(api.PreviewDay d) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(d.day,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${d.races.length} entries',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
            const Divider(height: 8),
            if (d.races.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('(empty)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            else
              for (final r in d.races) _raceLine(r),
          ],
        ),
      ),
    );
  }

  Widget _raceLine(api.PreviewRace r) {
    if (r.isBreak) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          const Icon(Icons.free_breakfast, size: 14, color: Colors.amber),
          const SizedBox(width: 6),
          Text(_timeOnly(r.raceTime),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(r.label ?? 'Break',
                style: const TextStyle(
                    fontStyle: FontStyle.italic, fontSize: 12)),
          ),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text('#${r.raceNumber ?? "—"}',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ),
        SizedBox(
          width: 56,
          child: Text(_timeOnly(r.raceTime),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        if (r.hull != null && r.hull!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(r.hull!,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
        Expanded(
          child: Text(
            [r.disciplineKey, r.stage].where((s) => s != null && s.isNotEmpty).join(' · '),
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  String _timeOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    // "2026-06-12 09:04:00" → "09:04"
    final i = raw.indexOf(' ');
    if (i < 0 || raw.length < i + 6) return raw;
    return raw.substring(i + 1, i + 6);
  }
}
