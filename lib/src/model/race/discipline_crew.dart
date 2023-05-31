import 'dart:convert';

import 'crew.dart';
import 'team.dart';

class DisciplineCrew {
  Team? team;
  Crew? crew;

  DisciplineCrew({this.team, this.crew});

  factory DisciplineCrew.fromMap(Map<String, dynamic> data) {
    return DisciplineCrew(
      team: data['team'] == null
          ? null
          : Team.fromMap(data['team'] as Map<String, dynamic>),
      crew: data['crew'] == null
          ? null
          : Crew.fromMap(data['crew'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() => {
        'team': team?.toMap(),
        'crew': crew?.toMap(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [DisciplineCrew].
  factory DisciplineCrew.fromJson(String data) {
    return DisciplineCrew.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [DisciplineCrew] to a JSON string.
  String toJson() => json.encode(toMap());
}
