import 'event_day.dart';

class ScheduleConfig {
  final int eventId;
  final int laneCount;
  /// Comma list of small-boat hull letters, e.g. "D,E,F". Empty = no
  /// hull rotation for small boats on this event.
  final String hullsSmall;
  /// Comma list of standard-boat hull letters, e.g. "A,B,C". Empty = no
  /// hull rotation for standard boats on this event.
  final String hullsStandard;
  final int defaultRounds;
  final int minCrewsPerRace;
  /// Nested: { "boat": { "Standard": "#hex" }, "age": { ... },
  /// "stage": { ... }, "gender": { ... } }. Missing entries fall back to
  /// the frontend's default palette.
  final Map<String, Map<String, String>> colorMap;
  final String scheduleStatus; // "draft" | "published"
  final DateTime? schedulePublishedAt;
  final List<EventDay> days;

  ScheduleConfig({
    required this.eventId,
    required this.laneCount,
    this.hullsSmall = '',
    this.hullsStandard = '',
    this.defaultRounds = 3,
    this.minCrewsPerRace = 3,
    this.colorMap = const {},
    required this.scheduleStatus,
    this.schedulePublishedAt,
    this.days = const [],
  });

  bool get isPublished => scheduleStatus == 'published';

  factory ScheduleConfig.fromMap(Map<String, dynamic> data) => ScheduleConfig(
        eventId: (data['event_id'] ?? 0) as int,
        laneCount: (data['lane_count'] ?? 6) as int,
        hullsSmall: (data['hulls_small'] ?? '') as String,
        hullsStandard: (data['hulls_standard'] ?? '') as String,
        defaultRounds: (data['default_rounds'] ?? 3) as int,
        minCrewsPerRace: (data['min_crews_per_race'] ?? 3) as int,
        colorMap: _parseColorMap(data['color_map']),
        scheduleStatus: (data['schedule_status'] ?? 'draft') as String,
        schedulePublishedAt: data['schedule_published_at'] == null
            ? null
            : DateTime.parse(data['schedule_published_at'] as String),
        days: (data['days'] as List<dynamic>? ?? [])
            .map((d) => EventDay.fromMap(d as Map<String, dynamic>))
            .toList(),
      );

  static Map<String, Map<String, String>> _parseColorMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, Map<String, String>>{};
    raw.forEach((cat, values) {
      if (values is Map) {
        out[cat.toString()] = {
          for (final entry in values.entries) entry.key.toString(): entry.value.toString(),
        };
      }
    });
    return out;
  }
}
