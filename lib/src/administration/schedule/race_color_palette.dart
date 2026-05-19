import 'package:flutter/material.dart';

/// Categories and known values that get colour chips on each Grid row.
/// Default colours are reasonable Material 500-level swatches; operators
/// can override per-event via Setup → Race row colours (persisted in
/// events.color_map).
class RaceColorPalette {
  static const Map<String, List<String>> categoryValues = {
    'boat': ['Standard', 'Small'],
    'age': ['Junior', 'Junior A', 'Junior B', 'U24', 'Premier', 'Senior A', 'Senior B', 'Senior C', 'Senior D', 'BCP', 'ACP'],
    'gender': ['Open', 'Women', 'Mixed'],
    'distance': ['100m', '200m', '250m', '500m', '1000m', '2000m'],
    // Stage TYPE (not full name). "Round 1"/"Round 2" both → 'Round'.
    // "Repechage 1"/"Repechage 2" both → 'Repechage'. Etc.
    'stage': ['Round', 'Heat', 'Repechage', 'Semi', 'Grand Final', 'Minor Final', 'Tail Final'],
  };

  static const Map<String, String> categoryLabels = {
    'boat': 'Boat group',
    'age': 'Age group',
    'gender': 'Gender',
    'distance': 'Distance',
    'stage': 'Stage type',
  };

  /// Stable defaults — used when the event has no per-value override.
  static const Map<String, Map<String, int>> defaultColors = {
    'boat': {
      'Standard': 0xFF1976D2, // blue
      'Small': 0xFF7B1FA2,    // purple
    },
    'age': {
      'Junior': 0xFF388E3C,    // green
      'Junior A': 0xFF66BB6A,  // lighter green
      'Junior B': 0xFFAED581,  // even lighter green
      'U24': 0xFF00ACC1,       // cyan
      'Premier': 0xFFD32F2F,   // red
      'Senior A': 0xFFF57C00,  // orange
      'Senior B': 0xFFFBC02D,  // amber
      'Senior C': 0xFFFFA726,  // light orange
      'Senior D': 0xFFFFCC80,  // pale orange
      'BCP': 0xFF5D4037,       // brown
      'ACP': 0xFF455A64,       // blue-grey
    },
    'gender': {
      'Open': 0xFF1565C0,   // dark blue
      'Women': 0xFFC2185B,  // pink
      'Mixed': 0xFF6D4C41,  // brown
    },
    'distance': {
      '100m':  0xFFB39DDB, // light purple
      '200m':  0xFF7E57C2, // purple
      '250m':  0xFF26A69A, // teal
      '500m':  0xFF42A5F5, // lighter blue
      '1000m': 0xFF66BB6A, // green
      '2000m': 0xFFEF6C00, // dark orange
    },
    'stage': {
      'Round': 0xFF1976D2,        // blue
      'Heat': 0xFF388E3C,         // green
      'Repechage': 0xFFF57C00,    // orange
      'Semi': 0xFF7B1FA2,         // purple
      'Grand Final': 0xFFFFC107,  // gold
      'Minor Final': 0xFF9E9E9E,  // grey
      'Tail Final': 0xFF607D8B,   // blue-grey
    },
  };

  /// Limited palette for the in-app picker (no external dependency).
  static const List<int> swatchPalette = [
    0xFFE53935, 0xFFD81B60, 0xFF8E24AA, 0xFF5E35B1,
    0xFF3949AB, 0xFF1E88E5, 0xFF039BE5, 0xFF00ACC1,
    0xFF00897B, 0xFF43A047, 0xFF7CB342, 0xFFC0CA33,
    0xFFFDD835, 0xFFFFB300, 0xFFFB8C00, 0xFFF4511E,
    0xFF6D4C41, 0xFF757575, 0xFF546E7A, 0xFF263238,
  ];

  /// Resolve the colour for (category, value) — operator override wins,
  /// otherwise default, otherwise a neutral grey so a chip still renders.
  static Color resolve(
    Map<String, Map<String, String>> overrides,
    String category,
    String? value,
  ) {
    if (value == null || value.isEmpty) return const Color(0xFFBDBDBD);
    final hex = overrides[category]?[value];
    if (hex != null) {
      final parsed = _parseHex(hex);
      if (parsed != null) return parsed;
    }
    final def = defaultColors[category]?[value];
    if (def != null) return Color(def);
    return const Color(0xFFBDBDBD);
  }

  /// "Round 1" / "Round 2" → "Round"; "Repechage 2" → "Repechage"; etc.
  /// Leaves names without a trailing number untouched.
  static String stageType(String? stage) {
    if (stage == null) return '';
    final trimmed = stage.trim();
    if (trimmed.isEmpty) return '';
    final match = RegExp(r'^(.*?)\s+\d+$').firstMatch(trimmed);
    return match != null ? match.group(1)! : trimmed;
  }

  static Color? _parseHex(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  static String toHex(Color c) {
    final argb = c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${argb.substring(2)}';
  }
}
