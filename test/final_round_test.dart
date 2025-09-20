import 'package:flutter_test/flutter_test.dart';
import 'package:eurocup_frontend/src/model/race/crew_result.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';

void main() {
  group('Final Round Tests', () {
    test('CrewResult should parse final round data correctly', () {
      final data = {
        'id': 1,
        'crew_id': 1,
        'race_result_id': 1,
        'lane': 3,
        'position': 1,
        'time_ms': 125000, // 2:05.000
        'status': 'FINISHED',
        'final_time_ms': 250433, // 4:10.433 (accumulated)
        'final_status': 'FINISHED',
        'formatted_final_time': '04:10.433',
        'final_position': 1, // Position based on accumulated final time
        'is_final_round': true,
      };

      final crewResult = CrewResult.fromMap(data);

      expect(crewResult.id, equals(1));
      expect(crewResult.timeMs, equals(125000));
      expect(crewResult.finalTimeMs, equals(250433));
      expect(crewResult.finalStatus, equals('FINISHED'));
      expect(crewResult.formattedFinalTime, equals('04:10.433'));
      expect(crewResult.finalPosition, equals(1));
      expect(crewResult.isFinalRound, equals(true));
      expect(crewResult.hasFinalTime, equals(true));
    });

    test('CrewResult displayFinalTime should format correctly', () {
      // Test with formatted time
      final crewResult1 = CrewResult(
        finalStatus: 'FINISHED',
        formattedFinalTime: '04:16.433',
      );
      expect(crewResult1.displayFinalTime, equals('04:16.433'));

      // Test with DSQ status
      final crewResult2 = CrewResult(
        finalStatus: 'DSQ',
        formattedFinalTime: '04:16.433',
      );
      expect(crewResult2.displayFinalTime, equals('DSQ'));

      // Test with raw milliseconds
      final crewResult3 = CrewResult(
        finalStatus: 'FINISHED',
        finalTimeMs: 256433, // 4:16.433
      );
      expect(crewResult3.displayFinalTime, equals('04:16.433'));
    });

    test('RaceResult should parse final round flag correctly', () {
      final data = {
        'id': 1,
        'race_number': 15,
        'discipline_id': 1,
        'stage': 'Final',
        'status': 'FINISHED',
        'is_final_round': true,
      };

      final raceResult = RaceResult.fromMap(data);

      expect(raceResult.id, equals(1));
      expect(raceResult.raceNumber, equals(15));
      expect(raceResult.stage, equals('Final'));
      expect(raceResult.isFinalRound, equals(true));
    });

    test('Final round position calculation should use finalPosition', () {
      // Create test crew results with final positions
      final crewResult1 = CrewResult(
        id: 1,
        position: null, // Current round position (should be overwritten)
        finalPosition: 1, // Final accumulated position
        timeMs: 125000,
        finalTimeMs: 250433,
        status: 'FINISHED',
        finalStatus: 'FINISHED',
      );

      final crewResult2 = CrewResult(
        id: 2,
        position: null,
        finalPosition: 2,
        timeMs: 127000,
        finalTimeMs: 252100,
        status: 'FINISHED',
        finalStatus: 'FINISHED',
      );

      final crewResult3 = CrewResult(
        id: 3,
        position: null,
        finalPosition: 3,
        timeMs: 130000,
        finalTimeMs: 255200,
        status: 'FINISHED',
        finalStatus: 'FINISHED',
      );

      final crewResults = [crewResult1, crewResult2, crewResult3];

      // Simulate the position calculation logic for final rounds
      for (var crew in crewResults) {
        crew.position = crew.finalPosition;
      }

      // Verify positions are set correctly for badge display
      expect(crewResult1.position, equals(1));
      expect(crewResult2.position, equals(2));
      expect(crewResult3.position, equals(3));
    });

    test('Final round position calculation should fallback to finalTimeMs when finalPosition is null', () {
      // Create test crew results without finalPosition but with finalTimeMs
      final crewResult1 = CrewResult(
        id: 1,
        position: null,
        finalPosition: null, // No backend-provided position
        timeMs: 125000,
        finalTimeMs: 250433, // Fastest total time
        status: 'FINISHED',
        finalStatus: 'FINISHED',
      );

      final crewResult2 = CrewResult(
        id: 2,
        position: null,
        finalPosition: null,
        timeMs: 127000,
        finalTimeMs: 252100, // Second fastest
        status: 'FINISHED',
        finalStatus: 'FINISHED',
      );

      final crewResult3 = CrewResult(
        id: 3,
        position: null,
        finalPosition: null,
        timeMs: 130000,
        finalTimeMs: 255200, // Third fastest
        status: 'FINISHED',
        finalStatus: 'FINISHED',
      );

      final crewResults = [crewResult1, crewResult2, crewResult3];

      // Simulate the fallback position calculation logic for final rounds
      final hasValidFinalPositions = crewResults.any((crew) => crew.finalPosition != null);

      if (!hasValidFinalPositions) {
        // Fallback: calculate positions based on finalTimeMs
        final finishedCrews = crewResults
            .where((crew) => crew.finalStatus == 'FINISHED' && crew.finalTimeMs != null)
            .toList();

        // Sort by final time (fastest first)
        finishedCrews.sort((a, b) => a.finalTimeMs!.compareTo(b.finalTimeMs!));

        // Assign positions based on final times
        for (int i = 0; i < finishedCrews.length; i++) {
          finishedCrews[i].position = i + 1;
        }
      }

      // Verify positions are calculated correctly from finalTimeMs
      expect(crewResult1.position, equals(1)); // Fastest (250433ms)
      expect(crewResult2.position, equals(2)); // Second (252100ms)
      expect(crewResult3.position, equals(3)); // Third (255200ms)
    });
  });
}