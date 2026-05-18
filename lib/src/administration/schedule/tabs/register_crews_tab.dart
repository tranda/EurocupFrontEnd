import 'dart:convert';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Bulk-register crews for an event from a CSV matrix.
/// Rows = team/club, columns = disciplines (grouped into Standard / Small
/// boat sections), a cell marked "x" = "this team is registered for this
/// discipline". Use Preview first (dry-run), then Import to commit.
class RegisterCrewsTab extends StatefulWidget {
  final int eventId;

  const RegisterCrewsTab({super.key, required this.eventId});

  @override
  State<RegisterCrewsTab> createState() => _RegisterCrewsTabState();
}

class _RegisterCrewsTabState extends State<RegisterCrewsTab> {
  final TextEditingController _matrixController = TextEditingController();
  String? _fileName;
  bool _busy = false;
  Map<String, dynamic>? _lastResult;
  bool _lastWasDryRun = false;
  String? _errorMessage;

  @override
  void dispose() {
    _matrixController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _errorMessage = 'Could not read file contents.');
        return;
      }
      setState(() {
        _fileName = file.name;
        _matrixController.text = _decodeCsv(bytes);
        _lastResult = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to read file: $e');
    }
  }

  /// Try UTF-8 first; fall back to Latin-1 for legacy exports. Strips BOM.
  String _decodeCsv(List<int> bytes) {
    var data = bytes;
    if (data.length >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
      data = data.sublist(3);
    }
    try {
      return utf8.decode(data);
    } catch (_) {
      return latin1.decode(data);
    }
  }

  Future<void> _run(bool dryRun) async {
    final csv = _matrixController.text;
    if (csv.trim().isEmpty) {
      setState(() => _errorMessage = 'Paste or pick a CSV first.');
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
      _lastResult = null;
    });
    try {
      final result = await api.importCrewRegistrations(
        widget.eventId,
        csv: csv,
        dryRun: dryRun,
      );
      setState(() {
        _lastResult = result;
        _lastWasDryRun = dryRun;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text(
            'Bulk-register crews from CSV',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick the entry-matrix CSV (or paste below). Rows = team / club, '
            'columns = disciplines grouped into Standard and Small boat '
            'sections. A cell marked "x" means that team is registered for '
            'that discipline.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(children: [
            ElevatedButton.icon(
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose CSV file'),
            ),
            const SizedBox(width: 12),
            if (_fileName != null)
              Expanded(
                child: Text(
                  _fileName!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _matrixController,
                maxLines: 14,
                minLines: 8,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Or paste matrix here',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(
              onPressed: _busy ? null : () => _run(true),
              icon: const Icon(Icons.preview),
              label: const Text('Preview (dry run)'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _busy ? null : () => _run(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 80, 150),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Import'),
            ),
          ]),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          ],
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            _ResultPanel(result: _lastResult!, dryRun: _lastWasDryRun),
          ],
        ]),
      ),
      if (_busy)
        const Positioned.fill(
          child: ColoredBox(
            color: Color.fromARGB(60, 255, 255, 255),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ]);
  }
}

class _ResultPanel extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool dryRun;
  const _ResultPanel({required this.result, required this.dryRun});

  @override
  Widget build(BuildContext context) {
    final created = (result['crews_created'] ?? 0) as int;
    final skipped = (result['crews_skipped_existing'] ?? 0) as int;
    final matched = (result['matched_count'] ?? 0) as int;
    final discCreated = (result['disciplines_created'] ?? 0) as int;
    final sections = (result['sections_parsed'] ?? 0) as int;
    final unmatchedTeams = ((result['unmatched_teams'] ?? const []) as List)
        .map((e) => e.toString())
        .toList();
    final warnings = ((result['warnings'] ?? const []) as List)
        .map((e) => e.toString())
        .toList();

    return Card(
      color: dryRun ? Colors.blue.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
              dryRun ? Icons.preview : Icons.check_circle,
              color: dryRun ? Colors.blue.shade700 : Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              dryRun ? 'Preview (nothing saved)' : 'Imported',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: dryRun ? Colors.blue.shade900 : Colors.green.shade900,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _row('Sections parsed', sections),
          _row('Cells marked', matched),
          _row(dryRun ? 'Crews to create' : 'Crews created', created),
          _row('Crews already registered (skipped)', skipped),
          _row('Disciplines auto-created', discCreated),
          if (unmatchedTeams.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Unmatched teams (not in DB — add them in Admin first):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...unmatchedTeams.map((t) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text('• $t', style: const TextStyle(fontSize: 12)),
                )),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Warnings:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...warnings.take(20).map((w) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text('• $w', style: const TextStyle(fontSize: 12)),
                )),
            if (warnings.length > 20)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(
                  '… and ${warnings.length - 20} more.',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _row(String label, int n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(
          '$n',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ]),
    );
  }
}
