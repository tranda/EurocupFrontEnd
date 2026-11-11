import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';

/// Database updates section of the Database Backups page (admins only):
/// lists database migrations that are in the backend code but not yet run
/// on the server, and runs them (like `php artisan migrate` from the
/// hosting panel).
class DatabaseUpdatesPanel extends StatefulWidget {
  const DatabaseUpdatesPanel({super.key});

  @override
  State<DatabaseUpdatesPanel> createState() => _DatabaseUpdatesPanelState();
}

class _DatabaseUpdatesPanelState extends State<DatabaseUpdatesPanel> {
  bool _loading = true;
  bool _running = false;
  List<String> _pending = [];
  int _ranCount = 0;
  String? _error;
  String? _output;
  String? _resultMessage;
  bool _resultOk = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _apply(Map<String, dynamic> d) {
    _pending = ((d['pending'] ?? []) as List).map((e) => e.toString()).toList();
    _ranCount = (d['ran_count'] ?? 0) as int;
    _error = d['error'] as String?;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await api.getDatabaseUpdates();
      setState(() => _apply(d));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update database?'),
        content: Text('This runs ${_pending.length} database migration(s) on the live server. '
            'Create a backup first with "Create Backup Now" above.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update database')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _running = true;
      _output = null;
      _resultMessage = null;
    });
    try {
      final d = await api.runDatabaseUpdates();
      setState(() {
        _apply(d);
        _output = d['output'] as String?;
        _resultMessage = d['message'] as String?;
        _resultOk = d['success'] == true;
      });
    } catch (e) {
      setState(() {
        _resultMessage = e.toString().replaceFirst('Exception: ', '');
        _resultOk = false;
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_loading)
        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
      else
        ..._content(),
      pageSectionGap,
    ]);
  }

  List<Widget> _content() {
    final widgets = <Widget>[];

    if (_resultMessage != null) {
      widgets.add(_banner(_resultMessage!, _resultOk ? Colors.green : Colors.red,
          _resultOk ? Icons.check_circle : Icons.error));
    }
    if (_error != null) {
      widgets.add(_banner('Could not read migration status: $_error', Colors.red, Icons.error));
    }

    widgets.add(ColoredPageHeader(
      title: _pending.isEmpty ? 'Database is up to date' : 'Database updates waiting (${_pending.length})',
      subtitle: '$_ranCount migration(s) applied',
      trailing: IconButton(
        tooltip: 'Check again',
        icon: const Icon(Icons.refresh),
        onPressed: _running ? null : _load,
      ),
    ));

    if (_pending.isNotEmpty) {
      widgets.add(const Divider(height: 4));
      for (final m in _pending) {
        widgets.add(PageListItem(
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.schema_outlined),
            title: Text(m, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ));
      }
      widgets.add(Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _running ? null : _run,
            icon: _running
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.system_update_alt),
            label: Text(_running ? 'Updating…' : 'Update database'),
          ),
        ),
      ));
    }

    if (_output != null && _output!.isNotEmpty) {
      widgets.add(pageSectionGap);
      widgets.add(const ColoredPageHeader(title: 'Output'));
      widgets.add(Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        color: Colors.black87,
        child: SelectableText(_output!,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white)),
      ));
    }

    return widgets;
  }

  Widget _banner(String text, MaterialColor color, IconData icon) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.shade50,
          border: Border.all(color: color.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Icon(icon, color: color.shade700),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(text, style: TextStyle(color: color.shade900))),
        ]),
      );
}
