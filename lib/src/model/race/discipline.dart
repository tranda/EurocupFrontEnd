import 'dart:convert';

class Discipline {
  int? id;
  int? eventId;
  int? distance;
  String? ageGroup;
  String? genderGroup;
  String? boatGroup;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? teamsCount;

  Discipline({
    this.id,
    this.eventId,
    this.distance,
    this.ageGroup,
    this.genderGroup,
    this.boatGroup,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.teamsCount,
  });

  factory Discipline.fromMap(Map<String, dynamic> data) => Discipline(
        id: data['id'] as int?,
        eventId: data['event_id'] as int?,
        distance: data['distance'] as int?,
        ageGroup: data['age_group'] as String?,
        genderGroup: data['gender_group'] as String?,
        boatGroup: data['boat_group'] as String?,
        status: data['status'] as String?,
        createdAt: data['created_at'] == null
            ? null
            : DateTime.parse(data['created_at'] as String),
        updatedAt: data['updated_at'] == null
            ? null
            : DateTime.parse(data['updated_at'] as String),
        teamsCount: data['teams_count'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'event_id': eventId,
        'distance': distance,
        'age_group': ageGroup,
        'gender_group': genderGroup,
        'boat_group': boatGroup,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'teams_count': teamsCount,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Discipline].
  factory Discipline.fromJson(String data) {
    return Discipline.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Discipline] to a JSON string.
  String toJson() => json.encode(toMap());

  String getDisplayName() {
    return ('$boatGroup $ageGroup $genderGroup ${distance}m');
  }
}
