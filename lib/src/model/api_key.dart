/// A server-side API key used by external integrations (e.g. a club app
/// pulling its races via `races.read`). The secret itself is only ever
/// returned once, at creation time — see [ApiKeyController::store] on the
/// backend. This model carries the non-sensitive metadata the list screen
/// shows; the plaintext key is handled separately at creation.
class ApiKey {
  final int? id;
  final String? name;
  final String? keyPrefix;
  final List<String> permissions;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? createdAt;
  final String? creatorName;

  ApiKey({
    this.id,
    this.name,
    this.keyPrefix,
    this.permissions = const [],
    this.lastUsedAt,
    this.expiresAt,
    this.isActive = true,
    this.createdAt,
    this.creatorName,
  });

  factory ApiKey.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

    List<String> parsePermissions(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    return ApiKey(
      id: map['id'] is int ? map['id'] : int.tryParse('${map['id']}'),
      name: map['name']?.toString(),
      keyPrefix: map['key_prefix']?.toString(),
      permissions: parsePermissions(map['permissions']),
      lastUsedAt: parseDate(map['last_used_at']),
      expiresAt: parseDate(map['expires_at']),
      isActive: map['is_active'] == true || map['is_active'] == 1,
      createdAt: parseDate(map['created_at']),
      creatorName: (map['creator'] is Map)
          ? (map['creator']['name'] ?? map['creator']['username'])?.toString()
          : null,
    );
  }
}

/// Result of creating an API key: the one-time plaintext secret plus the
/// stored metadata. The plaintext is never retrievable again.
class NewApiKey {
  final String plaintextKey;
  final ApiKey model;

  NewApiKey({required this.plaintextKey, required this.model});
}
