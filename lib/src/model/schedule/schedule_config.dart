import 'event_day.dart';

class ScheduleConfig {
  final int eventId;
  final int laneCount;
  final String scheduleStatus; // "draft" | "published"
  final DateTime? schedulePublishedAt;
  final List<EventDay> days;

  ScheduleConfig({
    required this.eventId,
    required this.laneCount,
    required this.scheduleStatus,
    this.schedulePublishedAt,
    this.days = const [],
  });

  bool get isPublished => scheduleStatus == 'published';

  factory ScheduleConfig.fromMap(Map<String, dynamic> data) => ScheduleConfig(
        eventId: (data['event_id'] ?? 0) as int,
        laneCount: (data['lane_count'] ?? 6) as int,
        scheduleStatus: (data['schedule_status'] ?? 'draft') as String,
        schedulePublishedAt: data['schedule_published_at'] == null
            ? null
            : DateTime.parse(data['schedule_published_at'] as String),
        days: (data['days'] as List<dynamic>? ?? [])
            .map((d) => EventDay.fromMap(d as Map<String, dynamic>))
            .toList(),
      );
}
