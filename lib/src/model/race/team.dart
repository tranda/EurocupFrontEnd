import 'dart:convert';

class Team {
  int? id;
  int? clubId;
  String? name;
  DateTime? createdAt;
  DateTime? updatedAt;

  Team({this.id, this.clubId, this.name, this.createdAt, this.updatedAt});

  factory Team.fromMap(Map<String, dynamic> data) => Team(
        id: data['id'] as int?,
        clubId: data['club_id'] as int?,
        name: data['name'] as String?,
        createdAt: data['created_at'] == null
            ? null
            : DateTime.parse(data['created_at'] as String),
        updatedAt: data['updated_at'] == null
            ? null
            : DateTime.parse(data['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'club_id': clubId,
        'name': name,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Team].
  factory Team.fromJson(String data) {
    return Team.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Team] to a JSON string.
  String toJson() => json.encode(toMap());
}
