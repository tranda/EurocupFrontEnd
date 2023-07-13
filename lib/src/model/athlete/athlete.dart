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
  String? category;
  String? eurocup;
  String? certificate;
  bool? checked;
  int? edbfId;
  String? documentNo;
  bool? leftSide;
  bool? rightSide;
  bool? helm;
  bool? drummer;

  Athlete(
      {this.id,
      this.clubId,
      this.firstName,
      this.lastName,
      this.birthDate,
      this.gender,
      this.category,
      this.photo,
      this.createdAt,
      this.updatedAt,
      this.eurocup,
      this.certificate,
      this.checked,
      this.edbfId,
      this.documentNo,
      this.leftSide,
      this.rightSide,
      this.helm,
      this.drummer});

  Athlete.edbf(List<String> headers, List<String> data) {
    // var index = (headers).indexOf('_checked_');
    checked = data[0] == '1'
        ? true
        : false; //data[(headers).indexOf('_checked_')] as bool;
    edbfId = int.parse(data[(headers).indexOf('id')]);
    lastName = trimQuotes(data[(headers).indexOf('last_name')]);
    firstName = trimQuotes(data[(headers).indexOf('first_name')]);
    gender = data[(headers).indexOf('gender')] == 'M' ? "Male" : 'Female';
    birthDate = trimQuotes(data[(headers).indexOf('birth_date')]);
    documentNo = trimQuotes(data[(headers).indexOf('document_no')]);
    leftSide = data[(headers).indexOf('left_side')] == 'x' ? true : false;
    rightSide = data[(headers).indexOf('right_side')] == 'x' ? true : false;
    helm = data[(headers).indexOf('helm')] == 'x' ? true : false;
    drummer = data[(headers).indexOf('drummer')] == 'x' ? true : false;
    category = trimQuotes(data[(headers).indexOf('divs')]);
  }

  String? trimQuotes(String? s) {
    if ((s != null && s != '')) {
      return s.replaceAll("\"", "").trim();
    } else {
      return s;
    }
  }

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
        category: data['category'] as String?,
        photo: data['photo'] as String?,
        createdAt: data['created_at'] == null
            ? null
            : DateTime.parse(data['created_at'] as String),
        updatedAt: data['updated_at'] == null
            ? null
            : DateTime.parse(data['updated_at'] as String),
        eurocup: data['eurocup'] as String?,
        certificate: data['certificate'] as String?,
        checked: data['_checked_'] as bool?,
        edbfId: data['edbf_id'] as int?,
        documentNo: data['document_no'] as String?,
        leftSide: data['left_side'] == '1' ? true : false,
        rightSide: data['left_side'] == '1' ? true : false,
        helm: data['left_side'] == '1' ? true : false,
        drummer: data['left_side'] == '1' ? true : false
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'club_id': clubId,
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate,
        'gender': gender,
        'category': category,
        'photo': photo,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'eurocup': eurocup,
        'certificate': certificate,
        '_checked_': checked ?? false,
        'edbf_id': edbfId,
        'document_no': documentNo,
        'left_side': leftSide,
        'right_side': rightSide,
        'helm': helm,
        'drummer': drummer
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

  String getDisplayName() {
    return ('$firstName $lastName');
  }

  String getDisplayDetail() {
    return ('$firstName $lastName ($gender)');
  }
}
