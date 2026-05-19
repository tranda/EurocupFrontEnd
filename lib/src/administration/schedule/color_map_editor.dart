import 'package:flutter/material.dart';

import 'race_color_palette.dart';

/// Card that lists every (category, value) and lets the operator pick a
/// colour from a fixed palette. Calls [onChanged] with the full updated
/// map whenever a swatch is picked. Parent debounces and persists.
class ColorMapEditor extends StatefulWidget {
  final Map<String, Map<String, String>> value;
  final ValueChanged<Map<String, Map<String, String>>> onChanged;
  final bool enabled;

  const ColorMapEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<ColorMapEditor> createState() => _ColorMapEditorState();
}

class _ColorMapEditorState extends State<ColorMapEditor> {
  late Map<String, Map<String, String>> _local;

  @override
  void initState() {
    super.initState();
    _local = _deepCopy(widget.value);
  }

  @override
  void didUpdateWidget(covariant ColorMapEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapsEqual(oldWidget.value, widget.value)) {
      _local = _deepCopy(widget.value);
    }
  }

  Map<String, Map<String, String>> _deepCopy(Map<String, Map<String, String>> src) =>
      {for (final e in src.entries) e.key: Map<String, String>.from(e.value)};

  bool _mapsEqual(Map<String, Map<String, String>> a, Map<String, Map<String, String>> b) {
    if (a.length != b.length) return false;
    for (final cat in a.keys) {
      final av = a[cat] ?? const {};
      final bv = b[cat] ?? const {};
      if (av.length != bv.length) return false;
      for (final k in av.keys) {
        if (av[k] != bv[k]) return false;
      }
    }
    return true;
  }

  Future<void> _pickColor(String category, String value) async {
    final current = RaceColorPalette.resolve(_local, category, value);
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _PaletteDialog(initial: current),
    );
    if (picked == null) return;
    setState(() {
      _local.putIfAbsent(category, () => {});
      _local[category]![value] = RaceColorPalette.toHex(picked);
    });
    widget.onChanged(_deepCopy(_local));
  }

  void _resetCategory(String category) {
    setState(() => _local.remove(category));
    widget.onChanged(_deepCopy(_local));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.palette, color: Color.fromARGB(255, 0, 80, 150)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Race row colours', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Each discipline word in the Grid is rendered with the colour you pick here.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          for (final cat in RaceColorPalette.categoryValues.keys) ...[
            _categorySection(cat),
            const SizedBox(height: 12),
          ],
        ]),
      ),
    );
  }

  Widget _categorySection(String category) {
    final values = RaceColorPalette.categoryValues[category] ?? const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(
          RaceColorPalette.categoryLabels[category] ?? category,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: widget.enabled ? () => _resetCategory(category) : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            minimumSize: const Size(0, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Reset defaults', style: TextStyle(fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final v in values) _valueChip(category, v),
      ]),
    ]);
  }

  Widget _valueChip(String category, String value) {
    final color = RaceColorPalette.resolve(_local, category, value);
    final fg = color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return InkWell(
      onTap: widget.enabled ? () => _pickColor(category, value) : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _PaletteDialog extends StatelessWidget {
  final Color initial;
  const _PaletteDialog({required this.initial});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a colour'),
      content: SizedBox(
        width: 320,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in RaceColorPalette.swatchPalette) _swatch(context, Color(v)),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _swatch(BuildContext context, Color c) {
    final selected = c.toARGB32() == initial.toARGB32();
    return InkWell(
      onTap: () => Navigator.pop(context, c),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(color: Colors.black, width: 3)
              : Border.all(color: Colors.black12, width: 1),
        ),
      ),
    );
  }
}
