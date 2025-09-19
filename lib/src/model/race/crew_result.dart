import 'dart:convert';
import 'crew.dart';
import 'team.dart';

class CrewResult {
  int? id;
  int? crewId;
  int? raceResultId;
  int? lane;
  int? position;
  int? timeMs; // Time in milliseconds or null if DNS/DNF
  String? delayAfterFirst; // Format: "+2.44" or null if first place
  String? status; // "FINISHED", "DNS", "DNF", "DSQ"
  Crew? crew;
  Team? team;
  DateTime? createdAt;
  DateTime? updatedAt;

  CrewResult({
    this.id,
    this.crewId,
    this.raceResultId,
    this.lane,
    this.position,
    this.timeMs,
    this.delayAfterFirst,
    this.status,
    this.crew,
    this.team,
    this.createdAt,
    this.updatedAt,
  });

  factory CrewResult.fromMap(Map<String, dynamic> data) => CrewResult(
        id: data['id'] as int?,
        crewId: data['crew_id'] as int?,
        raceResultId: data['race_result_id'] as int?,
        lane: data['lane'] as int?,
        position: data['position'] as int?,
        timeMs: data['time_ms'] as int?,
        delayAfterFirst: data['delay_after_first'] as String?,
        status: data['status'] as String?,
        crew: data['crew'] == null
            ? null
            : Crew.fromMap(data['crew'] as Map<String, dynamic>),
        team: data['team'] == null
            ? null
            : Team.fromMap(data['team'] as Map<String, dynamic>),
        createdAt: data['created_at'] == null
            ? null
            : DateTime.parse(data['created_at'] as String),
        updatedAt: data['updated_at'] == null
            ? null
            : DateTime.parse(data['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'crew_id': crewId,
        'race_result_id': raceResultId,
        'lane': lane,
        'position': position,
        'time_ms': timeMs,
        'delay_after_first': delayAfterFirst,
        'status': status,
        'crew': crew?.toMap(),
        'team': team?.toMap(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory CrewResult.fromJson(String data) {
    return CrewResult.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  bool get isFinished => status == 'FINISHED' && timeMs != null;
  bool get didNotStart => status == 'DNS';
  bool get didNotFinish => status == 'DNF';
  bool get isDisqualified => status == 'DSQ';
  
  String get displayTime {
    if (didNotStart) return 'DNS';
    if (didNotFinish) return 'DNF';
    if (isDisqualified) return 'DSQ';
    if (timeMs == null && status == null) return 'Registered';
    if (timeMs == null) return '-';
    
    // Convert milliseconds to MM:SS.mmm format
    final totalMs = timeMs!;
    final minutes = totalMs ~/ 60000;
    final seconds = (totalMs % 60000) ~/ 1000;
    final milliseconds = totalMs % 1000;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';
  }

  String get displayDelay {
    if (!isFinished || position == 1) return '';
    return delayAfterFirst ?? '';
  }
}