import 'dart:typed_data';

import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'badges_page.dart' show badgeTypeLabels;

/// Add or edit a non-crew badge person (volunteer, VIP, media, staff).
/// Pops true when saved.
class BadgePersonDialog extends StatefulWidget {
  const BadgePersonDialog({super.key, required this.eventId, this.person});

  final int eventId;
  final Map<String, dynamic>? person;

  @override
  State<BadgePersonDialog> createState() => _BadgePersonDialogState();
}

class _BadgePersonDialogState extends State<BadgePersonDialog> {
  final _form = GlobalKey<FormState>();
  late String _type = (widget.person?['type'] ?? 'volunteer') as String;
  late final _first = TextEditingController(text: (widget.person?['first_name'] ?? '') as String);
  late final _last = TextEditingController(text: (widget.person?['last_name'] ?? '') as String);
  late final _org = TextEditingController(text: (widget.person?['organisation'] ?? '') as String);
  late final _country = TextEditingController(text: (widget.person?['country'] ?? '') as String);
  late final String? _savedPhoto = widget.person?['photo'] as String?;
  Uint8List? _photo;
  String? _photoName;
  bool _removePhoto = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _org, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    final f = r?.files.single;
    if (f?.bytes == null) return;
    if (f!.bytes!.length > 8 * 1024 * 1024) {
      setState(() => _error = 'Photo is larger than 8 MB.');
      return;
    }
    setState(() {
      _photo = f.bytes;
      _photoName = f.name;
      _removePhoto = false;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await api.saveBadgePerson(
        widget.eventId,
        personId: widget.person?['id'] as int?,
        type: _type,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        organisation: _org.text.trim(),
        country: _country.text.trim(),
        photo: _photo,
        photoName: _photoName,
        removePhoto: _removePhoto,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSaved = _savedPhoto != null && !_removePhoto;
    Widget photo;
    if (_photo != null) {
      photo = Image.memory(_photo!, fit: BoxFit.cover);
    } else if (hasSaved) {
      photo = Image.network(api.badgeFileUrl(widget.eventId, _savedPhoto!),
          headers: api.badgeFileHeaders, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined));
    } else {
      photo = const Icon(Icons.person, size: 48, color: Colors.black26);
    }

    return AlertDialog(
      title: Text(widget.person == null ? 'Add badge person' : 'Edit badge person'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Badge type'),
                items: [
                  for (final e in badgeTypeLabels.entries)
                    if (e.key != 'athlete') DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              TextFormField(
                controller: _first,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'First name', counterText: ''),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _last,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Last name', counterText: ''),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _org,
                maxLength: 150,
                decoration: const InputDecoration(
                    labelText: 'Organisation', helperText: 'Shown in the footer, e.g. EDBF, RTS, Volunteers', counterText: ''),
              ),
              TextFormField(
                controller: _country,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Country', counterText: ''),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  width: 75,
                  height: 100,
                  decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.black12)),
                  clipBehavior: Clip.hardEdge,
                  child: photo,
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(_photo != null || hasSaved ? 'Replace photo' : 'Add photo'),
                  ),
                  if (_photo != null || hasSaved)
                    TextButton(
                      onPressed: () => setState(() {
                        _photo = null;
                        _photoName = null;
                        _removePhoto = _savedPhoto != null;
                      }),
                      child: const Text('Remove photo'),
                    ),
                ]),
              ]),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
