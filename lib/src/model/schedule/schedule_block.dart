class ScheduleBlock {
  final int id;
  final int eventDayId;
  final String name;
  final String startTime; // "HH:mm" or "HH:mm:ss"
  final int gapSeconds;
  final List<String>? genderFilter;
  final List<String>? distanceFilter;
  final List<String>? stageFilter;
  final int sortOrder;

  ScheduleBlock({
    required this.id,
    required this.eventDayId,
    required this.name,
    required this.startTime,
    required this.gapSeconds,
    this.genderFilter,
    this.distanceFilter,
    this.stageFilter,
    this.sortOrder = 0,
  });

  factory ScheduleBlock.fromMap(Map<String, dynamic> data) => ScheduleBlock(
        id: data['id'] as int,
        eventDayId: (data['event_day_id'] ?? 0) as int,
        name: (data['name'] ?? '') as String,
        startTime: (data['start_time'] ?? '') as String,
        gapSeconds: (data['gap_seconds'] ?? 240) as int,
        genderFilter: _stringListOrNull(data['gender_filter']),
        distanceFilter: _stringListOrNull(data['distance_filter']),
        stageFilter: _stringListOrNull(data['stage_filter']),
        sortOrder: (data['sort_order'] ?? 0) as int,
      );

  static List<String>? _stringListOrNull(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return null;
  }
}
