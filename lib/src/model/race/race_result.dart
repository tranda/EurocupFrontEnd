import 'dart:convert';
import 'discipline.dart';
import 'crew_result.dart';

class RaceResult {
  int? id;
  int? raceNumber;
  int? disciplineId;
  int? eventId;
  DateTime? raceTime;
  /// Hull letter assigned by the generator (e.g. "D"). Null when the event
  /// has no fleet configured or the discipline's boat_group isn't mapped.
  String? hull;
  String? stage; // "Round x", "Heat x", "Semifinal x", "Repechage x", "Minor Final", "Grand Final", "Final"
  String? status; // "SCHEDULED", "IN_PROGRESS", "FINISHED", "CANCELLED"
  bool? isFinalRound; // Indicates if this is the final round
  bool? showAccumulatedTime; // Indicates if accumulated/total times should be shown
  List<CrewResult>? crewResults;
  Discipline? discipline;
  List<String>? images; // Array of image filenames to be displayed below the race
  // Break-only fields (entryType == 'break').
  String entryType; // 'race' | 'break'
  int? durationSeconds;
  String? label;
  bool shiftSubsequent;
  // Per-race admin override of the auto-derived progression rule.
  // Null/empty = use the auto rule (server returns it as progressionRule).
  String? progressionNote;
  // Auto-derived "where do these crews go next" line, computed by the
  // server. Always populated for races (empty string when no rule applies);
  // overridden by progressionNote when set.
  String? progressionRule;
  DateTime? createdAt;
  DateTime? updatedAt;

  RaceResult({
    this.id,
    this.raceNumber,
    this.disciplineId,
    this.eventId,
    this.raceTime,
    this.hull,
    this.stage,
    this.status,
    this.isFinalRound,
    this.showAccumulatedTime,
    this.crewResults,
    this.discipline,
    this.images,
    this.entryType = 'race',
    this.durationSeconds,
    this.label,
    this.shiftSubsequent = true,
    this.progressionNote,
    this.progressionRule,
    this.createdAt,
    this.updatedAt,
  });

  bool get isBreak => entryType == 'break';

  factory RaceResult.fromMap(Map<String, dynamic> data) => RaceResult(
        id: data['id'] as int?,
        raceNumber: data['race_number'] as int?,
        disciplineId: data['discipline_id'] as int?,
        eventId: data['event_id'] as int?,
        raceTime: data['race_time'] == null
            ? null
            : DateTime.parse(data['race_time'] as String),
        hull: data['hull'] as String?,
        stage: data['stage'] as String?,
        status: data['status'] as String?,
        isFinalRound: data['is_final_round'] as bool?,
        showAccumulatedTime: data['show_accumulated_time'] as bool?,
        crewResults: (data['crew_results'] as List<dynamic>?)
            ?.map((e) => CrewResult.fromMap(e as Map<String, dynamic>))
            .toList(),
        discipline: data['discipline'] == null
            ? null
            : Discipline.fromMap(data['discipline'] as Map<String, dynamic>),
        images: (data['images'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        entryType: (data['entry_type'] as String?) ?? 'race',
        durationSeconds: data['duration_seconds'] as int?,
        label: data['label'] as String?,
        shiftSubsequent: data['shift_subsequent'] == null
            ? true
            : (data['shift_subsequent'] == true || data['shift_subsequent'] == 1),
        progressionNote: data['progression_note'] as String?,
        progressionRule: data['progression_rule'] as String?,
        createdAt: data['created_at'] == null
            ? null
            : DateTime.parse(data['created_at'] as String),
        updatedAt: data['updated_at'] == null
            ? null
            : DateTime.parse(data['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'race_number': raceNumber,
        'discipline_id': disciplineId,
        'event_id': eventId,
        'race_time': raceTime?.toIso8601String(),
        'hull': hull,
        'stage': stage,
        'status': status,
        'is_final_round': isFinalRound,
        'show_accumulated_time': showAccumulatedTime,
        'crew_results': crewResults?.map((e) => e.toMap()).toList(),
        'discipline': discipline?.toMap(),
        'images': images,
        'entry_type': entryType,
        'duration_seconds': durationSeconds,
        'label': label,
        'shift_subsequent': shiftSubsequent,
        'progression_note': progressionNote,
        'progression_rule': progressionRule,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory RaceResult.fromJson(String data) {
    return RaceResult.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());

  bool get isFinished => status == 'FINISHED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isScheduled => status == 'SCHEDULED';
  bool get isCancelled => status == 'CANCELLED';

  int get finishedCrewsCount => 
      crewResults?.where((crew) => crew.isFinished).length ?? 0;

  int get totalCrewsCount => crewResults?.length ?? 0;

  String get statusDisplay {
    switch (status) {
      case 'FINISHED':
        return '$finishedCrewsCount crews finished';
      case 'IN_PROGRESS':
        return 'In progress';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  String get raceTimeDisplay {
    if (raceTime == null) return '';
    return '${raceTime!.hour.toString().padLeft(2, '0')}:${raceTime!.minute.toString().padLeft(2, '0')}';
  }

  String get title {
    return discipline?.getDisplayName() ?? 'Unknown Race';
  }
}