import 'schedule_block.dart';

class EventDay {
  final int id;
  final int eventId;
  final DateTime date;
  final String? name;
  final int sortOrder;
  final List<ScheduleBlock> blocks;

  EventDay({
    required this.id,
    required this.eventId,
    required this.date,
    this.name,
    this.sortOrder = 0,
    this.blocks = const [],
  });

  factory EventDay.fromMap(Map<String, dynamic> data) => EventDay(
        id: data['id'] as int,
        eventId: (data['event_id'] ?? 0) as int,
        date: DateTime.parse(data['date'] as String),
        name: data['name'] as String?,
        sortOrder: (data['sort_order'] ?? 0) as int,
        blocks: (data['blocks'] as List<dynamic>? ?? [])
            .map((b) => ScheduleBlock.fromMap(b as Map<String, dynamic>))
            .toList(),
      );
}
