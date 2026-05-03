class GenerationResult {
  final int racesCreated;
  final int crewLanesAssigned;
  final Map<String, int> racesPerDiscipline;
  final List<String> warnings;

  GenerationResult({
    this.racesCreated = 0,
    this.crewLanesAssigned = 0,
    this.racesPerDiscipline = const {},
    this.warnings = const [],
  });

  factory GenerationResult.fromMap(Map<String, dynamic> data) => GenerationResult(
        racesCreated: (data['races_created'] ?? 0) as int,
        crewLanesAssigned: (data['crew_lanes_assigned'] ?? 0) as int,
        racesPerDiscipline: ((data['races_per_discipline'] ?? {}) as Map)
            .map((k, v) => MapEntry(k.toString(), v as int)),
        warnings: ((data['warnings'] ?? []) as List<dynamic>)
            .map((w) => w.toString())
            .toList(),
      );
}
