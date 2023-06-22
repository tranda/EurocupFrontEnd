import 'dart:convert';

class Club {
  final int? id;
  final String? name;
  final String? country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Club({
    this.id,
    this.name,
    this.country,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String toString() {
    return 'Club(id: $id, name: $name, country: $country, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  factory Club.fromMap(Map<String, dynamic> data) => Club(
        id: data['id'] as int?,
        name: data['name'] as String?,
        country: data['country'] as String?,
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
        'country': country,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Club.fromJson(String data) {
    return Club.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());
}
