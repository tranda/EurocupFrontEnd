class DisciplineProgressionInfo {
  final int disciplineId;
  final int crewCount;
  final int? laneCount;
  final String? autoPickCode;
  final String? overrideCode;
  final String? effectiveCode;
  final List<String>? customStages;

  DisciplineProgressionInfo({
    required this.disciplineId,
    required this.crewCount,
    this.laneCount,
    this.autoPickCode,
    this.overrideCode,
    this.effectiveCode,
    this.customStages,
  });

  factory DisciplineProgressionInfo.fromMap(Map<String, dynamic> data) =>
      DisciplineProgressionInfo(
        disciplineId: (data['discipline_id'] ?? 0) as int,
        crewCount: (data['crew_count'] ?? 0) as int,
        laneCount: data['lane_count'] as int?,
        autoPickCode: data['auto_pick_code'] as String?,
        overrideCode: data['override_code'] as String?,
        effectiveCode: data['effective_code'] as String?,
        customStages: (data['custom_stages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
}
