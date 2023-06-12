import 'dart:convert';

class User {
  int? id;
  String? name;
  String? email;
  dynamic emailVerifiedAt;
  int? accessLevel;
  int? clubId;
  int? eventId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? password;
  String? password_confirmation;

  User({
    this.id,
    this.name,
    this.email,
    this.emailVerifiedAt,
    this.accessLevel,
    this.clubId,
    this.eventId,
    this.createdAt,
    this.updatedAt,
    this.password,
    this.password_confirmation
  });

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, emailVerifiedAt: $emailVerifiedAt, accessLevel: $accessLevel, clubId: $clubId, eventId: $eventId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  factory User.fromMap(Map<String, dynamic> data) => User(
        id: data['id'] as int?,
        password: data['password'] as String?,
        password_confirmation: data['password_confirmation'] as String?,
        name: data['name'] as String?,
        email: data['email'] as String?,
        emailVerifiedAt: data['email_verified_at'] as dynamic,
        accessLevel: data['access_level'] as int?,
        clubId: data['club_id'] as int?,
        eventId: data['event_id'] as int?,
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
        'email': email,
        'email_verified_at': emailVerifiedAt,
        'access_level': accessLevel,
        'club_id': clubId,
        'event_id': eventId,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'password' : password,
        'password_confirmation' : password_confirmation
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [User].
  factory User.fromJson(String data) {
    return User.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [User] to a JSON string.
  String toJson() => json.encode(toMap());
}
