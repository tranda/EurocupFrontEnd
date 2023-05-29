import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:eurocup_frontend/src/common.dart';

class Athlete {
  int? id;
  int? clubId;
  String? firstName;
  String? lastName;
  String? birthDate;
  String? gender;
  String? photo;
  DateTime? createdAt;
  DateTime? updatedAt;
  String photoBase64 = '';

  Athlete({
    this.id,
    this.clubId,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.gender,
    this.photo,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String toString() {
    return 'Athlete(id: $id, clubId: $clubId, firstName: $firstName, lastName: $lastName, birthDate: $birthDate, gender: $gender, photo: $photo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  factory Athlete.fromMap(Map<String, dynamic> data) => Athlete(
        id: data['id'] as int?,
        clubId: data['club_id'] as int?,
        firstName: data['first_name'] as String?,
        lastName: data['last_name'] as String?,
        birthDate: data['birth_date'] as String?,
        gender: data['gender'] as String?,
        photo: data['photo'] as String?,
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
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate,
        'gender': gender,
        'photo': photo,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Athlete].
  factory Athlete.fromJson(String data) {
    return Athlete.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [Athlete] to a JSON string.
  String toJson() => json.encode(toMap());

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! Athlete) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    return mapEquals(other.toMap(), toMap());
  }

  @override
  int get hashCode =>
      id.hashCode ^
      clubId.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      birthDate.hashCode ^
      gender.hashCode ^
      photo.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  Future<String> convertPhotoBase64() async {
    if (photo != '') {
      try {
        print('https://$imagePrefix/$photo');
        http.Response response =
            await http.get(Uri.parse('https://$imagePrefix/$photo'));
        final bytes = response.bodyBytes;
        photoBase64 = base64Encode(bytes);
      } catch (e) {
        print(e);
      }
    }
    return (photoBase64);
  }
}
