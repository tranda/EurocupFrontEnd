import 'dart:convert';

class Club {
  final int? id;
  final String? name;
  final String? country;
  final bool? req_adel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Club({
    this.id,
    this.name,
    this.country,
    this.req_adel,
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
        req_adel: data['req_adel'] == 1 ? true : false,
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
        'req_adel': req_adel,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Club.fromJson(String data) {
    return Club.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  String toJson() => json.encode(toMap());
}
