import 'race/team.dart';

/// One row in the medal-standings table for a given competition.
///
/// Immutable snapshot produced by [MedalTally.compute]. Holds enough team
/// metadata (via [team]) for the view to render the country flag alongside
/// the [teamName] label.
class MedalStanding {
  final String teamName;
  final Team team;
  final int gold;
  final int silver;
  final int bronze;

  const MedalStanding({
    required this.teamName,
    required this.team,
    required this.gold,
    required this.silver,
    required this.bronze,
  });

  int get total => gold + silver + bronze;
}
