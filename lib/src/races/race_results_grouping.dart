import '../model/race/race_result.dart';

/// Returns a date-only key (year/month/day, time zeroed) for grouping races
/// that occur on the same calendar day.
DateTime dayKey(DateTime t) => DateTime(t.year, t.month, t.day);

/// Groups races by calendar day. Races with `raceTime == null` are omitted.
/// Returned map keys iterate chronologically ascending and value lists
/// preserve input order (callers are expected to pre-sort by race number).
/// Dart's default `Map` is insertion-ordered, which is the contract here.
Map<DateTime, List<RaceResult>> groupRacesByDay(List<RaceResult> races) {
  final buckets = <DateTime, List<RaceResult>>{};
  final keys = <DateTime>[];

  for (final r in races) {
    final t = r.raceTime;
    if (t == null) continue;
    final key = dayKey(t);
    buckets.putIfAbsent(key, () {
      keys.add(key);
      return <RaceResult>[];
    }).add(r);
  }

  keys.sort();
  final out = <DateTime, List<RaceResult>>{};
  for (final k in keys) {
    out[k] = buckets[k]!;
  }
  return out;
}
