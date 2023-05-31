import 'dart:convert';

import 'discipline.dart';
import 'discipline_crew.dart';

class Race {
  Discipline? discipline;
  List<DisciplineCrew>? disciplineCrews;

  Race({this.discipline, this.disciplineCrews});

  factory Race.fromMap(Map<String, dynamic> data) => Race(
        discipline: data['discipline'] == null
            ? null
            : Discipline.fromMap(data['discipline'] as Map<String, dynamic>),
        disciplineCrews: (data['discipline_crews'] as List<dynamic>?)
            ?.map((e) => DisciplineCrew.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'discipline': discipline?.toMap(),
        'discipline_crews': disciplineCrews?.map((e) => e.toMap()).toList(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Race].
  factory Race.fromJson(String data) {
    return Race.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Race] to a JSON string.
  String toJson() => json.encode(toMap());
}
