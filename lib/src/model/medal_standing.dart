/// One row in the medal-standings table for a given competition.
///
/// Populated by the backend endpoint `GET /api/public/events/{id}/medals`.
/// Grouping is by club (fallback to team name if a crew has no club).
class MedalStanding {
  final int? clubId;
  final String clubName;
  final String? country;
  final int gold;
  final int silver;
  final int bronze;
  final int total;

  const MedalStanding({
    required this.clubId,
    required this.clubName,
    required this.country,
    required this.gold,
    required this.silver,
    required this.bronze,
    required this.total,
  });

  factory MedalStanding.fromMap(Map<String, dynamic> data) => MedalStanding(
        clubId: data['club_id'] as int?,
        clubName: data['club_name'] as String? ?? '',
        country: data['country'] as String?,
        gold: (data['gold'] as num?)?.toInt() ?? 0,
        silver: (data['silver'] as num?)?.toInt() ?? 0,
        bronze: (data['bronze'] as num?)?.toInt() ?? 0,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
}
