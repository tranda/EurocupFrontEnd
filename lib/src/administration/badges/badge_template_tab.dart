import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:file_picker/file_picker.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';

import 'badges_page.dart' show badgeTypeLabels;

const _fieldLabels = <String, String>{
  'banner': 'Banner (event name bar)',
  'photo': 'Photo',
  'qr': 'QR code (athletes)',
  'gender': 'Gender tag (athletes)',
  'category': 'Category (athletes)',
  'edbf_id': 'EDBF ID',
  'club': 'Club in footer (off: country)',
  'areas': 'Accessible areas',
};

const _backFieldLabels = <String, String>{
  'back_name': 'Name and category',
  'back_qr': 'QR code (athletes)',
  'back_areas': 'Area legend',
};

/// An image slot being edited: the saved file name, a newly picked file, or removed.
class _ImageSlot {
  String? saved;
  Uint8List? bytes;
  String? name;
  bool remove = false;
  _ImageSlot(this.saved);

  bool get hasImage => bytes != null || (saved != null && !remove);
}

/// Per-event badge template: size, colours, images, front/back fields,
/// access areas and the per-type labels/colours/areas.
class BadgeTemplateTab extends StatefulWidget {
  const BadgeTemplateTab({
    super.key,
    required this.eventId,
    required this.template,
    required this.onSaved,
    required this.onPreview,
  });

  final int eventId;
  final Map<String, dynamic> template;
  final ValueChanged<Map<String, dynamic>> onSaved;
  final VoidCallback onPreview;

  @override
  State<BadgeTemplateTab> createState() => _BadgeTemplateTabState();
}

class _BadgeTemplateTabState extends State<BadgeTemplateTab> with AutomaticKeepAliveClientMixin {
  late String _size;
  late String _layout;
  late int _bleed;
  late final TextEditingController _banner;
  late final TextEditingController _bannerColor;
  late final TextEditingController _footerColor;
  late final TextEditingController _backText;
  late Map<String, bool> _fields;
  late Map<String, TextEditingController> _typeLabel;
  late Map<String, TextEditingController> _typeColor;
  late Map<String, Set<int>> _typeAreas;
  late List<TextEditingController> _areas;
  late _ImageSlot _logo;
  late _ImageSlot _background;
  late _ImageSlot _backBackground;
  bool _saving = false;
  bool _dirty = false;

  /// Keep unsaved edits when switching to the Badges tab and back.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init(widget.template);
  }

  @override
  void dispose() {
    for (final c in [_banner, _bannerColor, _footerColor, _backText, ..._areas,
      ..._typeLabel.values, ..._typeColor.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(Map<String, dynamic> t) {
    _size = (t['size'] ?? 'small') as String;
    _layout = (t['layout'] ?? 'classic') as String;
    _bleed = (t['bleed_mm'] ?? 0) as int;
    _banner = TextEditingController(text: (t['banner_text'] ?? '') as String);
    _bannerColor = TextEditingController(text: (t['banner_color'] ?? '#0072BC') as String);
    _footerColor = TextEditingController(text: (t['footer_color'] ?? '#F3F1DC') as String);
    _backText = TextEditingController(text: (t['back_text'] ?? '') as String);
    _fields = {
      for (final e in ((t['fields'] ?? {}) as Map).entries) e.key as String: e.value == true,
    };
    final types = (t['types'] ?? {}) as Map;
    _typeLabel = {};
    _typeColor = {};
    _typeAreas = {};
    for (final type in badgeTypeLabels.keys) {
      final s = (types[type] ?? {}) as Map;
      _typeLabel[type] = TextEditingController(text: (s['label'] ?? '') as String);
      _typeColor[type] = TextEditingController(text: (s['color'] ?? '#333333') as String);
      _typeAreas[type] = {for (final n in (s['areas'] ?? []) as List) n as int};
    }
    final areas = ((t['areas'] ?? []) as List).map((a) => a as Map).toList()
      ..sort((a, b) => (a['no'] as int).compareTo(b['no'] as int));
    _areas = [for (final a in areas) TextEditingController(text: a['name'] as String)];
    _logo = _ImageSlot(t['logo'] as String?);
    _background = _ImageSlot(t['background'] as String?);
    _backBackground = _ImageSlot(t['back_background'] as String?);
  }

  void _changed() {
    if (!_dirty) setState(() => _dirty = true);
  }

  static bool _isHex(String v) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v.trim());

  static Color _parse(String v, Color fallback) =>
      _isHex(v) ? Color(int.parse('FF${v.trim().substring(1)}', radix: 16)) : fallback;

  Future<void> _save() async {
    final colors = [_bannerColor.text, _footerColor.text, ..._typeColor.values.map((c) => c.text)];
    if (colors.any((c) => !_isHex(c))) {
      _snack('Colours must look like #0072BC.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final areas = <Map<String, dynamic>>[];
      for (var i = 0; i < _areas.length; i++) {
        if (_areas[i].text.trim().isNotEmpty) areas.add({'no': i + 1, 'name': _areas[i].text.trim()});
      }
      final saved = await api.saveBadgeTemplate(
        widget.eventId,
        settings: {
          'size': _size,
          'layout': _layout,
          'banner_text': _banner.text.trim(),
          'banner_color': _bannerColor.text.trim(),
          'footer_color': _footerColor.text.trim(),
          'bleed_mm': _bleed,
          'back_text': _backText.text.trim(),
        },
        fields: _fields,
        types: {
          for (final type in badgeTypeLabels.keys)
            type: {
              'label': _typeLabel[type]!.text.trim(),
              'color': _typeColor[type]!.text.trim(),
              'areas': (_typeAreas[type]!.where((n) => n <= _areas.length).toList()..sort()),
            },
        },
        areas: areas,
        logo: _logo.bytes,
        logoName: _logo.name,
        removeLogo: _logo.remove,
        background: _background.bytes,
        backgroundName: _background.name,
        removeBackground: _background.remove,
        backBackground: _backBackground.bytes,
        backBackgroundName: _backBackground.name,
        removeBackBackground: _backBackground.remove,
      );
      widget.onSaved(saved);
      setState(() {
        _logo = _ImageSlot(saved['logo'] as String?);
        _background = _ImageSlot(saved['background'] as String?);
        _backBackground = _ImageSlot(saved['back_background'] as String?);
        _dirty = false;
      });
      _snack('Template saved.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null));
  }

  Future<void> _pick(_ImageSlot slot) async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    final f = r?.files.single;
    if (f?.bytes == null) return;
    if (f!.bytes!.length > 8 * 1024 * 1024) {
      _snack('Image is larger than 8 MB.', error: true);
      return;
    }
    setState(() {
      slot.bytes = f.bytes;
      slot.name = f.name;
      slot.remove = false;
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          const PageTitleBlock(title: 'Badge Template', children: [
            Text('Settings for this event\'s badges. Save, then use Preview to see the real PDF.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ]),
          _card('Card', [
            const Text('Layout', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'classic', label: Text('Classic')),
                ButtonSegment(value: 'eurocup', label: Text('Euro Cup')),
              ],
              selected: {_layout},
              onSelectionChanged: (s) => setState(() {
                _layout = s.first;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 4),
            Text(
                _layout == 'eurocup'
                    ? 'Header and logo strip come from the front artwork; category ribbon, big names and centred club. '
                        'Text uses the banner colour.'
                    : 'EDBF Nationals style: banner bar, gender ribbon, footer with the club.',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            const Text('Size', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'small', label: Text('Small 54 × 85.6 mm')),
                ButtonSegment(value: 'large', label: Text('Large 100 × 145 mm')),
              ],
              selected: {_size},
              onSelectionChanged: (s) => setState(() {
                _size = s.first;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 4),
            const Text('Both sizes are portrait and two-sided. The size can also be picked at download.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Bleed for the printer'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _bleed,
                items: [for (var i = 0; i <= 5; i++) DropdownMenuItem(value: i, child: Text('$i mm'))],
                onChanged: (v) => setState(() {
                  _bleed = v ?? 0;
                  _dirty = true;
                }),
              ),
            ]),
          ]),
          _card('Banner and colours', [
            TextField(
              controller: _banner,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: 'Banner text',
                hintText: widget.template['banner_text_default'] as String? ?? 'Event name',
                helperText: 'Empty uses the event name',
              ),
              onChanged: (_) => _changed(),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _colorField('Banner colour', _bannerColor),
              _colorField('Footer colour', _footerColor),
            ]),
          ]),
          _card('Images', [
            const Text('JPG or PNG, up to 8 MB. Backgrounds fill the whole card including bleed.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _imageSlot('Logo (top right)', _logo),
              _imageSlot('Front background', _background),
              _imageSlot('Back artwork', _backBackground),
            ]),
          ]),
          _card('Front side', [
            for (final f in _fieldLabels.entries)
              SwitchListTile(
                dense: true,
                activeThumbColor: pageBlue,
                contentPadding: EdgeInsets.zero,
                title: Text(f.value),
                value: _fields[f.key] ?? true,
                onChanged: (v) => setState(() {
                  _fields[f.key] = v;
                  _dirty = true;
                }),
              ),
          ]),
          _card('Back side', [
            const Text(
                'Without back artwork the back repeats the logo, banner and footer. '
                'With artwork only the items below are printed over it.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            for (final f in _backFieldLabels.entries)
              SwitchListTile(
                dense: true,
                activeThumbColor: pageBlue,
                contentPadding: EdgeInsets.zero,
                title: Text(f.value),
                value: _fields[f.key] ?? true,
                onChanged: (v) => setState(() {
                  _fields[f.key] = v;
                  _dirty = true;
                }),
              ),
            TextField(
              controller: _backText,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Back text',
                hintText: 'Venue, dates, emergency phone numbers...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _changed(),
            ),
          ]),
          _card('Access areas', [
            const Text('Numbered zones. Each badge type below picks the areas it may enter.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            for (var i = 0; i < _areas.length; i++)
              Row(children: [
                SizedBox(
                    width: 28,
                    child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Expanded(
                  child: TextField(
                    controller: _areas[i],
                    maxLength: 40,
                    decoration: const InputDecoration(isDense: true, counterText: '', hintText: 'Area name'),
                    onChanged: (_) => _changed(),
                  ),
                ),
                if (i == _areas.length - 1)
                  IconButton(
                    tooltip: 'Remove area',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(() {
                      _areas.removeLast().dispose();
                      _dirty = true;
                    }),
                  ),
              ]),
            if (_areas.length < 9)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _areas.add(TextEditingController());
                    _dirty = true;
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Add area'),
                ),
              ),
          ]),
          _card('Badge types', [
            const Text('Label and colour of the tag on non-athlete badges, and accessible areas per type.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            for (final type in badgeTypeLabels.keys) _typeRow(type),
          ]),
        ]),
      ),
      Material(
        elevation: 8,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (_dirty) const Expanded(child: Text('Unsaved changes', style: TextStyle(color: Colors.orange))),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: pageBlue,
                side: const BorderSide(color: pageBlue),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: _saving || _dirty ? null : widget.onPreview,
              icon: const Icon(Icons.visibility),
              label: const Text('Preview'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: pageBlue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Save template'),
            ),
          ]),
        ),
      ),
    ]);
  }

  /// Style C section: event-coloured bar, white body, section gap.
  Widget _card(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredPageHeader(title: title, eventId: widget.eventId),
          const Divider(height: 4),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
          pageSectionGap,
        ],
      );

  Widget _colorField(String label, TextEditingController c, {double width = 170}) => SizedBox(
        width: width,
        child: TextField(
          controller: c,
          maxLength: 7,
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            labelText: label,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _parse(c.text, Colors.transparent),
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          onChanged: (_) => setState(() => _dirty = true),
        ),
      );

  Widget _imageSlot(String label, _ImageSlot slot) {
    Widget preview;
    if (slot.bytes != null) {
      preview = Image.memory(slot.bytes!, fit: BoxFit.contain);
    } else if (slot.saved != null && !slot.remove) {
      preview = Image.network(api.badgeFileUrl(widget.eventId, slot.saved!),
          headers: api.badgeFileHeaders,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined));
    } else {
      preview = const Icon(Icons.image_outlined, size: 36, color: Colors.black26);
    }
    return SizedBox(
      width: 160,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 100,
          width: 160,
          decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.black12)),
          alignment: Alignment.center,
          child: preview,
        ),
        Row(children: [
          TextButton(onPressed: () => _pick(slot), child: Text(slot.hasImage ? 'Replace' : 'Upload')),
          if (slot.hasImage)
            TextButton(
              onPressed: () => setState(() {
                slot.bytes = null;
                slot.name = null;
                slot.remove = slot.saved != null;
                _dirty = true;
              }),
              child: const Text('Remove'),
            ),
        ]),
      ]),
    );
  }

  Widget _typeRow(String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
              width: 90,
              child: Text(badgeTypeLabels[type]!, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (type != 'athlete')
            SizedBox(
              width: 140,
              child: TextField(
                controller: _typeLabel[type],
                maxLength: 20,
                decoration: const InputDecoration(isDense: true, counterText: '', labelText: 'Tag label'),
                onChanged: (_) => _changed(),
              ),
            ),
          if (type != 'athlete') _colorField('Tag colour', _typeColor[type]!, width: 140),
          if (type == 'athlete')
            const Text('Tag shows gender: FEMALE red, MALE green',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
        if (_areas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 6, runSpacing: 4, children: [
              for (var i = 1; i <= _areas.length; i++)
                FilterChip(
                  visualDensity: VisualDensity.compact,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: pageBlue,
                  label: Text('$i'),
                  tooltip: _areas[i - 1].text,
                  selected: _typeAreas[type]!.contains(i),
                  onSelected: (on) => setState(() {
                    on ? _typeAreas[type]!.add(i) : _typeAreas[type]!.remove(i);
                    _dirty = true;
                  }),
                ),
            ]),
          ),
        const Divider(height: 16),
      ]),
    );
  }
}
