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
}
