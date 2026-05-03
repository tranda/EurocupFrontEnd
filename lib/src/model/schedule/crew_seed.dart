class CrewSeed {
  final int crewId;
  final int teamId;
  final String? teamName;
  int? seedNumber;

  CrewSeed({
    required this.crewId,
    required this.teamId,
    this.teamName,
    this.seedNumber,
  });

  factory CrewSeed.fromMap(Map<String, dynamic> data) => CrewSeed(
        crewId: (data['crew_id'] ?? 0) as int,
        teamId: (data['team_id'] ?? 0) as int,
        teamName: data['team_name'] as String?,
        seedNumber: data['seed_number'] as int?,
      );

  Map<String, dynamic> toUpdatePayload() => {
        'crew_id': crewId,
        'seed_number': seedNumber,
      };
}
