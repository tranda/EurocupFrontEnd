import 'dart:convert';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/model/club/club.dart';
import 'package:eurocup_frontend/src/model/race/team.dart';
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
  bool _syncMode = false;
  Map<String, dynamic>? _lastResult;
  bool _lastWasDryRun = false;
  String? _errorMessage;

  /// Operator-supplied "this CSV row → existing team id" overrides. Cleared
  /// when a new CSV file is picked. Keyed by lowercased trimmed
  /// "team_name|club_name" so the backend can short-circuit findTeam.
  final Map<String, int> _teamMappings = {};

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
        _teamMappings.clear();
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
      final mappings = _teamMappings.entries.map((e) {
        final parts = e.key.split('|');
        return {
          'csv_team_name': parts.isNotEmpty ? parts[0] : '',
          'csv_club_name': parts.length > 1 ? parts[1] : '',
          'team_id': e.value,
        };
      }).toList();
      final result = await api.importCrewRegistrations(
        widget.eventId,
        csv: csv,
        dryRun: dryRun,
        sync: _syncMode,
        teamMappings: mappings.isEmpty ? null : mappings,
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

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all registrations?'),
        content: const Text(
          'This deletes every crew registration for this event. '
          'Race results in those crews will also be deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final deleted = await api.clearAllCrewRegistrations(widget.eventId);
      if (!mounted) return;
      setState(() {
        _lastResult = null;
        _teamMappings.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared $deleted registrations.')),
      );
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Clear failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addMapping(String teamName, String clubName, int teamId) {
    final key = '${teamName.trim().toLowerCase()}|${clubName.trim().toLowerCase()}';
    setState(() => _teamMappings[key] = teamId);
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
          CheckboxListTile(
            value: _syncMode,
            onChanged: _busy ? null : (v) => setState(() => _syncMode = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Sync mode (destructive)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Also unregister teams whose cell is empty in the CSV. '
              'Only touches teams/disciplines that appear in the CSV; '
              'crews outside the CSV scope are left alone.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
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
                backgroundColor: _syncMode
                    ? Colors.red.shade700
                    : const Color.fromARGB(255, 0, 80, 150),
                foregroundColor: Colors.white,
              ),
              icon: Icon(_syncMode ? Icons.sync : Icons.cloud_upload),
              label: Text(_syncMode ? 'Import + Sync' : 'Import'),
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
            _ResultPanel(
              result: _lastResult!,
              dryRun: _lastWasDryRun,
              onRequestPreview: _busy ? null : () => _run(true),
              onTeamMapped: _addMapping,
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Row(children: [
            const Expanded(
              child: Text(
                'Wipe every crew registration for this event. Use before '
                're-importing from scratch.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _clearAll,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Clear all registrations',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
              ),
            ),
          ]),
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
  final VoidCallback? onRequestPreview;
  final void Function(String teamName, String clubName, int teamId)? onTeamMapped;
  const _ResultPanel({
    required this.result,
    required this.dryRun,
    this.onRequestPreview,
    this.onTeamMapped,
  });

  @override
  Widget build(BuildContext context) {
    final created = (result['crews_created'] ?? 0) as int;
    final skipped = (result['crews_skipped_existing'] ?? 0) as int;
    final unregistered = (result['crews_unregistered'] ?? 0) as int;
    final matched = (result['matched_count'] ?? 0) as int;
    final discCreated = (result['disciplines_created'] ?? 0) as int;
    final discActivated = (result['disciplines_activated'] ?? 0) as int;
    final discDeactivated = (result['disciplines_deactivated'] ?? 0) as int;
    final minCrews = (result['min_crews_per_race'] ?? 0) as int;
    final sections = (result['sections_parsed'] ?? 0) as int;
    final syncMode = (result['sync_mode'] ?? false) == true;
    final unregisteredPairs = ((result['unregistered_pairs'] ?? const []) as List)
        .map((e) => e.toString())
        .toList();
    final unmatchedTeams = ((result['unmatched_teams'] ?? const []) as List)
        .map<_UnmatchedTeam>((e) {
          if (e is Map) {
            return _UnmatchedTeam(
              teamName: (e['team_name'] ?? '').toString(),
              clubName: (e['club_name'] ?? '').toString(),
            );
          }
          // Backward compat: older payloads sent a formatted string.
          return _UnmatchedTeam(teamName: e.toString(), clubName: '');
        })
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
          _row('Disciplines activated (≥ $minCrews crews)', discActivated),
          _row('Disciplines deactivated (< $minCrews crews)', discDeactivated),
          if (syncMode)
            _row(dryRun ? 'Crews to unregister' : 'Crews unregistered', unregistered),
          if (unregisteredPairs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              dryRun
                  ? 'Would unregister (team — discipline):'
                  : 'Unregistered (team — discipline):',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            ...unregisteredPairs.take(50).map((p) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text('• $p', style: const TextStyle(fontSize: 12)),
                )),
            if (unregisteredPairs.length > 50)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(
                  '… and ${unregisteredPairs.length - 50} more.',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
          if (unmatchedTeams.isNotEmpty) ...[
            const SizedBox(height: 12),
            _UnmatchedTeamsSection(
              teams: unmatchedTeams,
              onResolved: onRequestPreview,
              onTeamMapped: onTeamMapped,
            ),
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

class _UnmatchedTeam {
  final String teamName;
  final String clubName;
  const _UnmatchedTeam({required this.teamName, required this.clubName});
}

/// Per-row UI for unmatched teams: shows the CSV team/club label, a club
/// dropdown (auto-preselected if the CSV club name matches one
/// case-insensitively), an optional team dropdown filtered by the picked
/// club, and two actions:
///   • Use existing — calls [onTeamMapped] so the parent sends a
///     CSV-name → team-id alias on the next import. No DB writes.
///   • Create team — POSTs a new team in the picked club with the CSV
///     team name.
/// Either action calls [onResolved] so the parent can auto-re-run preview.
class _UnmatchedTeamsSection extends StatefulWidget {
  final List<_UnmatchedTeam> teams;
  final VoidCallback? onResolved;
  final void Function(String teamName, String clubName, int teamId)? onTeamMapped;
  const _UnmatchedTeamsSection({
    required this.teams,
    this.onResolved,
    this.onTeamMapped,
  });

  @override
  State<_UnmatchedTeamsSection> createState() => _UnmatchedTeamsSectionState();
}

class _UnmatchedTeamsSectionState extends State<_UnmatchedTeamsSection> {
  List<Club>? _clubs;
  List<Team>? _teams;
  String? _loadError;
  final Map<int, int?> _selectedClubId = {};
  final Map<int, int?> _selectedTeamId = {};
  final Set<int> _busyRows = {};
  final Set<int> _doneRows = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        api.getClubs(),
        api.getTeams(1), // accessLevel > 0 → all teams (with club info)
      ]);
      final clubs = (results[0] as List<Club>)
        ..sort((a, b) =>
            (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
      final teams = (results[1] as List<Team>);
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _teams = teams;
        for (var i = 0; i < widget.teams.length; i++) {
          final csvClub = widget.teams[i].clubName.trim().toLowerCase();
          if (csvClub.isEmpty) continue;
          final match = clubs.firstWhere(
            (c) => (c.name ?? '').trim().toLowerCase() == csvClub,
            orElse: () => const Club(),
          );
          if (match.id != null) {
            _selectedClubId[i] = match.id;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load clubs/teams: $e');
    }
  }

  List<Team> _teamsForClub(int? clubId) {
    if (clubId == null || _teams == null) return const [];
    return _teams!.where((t) => t.clubId == clubId).toList()
      ..sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
  }

  Future<void> _createTeam(int rowIndex) async {
    final clubId = _selectedClubId[rowIndex];
    if (clubId == null) return;
    final team = widget.teams[rowIndex];
    setState(() => _busyRows.add(rowIndex));
    try {
      await api.createTeamForImport(team.teamName, clubId);
      if (!mounted) return;
      setState(() {
        _doneRows.add(rowIndex);
        _busyRows.remove(rowIndex);
      });
      widget.onResolved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyRows.remove(rowIndex));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create team: $e')),
      );
    }
  }

  void _useExisting(int rowIndex) {
    final teamId = _selectedTeamId[rowIndex];
    if (teamId == null) return;
    final csv = widget.teams[rowIndex];
    widget.onTeamMapped?.call(csv.teamName, csv.clubName, teamId);
    setState(() => _doneRows.add(rowIndex));
    widget.onResolved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'Unmatched teams (not in DB)',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 2),
      const Text(
        'Pick a club, then either select an existing team and "Use" (CSV '
        'name → that team for this import), or click "Create" to add a new '
        'team in that club. Preview re-runs automatically.',
        style: TextStyle(fontSize: 11, color: Colors.black54),
      ),
      const SizedBox(height: 8),
      if (_loadError != null)
        Text(_loadError!, style: const TextStyle(color: Colors.red, fontSize: 12))
      else if (_clubs == null || _teams == null)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        ...List.generate(widget.teams.length, (i) => _buildRow(i)),
    ]);
  }

  Widget _buildRow(int i) {
    final team = widget.teams[i];
    final done = _doneRows.contains(i);
    final busy = _busyRows.contains(i);
    final selectedClubId = _selectedClubId[i];
    final selectedTeamId = _selectedTeamId[i];
    final teamsInClub = _teamsForClub(selectedClubId);

    // Defensive: if the previously picked team is no longer in the
    // current club (e.g. operator changed the club), clear the selection
    // so the dropdown doesn't fall over on a value not in items.
    final effectiveTeamId =
        teamsInClub.any((t) => t.id == selectedTeamId) ? selectedTeamId : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 180,
          child: Text(
            team.clubName.isEmpty
                ? team.teamName
                : '${team.teamName}\n(${team.clubName})',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _clubs!.any((c) => c.id == selectedClubId) ? selectedClubId : null,
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              labelText: 'Club',
            ),
            items: _clubs!
                .where((c) => c.id != null)
                .map((c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(
                        c.name ?? '(unnamed)',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: done || busy
                ? null
                : (v) => setState(() {
                      _selectedClubId[i] = v;
                      _selectedTeamId[i] = null; // reset team when club changes
                    }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: effectiveTeamId,
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              labelText: 'Existing team (optional)',
            ),
            items: teamsInClub
                .where((t) => t.id != null)
                .map((t) => DropdownMenuItem<int>(
                      value: t.id,
                      child: Text(
                        t.name ?? '(unnamed)',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: done || busy || teamsInClub.isEmpty
                ? null
                : (v) => setState(() => _selectedTeamId[i] = v),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 200,
          child: done
              ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 4),
                  Text('Resolved', style: TextStyle(fontSize: 12, color: Colors.green)),
                ])
              : Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy || effectiveTeamId == null
                          ? null
                          : () => _useExisting(i),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text('Use', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy || selectedClubId == null
                          ? null
                          : () => _createTeam(i),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ]),
        ),
      ]),
    );
  }
}
