// This is an example unit test.
//
// A unit test tests a single function, method, or class. To learn more about
// writing unit tests, visit
// https://flutter.dev/docs/cookbook/testing/unit/introduction

import 'package:flutter_test/flutter_test.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';

void main() {
  group('Plus Operator', () {
    test('should add two numbers together', () {
      expect(1 + 1, 2);
    });
  });

  group('Final Round Display Tests', () {
    test('RaceResult should handle final round flag', () {
      final testData = {
        'id': 1,
        'race_number': 3,
        'stage': 'Final',
        'status': 'FINISHED',
        'is_final_round': true,
      };

      final raceResult = RaceResult.fromMap(testData);

      expect(raceResult.id, 1);
      expect(raceResult.raceNumber, 3);
      expect(raceResult.isFinalRound, true);
    });

    test('CrewResult should handle final time fields', () {
      final testData = {
        'id': 1,
        'position': 1,
        'time_ms': 142120,
        'status': 'FINISHED',
        'final_time_ms': 465890,
        'final_status': 'FINISHED',
        'formatted_final_time': '7:45.890',
      };

      final crewResult = CrewResult.fromMap(testData);

      expect(crewResult.id, 1);
      expect(crewResult.position, 1);
      expect(crewResult.timeMs, 142120);
      expect(crewResult.finalTimeMs, 465890);
      expect(crewResult.finalStatus, 'FINISHED');
      expect(crewResult.formattedFinalTime, '7:45.890');
      expect(crewResult.displayFinalTime, '7:45.890');
      expect(crewResult.hasFinalTime, true);
    });

    test('CrewResult should handle DSQ final status', () {
      final testData = {
        'id': 2,
        'position': null,
        'time_ms': 144230,
        'status': 'FINISHED',
        'final_time_ms': null,
        'final_status': 'DSQ',
        'formatted_final_time': null,
      };

      final crewResult = CrewResult.fromMap(testData);

      expect(crewResult.finalStatus, 'DSQ');
      expect(crewResult.displayFinalTime, 'DSQ');
      expect(crewResult.hasFinalTime, true);
    });

    test('CrewResult should handle missing final time data', () {
      final testData = {
        'id': 3,
        'position': 2,
        'time_ms': 146340,
        'status': 'FINISHED',
      };

      final crewResult = CrewResult.fromMap(testData);

      expect(crewResult.finalTimeMs, null);
      expect(crewResult.finalStatus, null);
      expect(crewResult.formattedFinalTime, null);
      expect(crewResult.displayFinalTime, '');
      expect(crewResult.hasFinalTime, false);
    });
  });
}
