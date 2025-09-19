import 'dart:convert';
import 'team.dart';

class Crew {
  int? id;
  int? teamId;
  int? disciplineId;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? capacity;
  Team? team;

  Crew(
      {this.id,
      this.teamId,
      this.disciplineId,
      this.createdAt,
      this.updatedAt,
      this.capacity,
      this.team});

  factory Crew.fromMap(Map<String, dynamic> data) => Crew(
        id: data['id'] as int?,
        teamId: data['team_id'] as int?,
        disciplineId: data['discipline_id'] as int?,
        capacity: data['capacity'] as int?,
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
        'team_id': teamId,
        'discipline_id': disciplineId,
        'capacity': capacity,
        'team': team?.toMap(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Crew].
  factory Crew.fromJson(String data) {
    return Crew.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Crew] to a JSON string.
  String toJson() => json.encode(toMap());
}
