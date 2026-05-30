import 'package:flutter/material.dart';

import '../../api_helper.dart' as api;
import '../../model/schedule/event_day.dart';

/// Save / restore named schedule snapshots for an event.
/// Three independent categories:
///   - setup       (event params + days + blocks + colours)
///   - plan_seeds  (per-discipline progression + crew seed numbers)
///   - grid_day    (races + crew assignments + breaks for one specific day)
class SnapshotsDialog extends StatefulWidget {
  final int eventId;
  final List<EventDay> days;
  const SnapshotsDialog({super.key, required this.eventId, required this.days});

  @override
  State<SnapshotsDialog> createState() => _SnapshotsDialogState();
}

class _SnapshotsDialogState extends State<SnapshotsDialog> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<api.ScheduleSnapshot> _snapshots = [];

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
      final rows = await api.listScheduleSnapshots(widget.eventId);
      if (!mounted) return;
      setState(() {
        _snapshots = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final draft = await showDialog<_SnapshotDraft>(
      context: context,
      builder: (ctx) => _NewSnapshotDialog(days: widget.days),
    );
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      await api.createScheduleSnapshot(
        widget.eventId,
        category: draft.category,
        day: draft.day,
        name: draft.name,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved snapshot "${draft.name}"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(api.ScheduleSnapshot s) async {
    final confirmed = await _confirm(
      'Restore snapshot?',
      'This will overwrite the current ${_categoryLabel(s.category)}'
      '${s.day == null ? "" : " for day ${s.day}"} state with the snapshot '
      '"${s.name}". Make sure no race in that scope is in progress.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await api.restoreScheduleSnapshot(s.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored "${s.name}"')),
      );
      Navigator.pop(context, true); // signal parent to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(api.ScheduleSnapshot s) async {
    final confirmed = await _confirm(
      'Delete snapshot?',
      'Permanently delete snapshot "${s.name}". This cannot be undone.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await api.deleteScheduleSnapshot(s.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    return r == true;
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'setup': return 'Setup';
      case 'plan_seeds': return 'Plan & Seeds';
      case 'grid_day': return 'Grid (day)';
      default: return c;
    }
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'setup': return Icons.tune;
      case 'plan_seeds': return Icons.format_list_numbered;
      case 'grid_day': return Icons.grid_on;
      default: return Icons.bookmark_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.bookmark, color: Color.fromARGB(255, 0, 80, 150)),
        const SizedBox(width: 8),
        const Text('Schedule snapshots'),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ]),
      content: SizedBox(
        width: 560,
        height: 460,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _snapshots.isEmpty
                    ? const Center(
                        child: Text(
                          'No snapshots yet — save one with "+ New snapshot" below.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _snapshots.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = _snapshots[i];
                          return ListTile(
                            leading: Icon(_categoryIcon(s.category)),
                            title: Text(s.name),
                            subtitle: Text(
                              [
                                _categoryLabel(s.category),
                                if (s.day != null) 'day ${s.day}',
                                if (s.createdAt != null)
                                  'saved ${_formatRelative(s.createdAt!)}',
                              ].join(' · '),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                tooltip: 'Restore',
                                onPressed: _busy ? null : () => _restore(s),
                                icon: const Icon(Icons.restore, color: Colors.green),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: _busy ? null : () => _delete(s),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ]),
                          );
                        },
                      ),
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: _busy ? null : _create,
          icon: const Icon(Icons.add),
          label: const Text('New snapshot'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatRelative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${t.year}-${t.month.toString().padLeft(2, "0")}-${t.day.toString().padLeft(2, "0")}';
  }
}

class _SnapshotDraft {
  final String category;
  final String? day;
  final String name;
  _SnapshotDraft({required this.category, this.day, required this.name});
}

class _NewSnapshotDialog extends StatefulWidget {
  final List<EventDay> days;
  const _NewSnapshotDialog({required this.days});

  @override
  State<_NewSnapshotDialog> createState() => _NewSnapshotDialogState();
}

class _NewSnapshotDialogState extends State<_NewSnapshotDialog> {
  String _category = 'setup';
  String? _day;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayDates = widget.days
        .map((d) => d.date.toIso8601String().substring(0, 10))
        .toList()
      ..sort();

    return AlertDialog(
      title: const Text('New snapshot'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'setup', child: Text('Setup (params + days + blocks)')),
              DropdownMenuItem(value: 'plan_seeds', child: Text('Plan & Seeds (plans + crew seeds)')),
              DropdownMenuItem(value: 'grid_day', child: Text('Grid — one day (races + lanes + breaks)')),
            ],
            onChanged: (v) => setState(() {
              _category = v ?? 'setup';
              if (_category != 'grid_day') _day = null;
            }),
          ),
          if (_category == 'grid_day') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _day,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Day'),
              items: [
                for (final d in dayDates)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _day = v),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. "before clean generate"',
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save'),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            if (_category == 'grid_day' && _day == null) return;
            Navigator.pop(
              context,
              _SnapshotDraft(category: _category, day: _day, name: name),
            );
          },
        ),
      ],
    );
  }
}
