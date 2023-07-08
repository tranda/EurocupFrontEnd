import 'dart:convert';

class AthlereQrCode {
  int? id;
  int? clubId;

  AthlereQrCode({this.id, this.clubId});

  @override
  String toString() => 'AthlereQrCode(id: $id, clubId: $clubId)';

  factory AthlereQrCode.fromMap(Map<String, dynamic> data) => AthlereQrCode(
        id: data['id'] as int?,
        clubId: data['club_id'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'club_id': clubId,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [AthlereQrCode].
  factory AthlereQrCode.fromJson(String data) {
    return AthlereQrCode.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [AthlereQrCode] to a JSON string.
  String toJson() => json.encode(toMap());
}
