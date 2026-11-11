import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import 'badge_event_picker.dart';
import 'badge_person_dialog.dart';
import 'badge_template_tab.dart';

/// Badge types in display order, with UI labels.
const badgeTypeLabels = <String, String>{
  'athlete': 'Athlete',
  'coach': 'Coach',
  'official': 'Official',
  'support': 'Supporter',
  'media': 'Media',
  'volunteer': 'Volunteer',
  'vip': 'VIP',
};

/// Accreditation badges for one event: everyone who gets a badge, the
/// per-event template, and print downloads (one PDF, or a ZIP per club).
class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});
  static const routeName = '/badges';

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  Competition? _event;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  Map<String, dynamic> _template = {};
  List<Map<String, dynamic>> _entries = [];
  Map<int, Map<String, dynamic>> _people = {};

  final Set<String> _typeFilter = {};
  final Set<String> _selected = {};
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Competition) {
      _event = args;
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int get _eventId => _event!.id!;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.getBadges(_eventId);
      setState(() {
        _template = Map<String, dynamic>.from(data['template'] as Map);
        _entries = (data['entries'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _people = {
          for (final p in (data['people'] as List)) (p['id'] as int): Map<String, dynamic>.from(p as Map),
        };
        _selected.removeWhere((k) => !_entries.any((e) => e['key'] == k));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    final q = _search.trim().toLowerCase();
    return _entries.where((e) {
      if (_typeFilter.isNotEmpty && !_typeFilter.contains(e['type'])) return false;
      if (q.isEmpty) return true;
      final hay = '${e['first_name']} ${e['last_name']} ${e['club']} ${e['edbf_id']}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return Scaffold(
        appBar: appBar(title: 'Badges'),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushReplacementNamed(context, BadgeEventPicker.routeName),
            child: const Text('Choose an event'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar(title: 'Badges'),
      body: Container(
        decoration: bckDecoration(),
        child: Column(children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text('${_event!.name ?? "Event"} ${_event!.year ?? ""}'.trim(),
                style: Theme.of(context).textTheme.displaySmall),
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: Colors.blue.shade800,
              tabs: const [Tab(icon: Icon(Icons.people), text: 'Badges'), Tab(icon: Icon(Icons.palette), text: 'Template')],
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error: $_error')))
                    : TabBarView(controller: _tabs, children: [
                        _badgesTab(),
                        BadgeTemplateTab(
                          eventId: _eventId,
                          template: _template,
                          onSaved: (t) => setState(() => _template = t),
                          onPreview: () => _preview(_entries.take(6).map((e) => e['key'] as String).toList()),
                        ),
                      ]),
          ),
        ]),
      ),
    );
  }

  // ------------------------------------------------------------ badges tab

  Widget _badgesTab() {
    final visible = _visible;
    final counts = <String, int>{};
    for (final e in _entries) {
      counts[e['type'] as String] = (counts[e['type'] as String] ?? 0) + 1;
    }
    final missingPhotos = visible.where((e) => e['has_photo'] != true).length;

    // Group by club / organisation, keeping server order (group, surname).
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final e in visible) {
      groups.putIfAbsent(e['group'] as String, () => []).add(e);
    }

    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final t in badgeTypeLabels.keys)
              if ((counts[t] ?? 0) > 0)
                FilterChip(
                  label: Text('${badgeTypeLabels[t]} ${counts[t]}'),
                  selected: _typeFilter.contains(t),
                  onSelected: (on) => setState(() => on ? _typeFilter.add(t) : _typeFilter.remove(t)),
                ),
          ]),
          const SizedBox(height: 6),
          TextField(
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name, club, EDBF ID',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Checkbox(
              tristate: true,
              value: visible.isEmpty
                  ? false
                  : visible.every((e) => _selected.contains(e['key']))
                      ? true
                      : visible.any((e) => _selected.contains(e['key']))
                          ? null
                          : false,
              onChanged: (_) => setState(() {
                final all = visible.every((e) => _selected.contains(e['key']));
                for (final e in visible) {
                  all ? _selected.remove(e['key']) : _selected.add(e['key'] as String);
                }
              }),
            ),
            Expanded(
              child: Text(
                '${visible.length} shown · ${_selected.length} selected'
                '${missingPhotos > 0 ? ' · $missingPhotos without photo' : ''}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ]),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No badges. Athletes appear once they are on a crew in this event.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                ),
              for (final g in groups.entries) ...[
                Container(
                  color: Colors.blueGrey.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('${g.key} (${g.value.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                ),
                for (final e in g.value) _entryTile(e),
              ],
            ],
          ),
        ),
      ),
      _actionBar(visible),
    ]);
  }

  Widget _entryTile(Map<String, dynamic> e) {
    final key = e['key'] as String;
    final isPerson = e['source'] == 'person';
    final details = [
      badgeTypeLabels[e['type']] ?? e['type'],
      if ((e['category'] ?? '') != '') e['category'],
      if (e['gender'] != null) e['gender'],
      if ((e['edbf_id'] ?? '') != '') 'ID ${e['edbf_id']}',
    ].join(' · ');

    return Material(
      color: Colors.white,
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: _selected.contains(key),
          onChanged: (on) => setState(() => on == true ? _selected.add(key) : _selected.remove(key)),
        ),
        title: Text('${e['last_name']} ${e['first_name']}'.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(details),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (e['has_photo'] != true)
            const Tooltip(message: 'No photo', child: Icon(Icons.no_photography_outlined, color: Colors.orange)),
          if (isPerson) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editPerson(_people[e['id']]),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deletePerson(e),
            ),
          ],
          IconButton(
            tooltip: 'Preview badge',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => _preview([key]),
          ),
        ]),
      ),
    );
  }

  Widget _actionBar(List<Map<String, dynamic>> visible) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _editPerson(null),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add person'),
            ),
            OutlinedButton.icon(
              onPressed: _busy || _selected.isEmpty ? null : () => _preview(_selected.toList()),
              icon: const Icon(Icons.visibility),
              label: const Text('Preview selected'),
            ),
            FilledButton.icon(
              onPressed: _busy || _entries.isEmpty ? null : () => _download(visible),
              icon: const Icon(Icons.download),
              label: const Text('Download for print'),
            ),
          ]),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- actions

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Open the badges as a PDF in a new browser tab.
  Future<void> _preview(List<String> keys) async {
    if (keys.isEmpty) return;
    await _run(() async {
      final r = await api.downloadBadges(_eventId, keys: keys);
      final blob = html.Blob([r['bytes'] as Uint8List], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    });
  }

  Future<void> _download(List<Map<String, dynamic>> visible) async {
    final filtered = _typeFilter.isNotEmpty || _search.trim().isNotEmpty;
    final choice = await showDialog<_DownloadChoice>(
      context: context,
      builder: (_) => _DownloadDialog(
        size: (_template['size'] ?? 'small') as String,
        total: _entries.length,
        shown: filtered ? visible.length : null,
        selected: _selected.length,
      ),
    );
    if (choice == null) return;

    List<String>? keys;
    List<String>? types;
    if (choice.scope == 'selected') {
      keys = _selected.toList();
    } else if (choice.scope == 'shown') {
      if (_search.trim().isEmpty) {
        types = _typeFilter.toList();
      } else {
        keys = visible.map((e) => e['key'] as String).toList();
      }
    }

    await _run(() async {
      final r = await api.downloadBadges(_eventId,
          size: choice.size, split: choice.split, sides: choice.sides, keys: keys, types: types);
      final blob = html.Blob([r['bytes'] as Uint8List], r['contentType'] as String);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', r['filename'] as String)
        ..click();
      html.Url.revokeObjectUrl(url);
    });
  }

  Future<void> _editPerson(Map<String, dynamic>? person) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => BadgePersonDialog(eventId: _eventId, person: person),
    );
    if (saved == true) await _load();
  }

  Future<void> _deletePerson(Map<String, dynamic> e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete badge person?'),
        content: Text('${e['first_name']} ${e['last_name']} will be removed from this event\'s badges.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await api.deleteBadgePerson(_eventId, e['id'] as int);
      _selected.remove(e['key']);
    });
    await _load();
  }
}

// ------------------------------------------------------------ download dialog

class _DownloadChoice {
  final String size;
  final String split;
  final String sides; // duplex | spread
  final String scope; // all | shown | selected
  const _DownloadChoice(this.size, this.split, this.sides, this.scope);
}

class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.size, required this.total, required this.shown, required this.selected});
  final String size;
  final int total;
  final int? shown; // null when no filter is active
  final int selected;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  late String _size = widget.size;
  String _split = 'single';
  String _sides = 'duplex';
  late String _scope = widget.selected > 0 ? 'selected' : (widget.shown != null ? 'shown' : 'all');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Download for print'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Size', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<String>(
            dense: true,
            value: 'small',
            groupValue: _size,
            onChanged: (v) => setState(() => _size = v!),
            title: const Text('Small 54 × 85.6 mm'),
          ),
          RadioListTile<String>(
            dense: true,
            value: 'large',
            groupValue: _size,
            onChanged: (v) => setState(() => _size = v!),
            title: const Text('Large 100 × 145 mm'),
          ),
          const SizedBox(height: 8),
          const Text('Sides', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<String>(
            dense: true,
            value: 'duplex',
            groupValue: _sides,
            onChanged: (v) => setState(() => _sides = v!),
            title: const Text('Duplex'),
            subtitle: const Text('Front and back on alternating pages'),
          ),
          RadioListTile<String>(
            dense: true,
            value: 'spread',
            groupValue: _sides,
            onChanged: (v) => setState(() => _sides = v!),
            title: const Text('Side by side'),
            subtitle: const Text('Front and back next to each other on one page'),
          ),
          const SizedBox(height: 8),
          const Text('Badges', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<String>(
            dense: true,
            value: 'all',
            groupValue: _scope,
            onChanged: (v) => setState(() => _scope = v!),
            title: Text('All (${widget.total})'),
          ),
          if (widget.shown != null)
            RadioListTile<String>(
              dense: true,
              value: 'shown',
              groupValue: _scope,
              onChanged: (v) => setState(() => _scope = v!),
              title: Text('Shown by filter (${widget.shown})'),
            ),
          if (widget.selected > 0)
            RadioListTile<String>(
              dense: true,
              value: 'selected',
              groupValue: _scope,
              onChanged: (v) => setState(() => _scope = v!),
              title: Text('Selected (${widget.selected})'),
            ),
          const SizedBox(height: 8),
          const Text('File', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<String>(
            dense: true,
            value: 'single',
            groupValue: _split,
            onChanged: (v) => setState(() => _split = v!),
            title: const Text('One PDF'),
            subtitle: const Text('Grouped by club'),
          ),
          RadioListTile<String>(
            dense: true,
            value: 'club',
            groupValue: _split,
            onChanged: (v) => setState(() => _split = v!),
            title: const Text('ZIP, one PDF per club'),
          ),
          const SizedBox(height: 4),
          const Text('Large downloads can take a minute.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _DownloadChoice(_size, _split, _sides, _scope)),
          child: const Text('Download'),
        ),
      ],
    );
  }
}
