import 'dart:convert';
import 'discipline.dart';
import 'crew_result.dart';

class RaceResult {
  int? id;
  int? raceNumber;
  int? disciplineId;
  DateTime? raceTime;
  String? stage; // "Round x", "Heat x", "Semifinal x", "Repechage x", "Minor Final", "Grand Final", "Final"
  String? status; // "SCHEDULED", "IN_PROGRESS", "FINISHED", "CANCELLED"
  bool? isFinalRound; // Indicates if this is the final round
  List<CrewResult>? crewResults;
  Discipline? discipline;
  DateTime? createdAt;
  DateTime? updatedAt;

  RaceResult({
    this.id,
    this.raceNumber,
    this.disciplineId,
    this.raceTime,
    this.stage,
    this.status,
    this.isFinalRound,
    this.crewResults,
    this.discipline,
    this.createdAt,
    this.updatedAt,
  });

  factory RaceResult.fromMap(Map<String, dynamic> data) => RaceResult(
        id: data['id'] as int?,
        raceNumber: data['race_number'] as int?,
        disciplineId: data['discipline_id'] as int?,
        raceTime: data['race_time'] == null
            ? null
            : DateTime.parse(data['race_time'] as String),
        stage: data['stage'] as String?,
        status: data['status'] as String?,
        isFinalRound: data['is_final_round'] as bool?,
        crewResults: (data['crew_results'] as List<dynamic>?)
            ?.map((e) => CrewResult.fromMap(e as Map<String, dynamic>))
            .toList(),
        discipline: data['discipline'] == null
            ? null
            : Discipline.fromMap(data['discipline'] as Map<String, dynamic>),
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
        'race_time': raceTime?.toIso8601String(),
        'stage': stage,
        'status': status,
        'is_final_round': isFinalRound,
        'crew_results': crewResults?.map((e) => e.toMap()).toList(),
        'discipline': discipline?.toMap(),
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