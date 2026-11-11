import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../../athletes/image_widget_web.dart' if (dart.library.io) 'package:flutter/material.dart';
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

  bool _resolving = false;
  bool _noEvent = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && _event != null) {
        syncBadgesUrl(_event!.id?.toString(), tabIndex: _tabs.index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event != null || _resolving) return;
    _resolveEvent();
  }

  /// Warm navigation passes the Competition; on a browser refresh the id
  /// comes from the URL (?eventId=, &tab=) or local storage and the event is
  /// re-fetched from the events list (there is no by-id endpoint).
  Future<void> _resolveEvent() async {
    _resolving = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Competition) {
      _event = args;
      syncBadgesUrl(_event!.id?.toString(), tabIndex: _tabs.index);
      _load();
      return;
    }
    final map = args is Map ? args : const {};
    final tab = int.tryParse(map['tab']?.toString() ?? '') ?? loadBadgesTab();
    if (tab != null && tab >= 0 && tab < _tabs.length) _tabs.index = tab;
    final id = int.tryParse(map['eventId']?.toString() ?? '') ?? int.tryParse(loadBadgesEventId() ?? '');
    if (id == null) {
      setState(() {
        _loading = false;
        _noEvent = true;
      });
      return;
    }
    try {
      final list = await api.getCompetitions(allEvents: true);
      if (!mounted) return;
      final match = list.where((c) => c.id == id);
      if (match.isEmpty) {
        setState(() {
          _loading = false;
          _noEvent = true;
        });
        return;
      }
      _event = match.first;
      syncBadgesUrl(_event!.id?.toString(), tabIndex: _tabs.index);
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
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
    if (_event == null && !_noEvent) {
      return Scaffold(
        appBar: appBar(title: 'Badges'),
        body: Center(
            child: _error != null ? Text('Error: $_error') : const CircularProgressIndicator()),
      );
    }
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
      appBar: appBar(title: _event!.getShortName()),
      body: Container(
        decoration: bckDecoration(),
        child: Column(children: [
          Material(
            color: Colors.white,
            elevation: 1,
            child: TabBar(
              controller: _tabs,
              labelColor: pageBlue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: pageBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'Badges'),
                Tab(icon: Icon(Icons.palette), text: 'Template'),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 3, color: pageBlue),
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

  static const _typeColors = <String, MaterialColor>{
    'athlete': Colors.blue,
    'coach': Colors.green,
    'official': Colors.purple,
    'support': Colors.blueGrey,
    'media': Colors.orange,
    'volunteer': Colors.teal,
    'vip': Colors.amber,
  };

  bool? _selectionState(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return false;
    final n = list.where((e) => _selected.contains(e['key'])).length;
    return n == 0 ? false : (n == list.length ? true : null);
  }

  void _toggleAll(List<Map<String, dynamic>> list) {
    setState(() {
      final all = list.every((e) => _selected.contains(e['key']));
      for (final e in list) {
        all ? _selected.remove(e['key']) : _selected.add(e['key'] as String);
      }
    });
  }

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
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageTitleBlock(title: 'Badges (${_entries.length})', children: [
                Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                  for (final t in badgeTypeLabels.keys)
                    if ((counts[t] ?? 0) > 0)
                      FilterChip(
                        label: Text('${badgeTypeLabels[t]} ${counts[t]}'),
                        selected: _typeFilter.contains(t),
                        selectedColor: (_typeColors[t] ?? Colors.blue).shade100,
                        checkmarkColor: (_typeColors[t] ?? Colors.blue).shade800,
                        side: BorderSide(color: (_typeColors[t] ?? Colors.blue).shade300),
                        backgroundColor: Colors.white,
                        onSelected: (on) => setState(() => on ? _typeFilter.add(t) : _typeFilter.remove(t)),
                      ),
                ]),
                TextField(
                  decoration: pageFieldDecoration('Search name, club or EDBF ID')
                      .copyWith(prefixIcon: const Icon(Icons.search, color: pageBlue)),
                  onChanged: (v) => setState(() => _search = v),
                ),
                Row(children: [
                  Checkbox(
                    tristate: true,
                    activeColor: pageBlue,
                    value: _selectionState(visible),
                    onChanged: (_) => _toggleAll(visible),
                  ),
                  Expanded(
                    child: Text(
                      '${visible.length} shown · ${_selected.length} selected',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  if (missingPhotos > 0) StatusChip(label: '$missingPhotos without photo', color: Colors.orange),
                ]),
              ]),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No badges. Athletes appear once they are on a crew in this event.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                ),
              for (final g in groups.entries) ...[
                ColoredPageHeader(
                  title: '${g.key} (${g.value.length})',
                  eventId: _eventId,
                  trailing: Theme(
                    data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white),
                    child: Checkbox(
                      tristate: true,
                      value: _selectionState(g.value),
                      activeColor: Colors.white,
                      checkColor: pageBlue,
                      side: const BorderSide(color: Colors.white, width: 2),
                      onChanged: (_) => _toggleAll(g.value),
                    ),
                  ),
                ),
                const Divider(height: 4),
                for (final e in g.value) _entryTile(e),
                pageSectionGap,
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      _actionBar(visible),
    ]);
  }

  Widget _avatar(Map<String, dynamic> e) {
    final file = e['photo_file'] as String?;
    Widget? img;
    if (file != null && file.isNotEmpty) {
      img = e['source'] == 'person'
          ? Image.network(api.badgeFileUrl(_eventId, file),
              headers: api.badgeFileHeaders, width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey))
          : WebImage(imageUrl: 'https://$imagePrefix/$file', width: 48, height: 48);
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade200,
      child: img != null ? ClipOval(child: img) : const Icon(Icons.person, size: 28, color: Colors.grey),
    );
  }

  Widget _entryTile(Map<String, dynamic> e) {
    final key = e['key'] as String;
    final type = e['type'] as String;
    final isPerson = e['source'] == 'person';
    final selected = _selected.contains(key);

    return PageListItem(
      onTap: () => setState(() => selected ? _selected.remove(key) : _selected.add(key)),
      child: Container(
        color: selected ? Colors.blue.shade50 : Colors.white,
        child: ListTile(
          leading: Row(mainAxisSize: MainAxisSize.min, children: [
            Checkbox(
              value: selected,
              activeColor: pageBlue,
              onChanged: (on) => setState(() => on == true ? _selected.add(key) : _selected.remove(key)),
            ),
            _avatar(e),
          ]),
          title: Text('${e['first_name']} ${e['last_name']}', style: Theme.of(context).textTheme.displaySmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(runSpacing: 4, children: [
              StatusChip(label: badgeTypeLabels[type] ?? type, color: _typeColors[type] ?? Colors.blue),
              if ((e['category'] ?? '') != '') StatusChip(label: e['category'] as String, color: Colors.red),
              if (e['gender'] != null)
                StatusChip(label: e['gender'] as String, color: e['gender'] == 'FEMALE' ? Colors.pink : Colors.green),
              if ((e['edbf_id'] ?? '') != '') StatusChip(label: 'ID ${e['edbf_id']}', color: Colors.grey),
              if (e['has_photo'] != true) const StatusChip(label: 'no photo', color: Colors.orange),
            ]),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isPerson) ...[
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, color: pageBlue),
                onPressed: () => _editPerson(_people[e['id']]),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: pageBlue),
                onPressed: () => _deletePerson(e),
              ),
            ],
            IconButton(
              tooltip: 'Preview badge',
              icon: const Icon(Icons.visibility, color: pageBlue),
              onPressed: () => _preview([key]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _actionBar(List<Map<String, dynamic>> visible) {
    final btnStyle = OutlinedButton.styleFrom(
      foregroundColor: pageBlue,
      side: const BorderSide(color: pageBlue),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
            OutlinedButton.icon(
              style: btnStyle,
              onPressed: _busy ? null : () => _editPerson(null),
              icon: const Icon(Icons.person_add),
              label: const Text('Add person'),
            ),
            OutlinedButton.icon(
              style: btnStyle,
              onPressed: _busy || _selected.isEmpty ? null : () => _preview(_selected.toList()),
              icon: const Icon(Icons.visibility),
              label: Text(_selected.isEmpty ? 'Preview selected' : 'Preview ${_selected.length}'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: pageBlue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
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
