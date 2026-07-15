import 'package:flutter_test/flutter_test.dart';
import 'package:eurocup_frontend/src/model/medal_standing.dart';
import 'package:eurocup_frontend/src/model/race/team.dart';

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
}
