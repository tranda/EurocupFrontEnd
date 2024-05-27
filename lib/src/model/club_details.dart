import 'dart:convert';

class ClubDetails {
  final int? total;
  final int? male;
  final int? female;
  final int? junior;
  final int? juniorEC;
  final int? u24;
  final int? u24EC;
  final int? premier;
  final int? premierEC;
  final int? seniorA;
  final int? seniorAEC;
  final int? seniorB;
  final int? seniorBEC;
  final int? seniorC;
  final int? seniorCEC;
  final int? seniorD;
  final int? seniorDEC;
  final int? bcp;
  final int? eurocup;
  final int? pfestival;
  final int? withCertificate;

  const ClubDetails({
    this.total,
    this.male,
    this.female,
      this.junior,
      this.juniorEC,
      this.u24,
      this.u24EC,
      this.premier,
      this.premierEC,
      this.seniorA,
      this.seniorAEC,
      this.seniorB,
      this.seniorBEC,
      this.seniorC,
      this.seniorCEC,
      this.seniorD,
      this.seniorDEC,
    this.bcp,
    this.eurocup,
    this.pfestival,
    this.withCertificate
  });

  @override
  String toString() {
    return 'ClubDetails(total: $total, male: $male, female: $female, junior: $junior, u24: $u24, premier: $premier, seniorA: $seniorA, seniorB: $seniorB, seniorC: $seniorC, seniorD: $seniorD, bcp: $bcp, eurocup: $eurocup, festival: $pfestival)';
  }

  factory ClubDetails.fromMap(Map<String, dynamic> data) => ClubDetails(
        total: data['Total'] as int?,
        male: data['Male'] as int?,
        female: data['Female'] as int?,
      junior: data['Junior'] as int?,
      juniorEC: data['Junior EC'] as int?,
      u24: data['U24'] as int?,
      u24EC: data['U24 EC'] as int?,
      premier: data['Premier'] as int?,
      premierEC: data['Premier EC'] as int?,
      seniorA: data['Senior A'] as int?,
      seniorAEC: data['Senior A EC'] as int?,
      seniorB: data['Senior B'] as int?,
      seniorBEC: data['Senior B EC'] as int?,
      seniorC: data['Senior C'] as int?,
      seniorCEC: data['Senior C EC'] as int?,
      seniorD: data['Senior D'] as int?,
      seniorDEC: data['Senior D EC'] as int?,
        bcp: data['BCP'] as int?,
        eurocup: data['Eurocup'] as int?,
        pfestival: data['plus Festival'] as int?,
        withCertificate: data['withCertificate'] as int?
      );

  Map<String, dynamic> toMap() => {
        'Total': total,
        'Male': male,
        'Female': female,
        'Junior': junior,
        'Junior EC': junior,
        'U24': u24,
        'U24 EC': u24,
        'Premier': premier,
        'Premier EC': premier,
        'Senior A': seniorA,
        'Senior A EC': seniorA,
        'Senior B': seniorB,
        'Senior B EC': seniorB,
        'Senior C': seniorC,
        'Senior C EC': seniorC,
        'Senior D': seniorD,
        'Senior D EC': seniorD,
        'BCP': bcp,
        'Eurocup': eurocup,
        'Festival': pfestival,
        'withCertificate': withCertificate
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
