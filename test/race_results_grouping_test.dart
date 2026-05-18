import 'package:flutter_test/flutter_test.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/races/race_results_grouping.dart';

RaceResult _r({int? raceNumber, DateTime? raceTime}) => RaceResult(
      id: raceNumber,
      raceNumber: raceNumber,
      raceTime: raceTime,
    );

void main() {
  group('dayKey', () {
    test('strips time component from a DateTime', () {
      final t = DateTime(2026, 6, 13, 14, 32, 17);
      expect(dayKey(t), DateTime(2026, 6, 13));
    });

    test('two DateTimes on the same day produce equal keys', () {
      final a = DateTime(2026, 6, 13, 8, 0);
      final b = DateTime(2026, 6, 13, 22, 59);
      expect(dayKey(a), equals(dayKey(b)));
    });

    test('DateTimes on different days produce different keys', () {
      expect(
        dayKey(DateTime(2026, 6, 13, 23, 59)),
        isNot(equals(dayKey(DateTime(2026, 6, 14, 0, 0)))),
      );
    });
  });

  group('groupRacesByDay', () {
    test('returns empty map for empty input', () {
      expect(groupRacesByDay(const []), isEmpty);
    });

    test('omits races with null raceTime', () {
      final races = [
        _r(raceNumber: 1, raceTime: null),
        _r(raceNumber: 2, raceTime: DateTime(2026, 6, 13, 10, 0)),
      ];
      final grouped = groupRacesByDay(races);
      expect(grouped.length, 1);
      expect(grouped[DateTime(2026, 6, 13)]!.length, 1);
      expect(grouped[DateTime(2026, 6, 13)]!.single.raceNumber, 2);
    });

    test('groups by calendar day', () {
      final races = [
        _r(raceNumber: 1, raceTime: DateTime(2026, 6, 13, 9, 0)),
        _r(raceNumber: 2, raceTime: DateTime(2026, 6, 13, 16, 30)),
        _r(raceNumber: 3, raceTime: DateTime(2026, 6, 14, 9, 0)),
      ];
      final grouped = groupRacesByDay(races);
      expect(grouped.length, 2);
      expect(grouped[DateTime(2026, 6, 13)]!.map((r) => r.raceNumber), [1, 2]);
      expect(grouped[DateTime(2026, 6, 14)]!.map((r) => r.raceNumber), [3]);
    });

    test('iteration order is chronological ascending', () {
      final races = [
        _r(raceNumber: 3, raceTime: DateTime(2026, 6, 14, 9, 0)),
        _r(raceNumber: 1, raceTime: DateTime(2026, 6, 13, 9, 0)),
        _r(raceNumber: 2, raceTime: DateTime(2026, 6, 13, 16, 30)),
      ];
      final grouped = groupRacesByDay(races);
      expect(
        grouped.keys.toList(),
        [DateTime(2026, 6, 13), DateTime(2026, 6, 14)],
      );
    });

    test('preserves input order within each day', () {
      // Caller is expected to pre-sort by raceNumber; helper must not reorder.
      final races = [
        _r(raceNumber: 5, raceTime: DateTime(2026, 6, 13, 9, 0)),
        _r(raceNumber: 1, raceTime: DateTime(2026, 6, 13, 16, 30)),
      ];
      final grouped = groupRacesByDay(races);
      expect(
        grouped[DateTime(2026, 6, 13)]!.map((r) => r.raceNumber),
        [5, 1],
      );
    });
  });
}
