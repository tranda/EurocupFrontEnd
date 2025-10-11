import 'dart:convert';

class Competition {
  final int? id;
  final String? name;
  final String? location;
  final int? year;
  final String? status;
  final int? standardReserves;
  final int? standardMinGender;
  final int? standardMaxGender;
  final int? smallReserves;
  final int? smallMinGender;
  final int? smallMaxGender;
  final DateTime? raceEntriesLock;
  final DateTime? nameEntriesLock;
  final DateTime? crewEntriesLock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Competition({
    this.id,
    this.name,
    this.location,
    this.year,
    this.status,
    this.standardReserves,
    this.standardMinGender,
    this.standardMaxGender,
    this.smallReserves,
    this.smallMinGender,
    this.smallMaxGender,
    this.raceEntriesLock,
    this.nameEntriesLock,
    this.crewEntriesLock,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String toString() {
    return '$name, $location $year';
  }

  /// Returns short name format: [name] [year]
  String getShortName() {
    return '${name ?? 'Event'} ${year ?? DateTime.now().year}';
  }

  factory Competition.fromMap(Map<String, dynamic> data) => Competition(
        id: data['id'] as int?,
        name: data['name'] as String?,
        location: data['location'] as String?,
        year: data['year'] as int?,
        status: data['status'] as String?,
        standardReserves: data['standard_reserves'] as int?,
        standardMinGender: data['standard_min_gender'] as int?,
        standardMaxGender: data['standard_max_gender'] as int?,
        smallReserves: data['small_reserves'] as int?,
        smallMinGender: data['small_min_gender'] as int?,
        smallMaxGender: data['small_max_gender'] as int?,
        raceEntriesLock: data['race_entries_lock'] == null
            ? null
            : DateTime.parse(data['race_entries_lock'] as String),
        nameEntriesLock: data['name_entries_lock'] == null
            ? null
            : DateTime.parse(data['name_entries_lock'] as String),
        crewEntriesLock: data['crew_entries_lock'] == null
            ? null
            : DateTime.parse(data['crew_entries_lock'] as String),
        createdAt: data['created_at'] == null
            ? null
            : DateTime.parse(data['created_at'] as String),
        updatedAt: data['updated_at'] == null
            ? null
            : DateTime.parse(data['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'year': year,
        'status': status,
        'standard_reserves': standardReserves,
        'standard_min_gender': standardMinGender,
        'standard_max_gender': standardMaxGender,
        'small_reserves': smallReserves,
        'small_min_gender': smallMinGender,
        'small_max_gender': smallMaxGender,
        'race_entries_lock': raceEntriesLock?.toIso8601String(),
        'name_entries_lock': nameEntriesLock?.toIso8601String(),
        'crew_entries_lock': crewEntriesLock?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Competition].
  factory Competition.fromJson(String data) {
    return Competition.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Competition] to a JSON string.
  String toJson() => json.encode(toMap());
}
