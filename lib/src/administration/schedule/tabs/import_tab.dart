import 'package:flutter/material.dart';

/// Legacy import tab — explains the existing Google Sheets bulk-update flow.
/// Kept as a one-time bootstrap for in-flight events; the in-app builder is
/// the source of truth going forward.
class ImportTab extends StatelessWidget {
  final int eventId;

  const ImportTab({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('Legacy: Google Sheets import'),
        const SizedBox(height: 8),
        const Text(
          'For events whose schedule was originally built in Google Sheets, '
          'use the existing import flow to bootstrap a draft. After importing, '
          'all further edits should happen in this builder — Sheets is no '
          'longer the source of truth.',
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 16),
        Card(
          color: const Color.fromARGB(255, 245, 248, 252),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Steps', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const _Step(n: 1, text: 'Open the existing Google Sheet for this event.'),
              const _Step(n: 2, text: 'Run the "race_sync_script_modified.js" Apps Script (Sheet → Extensions → Apps Script).'),
              const _Step(n: 3, text: 'The script POSTs to /api/race-results/bulk-update with API key auth.'),
              const _Step(n: 4, text: 'Reload this builder; the imported races appear under the Grid tab.'),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Endpoint reference'),
        const SizedBox(height: 4),
        const SelectableText(
          'POST /api/race-results/bulk-update\n'
          '   header: X-API-Key: <key with races.bulk-update permission>\n'
          '   body: { event_id, competition, races: [...] }',
          style: TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "After publishing this event's schedule from the in-app builder, "
                "avoid re-running the Sheets import — it will overwrite changes.",
                style: TextStyle(fontSize: 13),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step({required this.n, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 0, 80, 150),
            shape: BoxShape.circle,
          ),
          child: Text('$n',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ]),
    );
  }
}
