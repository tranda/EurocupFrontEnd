import 'race/race_result.dart';
import 'race/team.dart';
import 'medal_standing.dart';

/// Reduces a list of race results to per-competition medal standings.
///
/// Pure, side-effect-free. Consumers pass in whatever race list they already
/// have (typically the result of `getPublicRaceResults`) — no fetch, no state.
class MedalTally {
  /// Returns a map keyed by competition name (`Club`, `Corporate`, …), each
  /// value being the standings for that competition sorted by gold → silver
  /// → bronze DESC then team name ASC (case-insensitive).
  ///
  /// Medals are awarded per race where `status == 'FINISHED'` and
  /// `isFinalRound == true`. Within a medal race, crews are ranked by
  /// `finalTimeMs` ascending (matches backend semantics for both round-based
  /// and heat-based plans). Only the top 3 finishers get medals. Crews
  /// without a `FINISHED` final status or without a `finalTimeMs` are
  /// excluded (naturally: DSQ/DNS/DNF crews have null `finalTimeMs`).
  static Map<String, List<MedalStanding>> compute(List<RaceResult> races) {
    final byCompetition = <String, Map<String, _TeamCounter>>{};

    for (final race in races) {
      if (race.status != 'FINISHED') continue;
      if (race.isFinalRound != true) continue;

      final competition = race.discipline?.competition;
      if (competition == null || competition.isEmpty) continue;

      final finishers = (race.crewResults ?? [])
          .where((cr) => cr.finalStatus == 'FINISHED' && cr.finalTimeMs != null)
          .toList()
        ..sort((a, b) => a.finalTimeMs!.compareTo(b.finalTimeMs!));

      final medalists = finishers.take(3).toList();
      for (int i = 0; i < medalists.length; i++) {
        final cr = medalists[i];
        final rawName = cr.crew?.team?.name?.trim();
        final team = cr.crew?.team;
        if (rawName == null || rawName.isEmpty || team == null) continue;

        final teams = byCompetition.putIfAbsent(competition, () => <String, _TeamCounter>{});
        final counter = teams.putIfAbsent(rawName, () => _TeamCounter(rawName, team));
        if (i == 0) {
          counter.gold++;
        } else if (i == 1) {
          counter.silver++;
        } else {
          counter.bronze++;
        }
      }
    }

    final result = <String, List<MedalStanding>>{};
    byCompetition.forEach((competition, teams) {
      final standings = teams.values
          .map((c) => MedalStanding(
                teamName: c.teamName,
                team: c.team,
                gold: c.gold,
                silver: c.silver,
                bronze: c.bronze,
              ))
          .toList()
        ..sort(_sortStandings);
      result[competition] = standings;
    });
    return result;
  }

  static int _sortStandings(MedalStanding a, MedalStanding b) {
    if (a.gold != b.gold) return b.gold.compareTo(a.gold);
    if (a.silver != b.silver) return b.silver.compareTo(a.silver);
    if (a.bronze != b.bronze) return b.bronze.compareTo(a.bronze);
    return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
  }
}

class _TeamCounter {
  final String teamName;
  final Team team;
  int gold = 0, silver = 0, bronze = 0;
  _TeamCounter(this.teamName, this.team);
}
