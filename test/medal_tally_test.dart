import 'package:flutter_test/flutter_test.dart';
import 'package:eurocup_frontend/src/model/medal_standing.dart';
import 'package:eurocup_frontend/src/model/medal_tally.dart';
import 'package:eurocup_frontend/src/model/race/crew.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';
import 'package:eurocup_frontend/src/model/race/discipline.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/model/race/team.dart';

// Test builders — keep the test bodies focused on the assertion.
RaceResult _medalRace({
  required int id,
  required String competition,
  required List<_CrewSpec> finishers,
}) {
  return RaceResult(
    id: id,
    stage: 'Grand Final',
    status: 'FINISHED',
    isFinalRound: true,
    discipline: Discipline(id: 100, competition: competition),
    crewResults: finishers.asMap().entries.map((e) {
      final idx = e.key;
      final spec = e.value;
      return CrewResult(
        crewId: spec.crewId,
        lane: idx + 1,
        finalStatus: spec.finalStatus,
        finalTimeMs: spec.finalTimeMs,
        crew: Crew(id: spec.crewId, team: Team(id: spec.crewId, name: spec.teamName)),
      );
    }).toList(),
  );
}

class _CrewSpec {
  final int crewId;
  final String teamName;
  final int? finalTimeMs;
  final String? finalStatus;
  _CrewSpec(this.crewId, this.teamName, {this.finalTimeMs, this.finalStatus = 'FINISHED'});
}

void main() {
  group('MedalStanding', () {
    test('exposes team + counts and computes total', () {
      final team = Team(id: 1, name: 'GYVSE');
      final s = MedalStanding(
        teamName: 'GYVSE',
        team: team,
        gold: 4,
        silver: 2,
        bronze: 1,
      );
      expect(s.teamName, 'GYVSE');
      expect(s.team, team);
      expect(s.gold, 4);
      expect(s.silver, 2);
      expect(s.bronze, 1);
      expect(s.total, 7);
    });
  });

  group('MedalTally.compute — happy path', () {
    test('assigns gold/silver/bronze to top 3 finishers of each medal race', () {
      final races = [
        _medalRace(id: 1, competition: 'Club', finishers: [
          _CrewSpec(1, 'Alpha', finalTimeMs: 50000),  // gold
          _CrewSpec(2, 'Beta',  finalTimeMs: 52000),  // silver
          _CrewSpec(3, 'Gamma', finalTimeMs: 54000),  // bronze
          _CrewSpec(4, 'Delta', finalTimeMs: 56000),  // 4th — no medal
        ]),
        _medalRace(id: 2, competition: 'Club', finishers: [
          _CrewSpec(2, 'Beta',  finalTimeMs: 48000),  // gold
          _CrewSpec(1, 'Alpha', finalTimeMs: 49000),  // silver
        ]),
      ];

      final standings = MedalTally.compute(races);
      expect(standings.keys, ['Club']);

      final club = standings['Club']!;
      final alpha = club.firstWhere((s) => s.teamName == 'Alpha');
      final beta  = club.firstWhere((s) => s.teamName == 'Beta');
      final gamma = club.firstWhere((s) => s.teamName == 'Gamma');
      final delta = club.where((s) => s.teamName == 'Delta');

      expect(alpha.gold, 1);   expect(alpha.silver, 1); expect(alpha.bronze, 0);
      expect(beta.gold,  1);   expect(beta.silver,  1); expect(beta.bronze,  0);
      expect(gamma.gold, 0);   expect(gamma.silver, 0); expect(gamma.bronze, 1);
      expect(delta, isEmpty, reason: '4th-place team should not appear');
    });
  });

  group('MedalTally.compute — sort order', () {
    test('sorts gold DESC → silver DESC → bronze DESC → name ASC', () {
      // Construct 4 races so that after tally:
      //   Alpha:  2G 0S 0B
      //   Beta:   2G 0S 0B  (tied with Alpha on all counts)
      //   Gamma:  0G 2S 2B
      //   Delta:  0G 2S 2B  (tied with Gamma on all counts)
      // Expected order: Alpha, Beta (gold breaks vs Gamma/Delta),
      //                 Delta, Gamma (alphabetical tie-break within pairs).
      final races = [
        _medalRace(id: 1, competition: 'Club', finishers: [
          _CrewSpec(1, 'Alpha', finalTimeMs: 50000),  // gold
          _CrewSpec(4, 'Delta', finalTimeMs: 51000),  // silver
          _CrewSpec(3, 'Gamma', finalTimeMs: 52000),  // bronze
        ]),
        _medalRace(id: 2, competition: 'Club', finishers: [
          _CrewSpec(2, 'Beta',  finalTimeMs: 50000),  // gold
          _CrewSpec(3, 'Gamma', finalTimeMs: 51000),  // silver
          _CrewSpec(4, 'Delta', finalTimeMs: 52000),  // bronze
        ]),
        _medalRace(id: 3, competition: 'Club', finishers: [
          _CrewSpec(1, 'Alpha', finalTimeMs: 50000),  // gold
          _CrewSpec(3, 'Gamma', finalTimeMs: 51000),  // silver
          _CrewSpec(4, 'Delta', finalTimeMs: 52000),  // bronze
        ]),
        _medalRace(id: 4, competition: 'Club', finishers: [
          _CrewSpec(2, 'Beta',  finalTimeMs: 50000),  // gold
          _CrewSpec(4, 'Delta', finalTimeMs: 51000),  // silver
          _CrewSpec(3, 'Gamma', finalTimeMs: 52000),  // bronze
        ]),
      ];

      final club = MedalTally.compute(races)['Club']!;
      expect(club.map((s) => s.teamName).toList(),
             ['Alpha', 'Beta', 'Delta', 'Gamma']);
      // Alpha before Beta and Delta before Gamma: both are alphabetical
      // tie-breaks (identical G/S/B counts within each pair).

      final alpha = club[0], beta = club[1], delta = club[2], gamma = club[3];
      expect(alpha.gold, 2); expect(alpha.silver, 0); expect(alpha.bronze, 0);
      expect(beta.gold,  2); expect(beta.silver,  0); expect(beta.bronze,  0);
      expect(delta.gold, 0); expect(delta.silver, 2); expect(delta.bronze, 2);
      expect(gamma.gold, 0); expect(gamma.silver, 2); expect(gamma.bronze, 2);
    });
  });

  group('MedalTally.compute — exclusions', () {
    test('skips races that are not FINISHED, not final, or missing competition; ignores DSQ/DNS/DNF crews', () {
      final races = [
        // CANCELLED medal race → does not contribute.
        RaceResult(
          id: 10,
          status: 'CANCELLED',
          isFinalRound: true,
          discipline: Discipline(id: 100, competition: 'Club'),
          crewResults: [
            CrewResult(
              crewId: 1, lane: 1,
              finalStatus: 'FINISHED', finalTimeMs: 50000,
              crew: Crew(id: 1, team: Team(id: 1, name: 'ShouldNotAppear')),
            ),
          ],
        ),
        // SCHEDULED (not yet finished) medal race → does not contribute.
        RaceResult(
          id: 11,
          status: 'SCHEDULED',
          isFinalRound: true,
          discipline: Discipline(id: 100, competition: 'Club'),
          crewResults: [],
        ),
        // Non-final race (e.g. Heat 1) → does not contribute.
        RaceResult(
          id: 12,
          status: 'FINISHED',
          isFinalRound: false,
          discipline: Discipline(id: 100, competition: 'Club'),
          crewResults: [
            CrewResult(
              crewId: 1, lane: 1,
              finalStatus: 'FINISHED', finalTimeMs: 50000,
              crew: Crew(id: 1, team: Team(id: 1, name: 'ShouldNotAppear')),
            ),
          ],
        ),
        // Race whose discipline has no competition → skipped.
        RaceResult(
          id: 13,
          status: 'FINISHED',
          isFinalRound: true,
          discipline: Discipline(id: 100, competition: null),
          crewResults: [
            CrewResult(
              crewId: 1, lane: 1,
              finalStatus: 'FINISHED', finalTimeMs: 50000,
              crew: Crew(id: 1, team: Team(id: 1, name: 'ShouldNotAppear')),
            ),
          ],
        ),
        // Real medal race with only 2 finishers; other lanes DSQ/DNS.
        _medalRace(id: 14, competition: 'Club', finishers: [
          _CrewSpec(1, 'RealAlpha', finalTimeMs: 50000),
          _CrewSpec(2, 'RealBeta',  finalTimeMs: 52000),
          _CrewSpec(3, 'DsqCrew',   finalStatus: 'DSQ', finalTimeMs: null),
          _CrewSpec(4, 'DnsCrew',   finalStatus: 'DNS', finalTimeMs: null),
        ]),
      ];

      final standings = MedalTally.compute(races);
      expect(standings.keys, ['Club']);
      final club = standings['Club']!;
      expect(club.map((s) => s.teamName).toList(), ['RealAlpha', 'RealBeta']);
      expect(club[0].gold, 1);   expect(club[0].silver, 0); expect(club[0].bronze, 0);
      expect(club[1].gold, 0);   expect(club[1].silver, 1); expect(club[1].bronze, 0);
      // No bronze awarded — only 2 finishers.
    });
  });

  group('MedalTally.compute — multi-competition', () {
    test('groups results per competition; same team across boat groups in one competition sums into one row', () {
      final races = [
        // Club / Small boat discipline (id 100) — GYVSE wins gold.
        _medalRace(id: 1, competition: 'Club', finishers: [
          _CrewSpec(1, 'GYVSE',    finalTimeMs: 50000),
          _CrewSpec(2, 'Beodrag',  finalTimeMs: 52000),
        ]),
        // Club / Standard boat discipline (id 101) — GYVSE also wins gold.
        // Discipline is different but competition is still 'Club', so both
        // gold medals go to the same GYVSE row in the Club tally.
        _medalRace(id: 2, competition: 'Club', finishers: [
          _CrewSpec(1, 'GYVSE',    finalTimeMs: 48000),
          _CrewSpec(3, 'Dragon',   finalTimeMs: 49000),
        ]),
        // Corporate discipline — GYVSE isn't here; a Corporate-only team wins.
        _medalRace(id: 3, competition: 'Corporate', finishers: [
          _CrewSpec(10, 'BankOfChina', finalTimeMs: 60000),
          _CrewSpec(11, 'SDHS',        finalTimeMs: 62000),
        ]),
      ];

      final standings = MedalTally.compute(races);
      expect(standings.keys.toSet(), {'Club', 'Corporate'});

      final club = standings['Club']!;
      final gyvse = club.firstWhere((s) => s.teamName == 'GYVSE');
      expect(gyvse.gold, 2, reason: 'Club/Small + Club/Standard gold medals sum');
      expect(gyvse.silver, 0);
      expect(gyvse.bronze, 0);

      final corp = standings['Corporate']!;
      expect(corp.map((s) => s.teamName).toList(), ['BankOfChina', 'SDHS']);
      expect(corp[0].gold, 1);
    });
  });

  group('MedalTally.compute — empty and degenerate inputs', () {
    test('returns an empty map when there are no medal races', () {
      // All races are non-final heats.
      final races = [
        RaceResult(
          id: 1,
          status: 'FINISHED',
          isFinalRound: false,
          stage: 'Heat 1',
          discipline: Discipline(id: 100, competition: 'Club'),
          crewResults: [
            CrewResult(
              crewId: 1, lane: 1,
              finalStatus: 'FINISHED', finalTimeMs: 50000,
              crew: Crew(id: 1, team: Team(id: 1, name: 'Alpha')),
            ),
          ],
        ),
      ];
      expect(MedalTally.compute(races), isEmpty);
    });

    test('returns an empty map when the input list is empty', () {
      expect(MedalTally.compute([]), isEmpty);
    });

    test('tolerates crews with null team / null name — silently skips them', () {
      final races = [
        RaceResult(
          id: 1, status: 'FINISHED', isFinalRound: true,
          discipline: Discipline(id: 100, competition: 'Club'),
          crewResults: [
            CrewResult(
              crewId: 1, lane: 1,
              finalStatus: 'FINISHED', finalTimeMs: 50000,
              crew: Crew(id: 1, team: null),  // no team → skipped
            ),
            CrewResult(
              crewId: 2, lane: 2,
              finalStatus: 'FINISHED', finalTimeMs: 52000,
              crew: Crew(id: 2, team: Team(id: 2, name: '   ')),  // whitespace-only name → skipped
            ),
            CrewResult(
              crewId: 3, lane: 3,
              finalStatus: 'FINISHED', finalTimeMs: 54000,
              crew: Crew(id: 3, team: Team(id: 3, name: 'RealTeam')),
            ),
          ],
        ),
      ];
      // Only RealTeam is countable. The medalist ranking is time-based: RealTeam
      // is the 3rd finisher, so it gets bronze (not gold — we don't compact).
      final club = MedalTally.compute(races)['Club']!;
      expect(club.length, 1);
      expect(club[0].teamName, 'RealTeam');
      expect(club[0].gold, 0);
      expect(club[0].silver, 0);
      expect(club[0].bronze, 1);
    });
  });
}
