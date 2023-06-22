import 'dart:convert';

class ClubDetails {
  final int? total;
  final int? male;
  final int? female;
  final int? junior;
  final int? u24;
  final int? premier;
  final int? seniorA;
  final int? seniorB;
  final int? seniorC;
  final int? seniorD;
  final int? bcp;
  final int? eurocup;
  final int? festival;

  const ClubDetails({
    this.total,
    this.male,
    this.female,
    this.junior,
    this.u24,
    this.premier,
    this.seniorA,
    this.seniorB,
    this.seniorC,
    this.seniorD,
    this.bcp,
    this.eurocup,
    this.festival,
  });

  @override
  String toString() {
    return 'ClubDetails(total: $total, male: $male, female: $female, junior: $junior, u24: $u24, premier: $premier, seniorA: $seniorA, seniorB: $seniorB, seniorC: $seniorC, seniorD: $seniorD, bcp: $bcp, eurocup: $eurocup, festival: $festival)';
  }

  factory ClubDetails.fromMap(Map<String, dynamic> data) => ClubDetails(
        total: data['Total'] as int?,
        male: data['Male'] as int?,
        female: data['Female'] as int?,
        junior: data['Junior'] as int?,
        u24: data['U24'] as int?,
        premier: data['Premier'] as int?,
        seniorA: data['Senior A'] as int?,
        seniorB: data['Senior B'] as int?,
        seniorC: data['Senior C'] as int?,
        seniorD: data['Senior D'] as int?,
        bcp: data['BCP'] as int?,
        eurocup: data['Eurocup'] as int?,
        festival: data['Festival'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'Total': total,
        'Male': male,
        'Female': female,
        'Junior': junior,
        'U24': u24,
        'Premier': premier,
        'Senior A': seniorA,
        'Senior B': seniorB,
        'Senior C': seniorC,
        'Senior D': seniorD,
        'BCP': bcp,
        'Eurocup': eurocup,
        'Festival': festival,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [ClubDetails].
  factory ClubDetails.fromJson(String data) {
    return ClubDetails.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [ClubDetails] to a JSON string.
  String toJson() => json.encode(toMap());
}
