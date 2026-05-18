# Race Results: Group by Day + Date Filter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Group races on the Race Results page by day with collapsible day section headers, add a date multi-select to the Filters dialog, and mirror the grouping in the PDF export.

**Architecture:** All changes are confined to `lib/src/races/race_results_list_view.dart`. We add two pieces of state (`_expandedDays`, `_filterDates`), a pure date-key helper, a pure grouping helper, and wire the existing list/PDF/filter code through them. No backend, model, API, or routing changes.

**Tech Stack:** Flutter (Dart), `intl: ^0.20.2` (already in `pubspec.yaml`), `pdf` + `printing` for PDF export, `flutter_test` for unit tests.

**Companion spec:** `docs/superpowers/specs/2026-05-19-race-results-day-grouping-design.md`

---

## Working directory + repo

All changes happen in the **frontend repo**: `EurocupFrontEnd/`. That directory is its own git repository (per project `CLAUDE.md`). Every `git` command in this plan assumes you are inside `EurocupFrontEnd/`. Use `cd EurocupFrontEnd` once at the start of each task if needed.

## File map

| Path | Action | Why |
| --- | --- | --- |
| `lib/src/races/race_results_list_view.dart` | Modify | Add helpers, state, grouping render, date filter UI, PDF day headers, Expand/Collapse wiring. |
| `test/race_results_grouping_test.dart` | Create | Unit tests for the two pure helpers (`dayKey`, `groupRacesByDay`). |
| `lib/config/app_version.dart` | Modify | Bump patch version on release (final task only). |

Per project `CLAUDE.md`, the version bump only happens when the user says "deploy". Do **not** bump on regular commits.

---

## Background the engineer needs

- `RaceResult` (in `lib/src/model/race/race_result.dart`) has a `DateTime? raceTime` field. We group by `DateTime(t.year, t.month, t.day)`.
- The screen widget is `_RaceResultsListViewState` inside `lib/src/races/race_results_list_view.dart` (~2238 lines).
- Existing list-based filter state (`_filterAgeGroups`, etc.) uses the OR-within / AND-between pattern. The date filter follows the same shape.
- The Filters dialog (`_showFilters`) keeps `temp*` local copies that are committed back to instance state when **Apply** is pressed. Pattern to mirror exactly.
- `_expandedRaces` is a `Set<int?>` where **membership = expanded**. Mirror this convention for `_expandedDays: Set<DateTime>`.
- The list is currently rendered by a `ListView.builder` whose `index == 0` is a custom header (event title + buttons) and `index >= 1` indexes into a flat `races` list sorted by `raceNumber`. We will replace the body indexing with a flattened "render item" list of typed entries: `_HeaderItem`, `_DayHeaderItem(date, count)`, `_RaceItem(race)`, `_EmptyItem`.
- The PDF builder is `_buildPDFContent(races)` calling `_buildPDFRaceSection(race)` in a loop. We will insert `_buildPDFDayHeader(date, count)` widgets between day groups.

---

## TDD strategy

The two pure helpers (`dayKey` and `groupRacesByDay`) are testable in isolation. We write unit tests for them first. The UI integration (collapsible behaviour, dialog rendering, PDF visual output) is verified manually in a browser — Flutter widget tests for this large stateful widget would be high-cost / low-value here, and the project's existing test base does not test this view.

To make the helpers testable, define them as **top-level functions** in `race_results_list_view.dart` (not private methods of the state class). Underscore-prefix them (`_dayKey`, `_groupRacesByDay`) so they're library-private but still importable from the test file via the `package:` URI? No — underscore-prefixed identifiers are library-private in Dart and **not** importable from another file. So:

- Define them as **public top-level** functions named `dayKey` and `groupRacesByDay` in `race_results_list_view.dart`.
- They are part of this file's public API and tested directly.

This is the smallest change that keeps them unit-testable.

---

## Task 1: Pure helpers + unit tests

**Files:**
- Modify: `lib/src/races/race_results_list_view.dart` (add two top-level functions near the top of the file, just below the imports)
- Create: `test/race_results_grouping_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/race_results_grouping_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eurocup_frontend/src/model/race/race_result.dart';
import 'package:eurocup_frontend/src/races/race_results_list_view.dart';

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
```

- [ ] **Step 2: Run the tests, verify they fail**

```bash
cd EurocupFrontEnd
flutter test test/race_results_grouping_test.dart
```

Expected: compilation failure / undefined name `dayKey` and `groupRacesByDay`.

- [ ] **Step 3: Add the helpers**

In `lib/src/races/race_results_list_view.dart`, immediately after the `import` block (before `class RaceResultsListView`), add:

```dart
/// Returns a date-only key (year/month/day, time zeroed) for grouping races
/// that occur on the same calendar day.
DateTime dayKey(DateTime t) => DateTime(t.year, t.month, t.day);

/// Groups races by calendar day. Races with `raceTime == null` are omitted.
/// Returns a `LinkedHashMap` whose keys are sorted chronologically ascending
/// and whose value lists preserve the input order (callers are expected to
/// pre-sort by race number).
LinkedHashMap<DateTime, List<RaceResult>> groupRacesByDay(
  List<RaceResult> races,
) {
  final out = LinkedHashMap<DateTime, List<RaceResult>>();
  final sortedKeys = <DateTime>[];

  // First pass: bucket by day, preserving input order within each bucket.
  final buckets = <DateTime, List<RaceResult>>{};
  for (final r in races) {
    final t = r.raceTime;
    if (t == null) continue;
    final key = dayKey(t);
    buckets.putIfAbsent(key, () {
      sortedKeys.add(key);
      return <RaceResult>[];
    }).add(r);
  }

  // Sort keys chronologically and emit into the LinkedHashMap so iteration
  // order is stable and ascending by date.
  sortedKeys.sort();
  for (final k in sortedKeys) {
    out[k] = buckets[k]!;
  }
  return out;
}
```

Then add the `dart:collection` import at the top of the file (with the other `package:`/Dart imports):

```dart
import 'dart:collection';
```

- [ ] **Step 4: Run the tests, verify they pass**

```bash
flutter test test/race_results_grouping_test.dart
```

Expected: all 8 tests pass.

- [ ] **Step 5: Run the full test suite to make sure nothing else broke**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/src/races/race_results_list_view.dart test/race_results_grouping_test.dart
git commit -m "Race results: add pure dayKey + groupRacesByDay helpers (TDD)"
```

---

## Task 2: State + Expand/Collapse wiring

**Files:**
- Modify: `lib/src/races/race_results_list_view.dart`

No new tests in this task — the change is pure state plumbing; visible behaviour ships in Task 3.

- [ ] **Step 1: Add state fields**

Inside `_RaceResultsListViewState`, just below the existing `_filterCountry = ''` field and the comment block at lines 36–43, add:

```dart
  // Day-section fold state. Membership = expanded (mirrors _expandedRaces).
  final Set<DateTime> _expandedDays = <DateTime>{};

  // Date filter — list of day keys (DateTime with time zeroed). OR-within,
  // AND-between with the other filters, matching the existing pattern.
  final List<DateTime> _filterDates = [];
```

- [ ] **Step 2: Pre-populate `_expandedDays` after results load**

In `_loadRaceResults`, inside the `setState` block where `_raceResults = results` is assigned (around line 196), add — immediately after the line `_raceResults = results;` — these lines:

```dart
        // Default every day section to expanded so the page looks like the
        // current flat list on first load and after refreshes.
        for (final r in results) {
          final t = r.raceTime;
          if (t != null) _expandedDays.add(dayKey(t));
        }
```

This is additive: a refresh that introduces new days expands them; existing day keys remain whatever the user set.

- [ ] **Step 3: Update Expand All to also expand all days**

Replace the existing `_expandAll` body (lines 222–227) with:

```dart
  void _expandAll() {
    setState(() {
      final races = _filteredRaceResults ?? _raceResults ?? [];
      _expandedRaces.addAll(races.map((race) => race.id));
      for (final r in races) {
        final t = r.raceTime;
        if (t != null) _expandedDays.add(dayKey(t));
      }
    });
  }
```

- [ ] **Step 4: Update Collapse All to also collapse all days**

Replace the existing `_collapseAll` body (lines 229–233) with:

```dart
  void _collapseAll() {
    setState(() {
      _expandedRaces.clear();
      _expandedDays.clear();
    });
  }
```

- [ ] **Step 5: Wire the date filter into `_applyFilters`**

In `_applyFilters` (starts line 702), inside the `where((race) {...})` predicate, just **before** the existing `// Age group filter` block (line 711), add:

```dart
      // Date filter (OR logic - match any selected day)
      if (_filterDates.isNotEmpty) {
        final t = race.raceTime;
        if (t == null) return false;
        final key = dayKey(t);
        if (!_filterDates.any((d) => dayKey(d) == key)) return false;
      }
```

Also update the `print` at line 705 and the early-return guard at line 709. Line 709 currently is `if (discipline == null) return true;` — leave it as-is (the date check is above it, so a null-discipline race still respects the date filter).

Update the `_filteredRaceResults` reapply guard inside `_loadRaceResults` (around lines 198–204). The existing condition lists every filter list — add `_filterDates.isNotEmpty ||` to it:

Find this block:

```dart
        if (_filterAgeGroups.isNotEmpty || _filterGenderGroups.isNotEmpty ||
            _filterBoatGroups.isNotEmpty || _filterDistances.isNotEmpty ||
            _filterStages.isNotEmpty || _filterCompetitions.isNotEmpty ||
            _filterTeamName.isNotEmpty || _filterCountry.isNotEmpty) {
```

Replace with:

```dart
        if (_filterAgeGroups.isNotEmpty || _filterGenderGroups.isNotEmpty ||
            _filterBoatGroups.isNotEmpty || _filterDistances.isNotEmpty ||
            _filterStages.isNotEmpty || _filterCompetitions.isNotEmpty ||
            _filterDates.isNotEmpty ||
            _filterTeamName.isNotEmpty || _filterCountry.isNotEmpty) {
```

- [ ] **Step 6: Verify the project still compiles**

```bash
flutter analyze lib/src/races/race_results_list_view.dart
```

Expected: no new errors. (Unused-field warnings on `_expandedDays` / `_filterDates` are acceptable for now — Task 3 consumes them.)

- [ ] **Step 7: Run the test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/src/races/race_results_list_view.dart
git commit -m "Race results: state + filter/expand wiring for day grouping"
```

---

## Task 3: Render collapsible day sections in the list

**Files:**
- Modify: `lib/src/races/race_results_list_view.dart`

This task replaces the flat `ListView.builder` indexing with a typed render-item list and inserts day headers.

- [ ] **Step 1: Add render-item types**

At the bottom of `lib/src/races/race_results_list_view.dart` (after the closing brace of `_RaceResultsListViewState`), add:

```dart
sealed class _RenderItem {
  const _RenderItem();
}

class _HeaderItem extends _RenderItem {
  const _HeaderItem();
}

class _DayHeaderItem extends _RenderItem {
  final DateTime day;
  final int raceCount;
  const _DayHeaderItem(this.day, this.raceCount);
}

class _RaceItem extends _RenderItem {
  final RaceResult race;
  const _RaceItem(this.race);
}

class _EmptyItem extends _RenderItem {
  const _EmptyItem();
}
```

- [ ] **Step 2: Add a build helper that flattens the list**

Inside `_RaceResultsListViewState`, just above the `Widget build(BuildContext context)` method (line 1276), add:

```dart
  /// Builds the flat render-item list consumed by ListView.builder.
  /// Always emits a header. Day sections appear in chronological order.
  /// A day's race items are only emitted when the day is expanded.
  List<_RenderItem> _buildRenderItems() {
    final items = <_RenderItem>[const _HeaderItem()];

    var races = List<RaceResult>.from(_filteredRaceResults ?? _raceResults ?? []);
    races.sort((a, b) => (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0));

    final grouped = groupRacesByDay(races);

    if (grouped.isEmpty) {
      items.add(const _EmptyItem());
      return items;
    }

    grouped.forEach((day, dayRaces) {
      items.add(_DayHeaderItem(day, dayRaces.length));
      if (_expandedDays.contains(day)) {
        for (final r in dayRaces) {
          items.add(_RaceItem(r));
        }
      }
    });

    return items;
  }
```

- [ ] **Step 3: Add the day-header widget builder**

Immediately below `_buildRenderItems`, add:

```dart
  Widget _buildDayHeader(_DayHeaderItem item) {
    final color = competitionColor[(int.tryParse(_eventId ?? '1') ?? 1) - 1];
    final isExpanded = _expandedDays.contains(item.day);
    final dateText = DateFormat('EEEE, d MMM yyyy').format(item.day);
    return Material(
      color: color,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedDays.remove(item.day);
            } else {
              _expandedDays.add(item.day);
            }
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
              bottom: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text(
                '${item.raceCount} race${item.raceCount == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

Also add (or confirm) the `intl` import at the top of the file:

```dart
import 'package:intl/intl.dart';
```

- [ ] **Step 4: Rewire `ListView.builder` to consume render items**

In `_buildBody` (line 1290), find the block starting at line 1318:

```dart
    final races = _filteredRaceResults ?? _raceResults ?? [];
    print('Building UI - using ${_filteredRaceResults != null ? "FILTERED" : "UNFILTERED"} results: ${races.length} races');
    races.sort((a, b) => (a.raceNumber ?? 0).compareTo(b.raceNumber ?? 0));

    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: ListView.builder(
        itemCount: races.isEmpty ? 2 : races.length + 1, // +1 for header, +1 for empty message if no races
        itemBuilder: (context, index) {
```

Replace with:

```dart
    final items = _buildRenderItems();
    print('Building UI - using ${_filteredRaceResults != null ? "FILTERED" : "UNFILTERED"} results: ${items.whereType<_RaceItem>().length} race rows in ${items.whereType<_DayHeaderItem>().length} day sections');

    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is _HeaderItem) {
            return _buildScreenHeader();
          }
          if (item is _EmptyItem) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  _filteredRaceResults != null
                      ? 'No race results match your filters'
                      : 'No race results available',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ),
            );
          }
          if (item is _DayHeaderItem) {
            return _buildDayHeader(item);
          }
          if (item is _RaceItem) {
            return _buildRaceRow(item.race);
          }
          return const SizedBox.shrink();
        },
```

You will see the original `itemBuilder` was inline and very long. The replacement above delegates to two new helper methods — `_buildScreenHeader()` and `_buildRaceRow(RaceResult)` — that we extract in the next two steps. Do not collapse them in this step.

- [ ] **Step 5: Extract `_buildScreenHeader`**

Take the existing `if (index == 0) { return Container(...); }` block (lines 1328–1411 in the pre-edit file — the entire branch that builds the white header `Container` with the event title, Expand/Collapse/Filter buttons, competition chips, Export PDF button, and the `_buildActiveFiltersChips()` call) and **move** its body into a new method on `_RaceResultsListViewState`:

```dart
  Widget _buildScreenHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ...exact same children as the original index==0 block...
        ],
      ),
    );
  }
```

Copy the children verbatim from the original — do not change the visuals.

- [ ] **Step 6: Extract `_buildRaceRow`**

Take the entire body of the original `itemBuilder` from line 1432 onward (starting with `final raceResult = races[index - 1];` and including the `try { ... } catch (e, st) { ... }` block that returns the `Column` of race tile + expanded crew results + closes the catch) and move it into:

```dart
  Widget _buildRaceRow(RaceResult raceResult) {
    try {
      // ...exact same body as the original, but using `raceResult`
      // (already named that way in the original) and returning the Column...
    } catch (e, st) {
      // ...same catch as before...
    }
  }
```

The crew-result sorting, position calculation, expanded check, navigation, and detail rendering all stay identical. The only difference is that `raceResult` now arrives as a parameter instead of being indexed from `races[index - 1]`.

- [ ] **Step 7: Delete the now-dead inline branches**

After extracting `_buildScreenHeader` and `_buildRaceRow`, the original `itemBuilder` body (the `if (index == 0)` block, the empty-list branch at `if (races.isEmpty && index == 1)`, and the long race-row block) is fully replaced by the new dispatch from Step 4. Delete those original branches and their trailing closing braces so the file compiles.

- [ ] **Step 8: Verify it builds**

```bash
flutter analyze lib/src/races/race_results_list_view.dart
flutter test
```

Expected: no new analyzer errors, all tests pass.

- [ ] **Step 9: Manual UI check — Race Results page**

Start the dev server and open the Race Results page for an event that spans multiple days (the user's `Nihao Festival, Belgrade 2026`).

```bash
flutter run -d chrome
```

Verify in the browser:

- [ ] Day section headers appear, in chronological order, with weekday + date.
- [ ] Each day header shows the race count for that day.
- [ ] Tapping a day header folds/unfolds its races (chevron toggles between right and down).
- [ ] On first load, all day sections are expanded.
- [ ] Tapping a race row still expands the crew-results panel as before.
- [ ] **Expand All** opens every day section AND every race row.
- [ ] **Collapse All** folds every day section AND every race row.
- [ ] Refreshing the page (refresh button in app bar, or pull-to-refresh) preserves the day grouping.
- [ ] An event with only one day still shows one day header (does not regress single-day events).
- [ ] If `_raceResults` is empty, the "No race results available" message renders correctly.

If anything misbehaves, fix in this task before committing — do not advance to Task 4 with a broken UI.

- [ ] **Step 10: Commit**

```bash
git add lib/src/races/race_results_list_view.dart
git commit -m "Race results: render collapsible day sections in the list"
```

---

## Task 4: Date filter inside the Filters dialog + active chips

**Files:**
- Modify: `lib/src/races/race_results_list_view.dart`

- [ ] **Step 1: Add a `tempDates` local + populate available dates in `_showFilters`**

In `_showFilters` (line 419), just above the `// Populate available stages` block (line 420), add:

```dart
    // Populate available race dates from the loaded race results.
    final dateSet = <DateTime>{};
    if (_raceResults != null) {
      for (final race in _raceResults!) {
        final t = race.raceTime;
        if (t != null) dateSet.add(dayKey(t));
      }
    }
    final availableDates = dateSet.toList()..sort();
```

Then, inside the local-copies block (lines 432–438), add `tempDates` alongside the others:

```dart
    List<DateTime> tempDates = List<DateTime>.from(_filterDates);
```

- [ ] **Step 2: Insert the Date filter section in the dialog**

Inside the dialog's `Column` children (line 455 onward), **before** the existing `// Age Group filter` block (around line 457), insert:

```dart
                    // Date filter (multiselect with chips) — placed first
                    // because it is the most coarse-grained.
                    if (availableDates.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date',
                              style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: availableDates.map((d) {
                              final isSelected =
                                  tempDates.any((td) => dayKey(td) == d);
                              return FilterChip(
                                label: Text(DateFormat('EEE, d MMM').format(d)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      tempDates.add(d);
                                    } else {
                                      tempDates.removeWhere(
                                          (td) => dayKey(td) == d);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
```

- [ ] **Step 3: Wire the date filter into Clear All / Apply**

In the **Clear All** `TextButton.onPressed` (lines 639–652), add `tempDates.clear();` alongside the other `tempXxx.clear()` calls.

In the **Apply** `ElevatedButton.onPressed` block (lines 658–693), inside the `setState`:

- Add to the temp-to-actual copy block:

```dart
                      _filterDates.clear();
                      _filterDates.addAll(tempDates);
```

- Add `_filterDates.isNotEmpty ||` to the `hasActiveFilters` boolean.

So the final `hasActiveFilters` line reads:

```dart
                      final hasActiveFilters = _filterAgeGroups.isNotEmpty || _filterGenderGroups.isNotEmpty ||
                          _filterBoatGroups.isNotEmpty || _filterDistances.isNotEmpty ||
                          _filterStages.isNotEmpty || _filterCompetitions.isNotEmpty ||
                          _filterDates.isNotEmpty ||
                          _filterTeamName.isNotEmpty || _filterCountry.isNotEmpty;
```

- [ ] **Step 4: Add date chips to `_buildActiveFiltersChips`**

In `_buildActiveFiltersChips` (line 305), update the `hasFilters` guard at lines 306–309:

```dart
    final hasFilters = _filterAgeGroups.isNotEmpty || _filterGenderGroups.isNotEmpty ||
        _filterBoatGroups.isNotEmpty || _filterDistances.isNotEmpty ||
        _filterStages.isNotEmpty || _filterDates.isNotEmpty ||
        _filterTeamName.isNotEmpty || _filterCountry.isNotEmpty;
```

Then, inside the `Wrap`'s `children` list (around the existing Age/Gender/Boat chips), add date chips at the top — just **before** the `// Age group chips` line (322):

```dart
          // Date chips
          ..._filterDates.map((d) => Chip(
                label: Text('Date: ${DateFormat('EEE, d MMM').format(d)}',
                    style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _filterDates.removeWhere(
                        (td) => dayKey(td) == dayKey(d));
                    _applyFilters();
                  });
                },
                backgroundColor: Colors.indigo.shade50,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )),
```

- [ ] **Step 5: Analyze + test**

```bash
flutter analyze lib/src/races/race_results_list_view.dart
flutter test
```

Expected: no new analyzer errors, all tests pass.

- [ ] **Step 6: Manual UI check — Filters dialog**

```bash
flutter run -d chrome
```

Verify on the same multi-day event:

- [ ] Opening **Filters** shows a **Date** section at the top of the dialog with one chip per available day, formatted like `Sat, 13 Jun`.
- [ ] Selecting one or more date chips and pressing **Apply** filters the list to only those days.
- [ ] After applying, active filter chips appear at the top of the page (e.g., `Date: Sat 13 Jun`) with a working delete icon.
- [ ] Clicking the delete icon on a date chip removes that date from the filter and the list re-renders.
- [ ] **Clear All** in the dialog clears the Date selection alongside the others.
- [ ] Combining Date with another filter (e.g., Age Group) produces the AND-between behaviour (only races matching both).
- [ ] On a single-day event, the Date section still appears with one chip.

- [ ] **Step 7: Commit**

```bash
git add lib/src/races/race_results_list_view.dart
git commit -m "Race results: date multi-select in Filters dialog + active chips"
```

---

## Task 5: PDF export — group by day

**Files:**
- Modify: `lib/src/races/race_results_list_view.dart`

- [ ] **Step 1: Add the PDF day-header builder**

Below the existing `_buildPDFRaceSection` method, add:

```dart
  pw.Widget _buildPDFDayHeader(DateTime day, int raceCount) {
    final dateText = DateFormat('EEEE, d MMM yyyy').format(day);
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey800,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            dateText,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
            ),
          ),
          pw.Text(
            '$raceCount race${raceCount == 1 ? '' : 's'}',
            style: pw.TextStyle(
              color: PdfColors.grey300,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 2: Update `_exportToPDF` to operate on the filtered list**

In `_exportToPDF` (line 798), replace this line:

```dart
      final races = List<RaceResult>.from(_raceResults!);
```

with:

```dart
      final races = List<RaceResult>.from(_filteredRaceResults ?? _raceResults!);
```

This makes the PDF respect the active filters (including the new date filter). The `_raceResults` empty guard at the top of `_exportToPDF` still protects against the truly-empty case.

- [ ] **Step 3: Update `_buildPDFContent` to insert day headers**

Replace the entire `_buildPDFContent` method (line 886) with:

```dart
  List<pw.Widget> _buildPDFContent(List<RaceResult> races) {
    final widgets = <pw.Widget>[];

    // Title
    widgets.add(
      pw.Column(
        children: [
          pw.Text(
            _getEventFullName(),
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
        ],
      ),
    );

    // Group by day; races with null raceTime are omitted from the PDF too.
    final grouped = groupRacesByDay(races);

    grouped.forEach((day, dayRaces) {
      widgets.add(_buildPDFDayHeader(day, dayRaces.length));
      for (final race in dayRaces) {
        widgets.add(_buildPDFRaceSection(race));
        widgets.add(pw.SizedBox(height: 20));
      }
    });

    return widgets;
  }
```

- [ ] **Step 4: Analyze + test**

```bash
flutter analyze lib/src/races/race_results_list_view.dart
flutter test
```

Expected: no new analyzer errors, all tests pass.

- [ ] **Step 5: Manual PDF check**

```bash
flutter run -d chrome
```

Verify on the same multi-day event:

- [ ] Press **Export PDF** with no filters. Open the PDF: each day's races are preceded by a day-header band showing the date and race count. Day order is ascending.
- [ ] Apply a Date filter (one day), press **Export PDF**: only that day's races appear, preceded by its day header.
- [ ] Apply a non-date filter (e.g., Age Group): PDF respects the filter, day headers still appear above each remaining day's races.
- [ ] On a single-day event, the PDF still shows one day header.

- [ ] **Step 6: Commit**

```bash
git add lib/src/races/race_results_list_view.dart
git commit -m "Race results: group PDF export by day with day headers"
```

---

## Task 6: Regression sweep + cleanup

**Files:** none modified unless an issue is found.

- [ ] **Step 1: Re-test all interactions end-to-end**

Run `flutter run -d chrome` once more and walk through:

- [ ] Refresh while a date filter is active — list reapplies the filter; day grouping stays correct.
- [ ] Open a race detail by tapping a race row when the day section is expanded.
- [ ] Verify a race with no crews still navigates to detail on tap (existing behaviour preserved in `_buildRaceRow`).
- [ ] Verify competition chips at the top still filter as before.
- [ ] Switch between two different events (e.g., a single-day and a multi-day event) — both render correctly.

- [ ] **Step 2: Final analyzer pass**

```bash
flutter analyze
```

Expected: 0 errors. Address any new warnings introduced by this change.

- [ ] **Step 3: Final test pass**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit anything found** (only if changes are needed)

```bash
git add -p
git commit -m "Race results: regression fixes from manual sweep"
```

If nothing needed changing, skip this commit.

---

## Task 7 (release-only): Bump patch version + deploy

**Only run this task when the user says "deploy".** Per project `CLAUDE.md`, regular work does not bump the version.

**Files:**
- Modify: `lib/config/app_version.dart`

- [ ] **Step 1: Bump the patch**

In `lib/config/app_version.dart`, change `patch` from its current value to the next integer string (e.g., `'72'` → `'73'`).

- [ ] **Step 2: Commit**

```bash
git add lib/config/app_version.dart
git commit -m "v0.6.<next>: race results grouped by day + date filter"
```

- [ ] **Step 3: Deploy via the project's release flow** (per `CLAUDE.md`)

```bash
git checkout release
git merge main --ff-only
git push origin release
git checkout main
```

This triggers the GitHub Actions build/deploy.

---

## Self-review notes

- **Spec coverage:** Every spec section maps to a task — Task 1 (helpers), Task 2 (state + Expand/Collapse + filter wiring), Task 3 (day-section rendering + always-show-headers behaviour), Task 4 (Date section in Filters dialog + active chips), Task 5 (PDF parity), Task 6 (regression), Task 7 (version bump).
- **Type consistency:** `dayKey` / `groupRacesByDay` / `_expandedDays: Set<DateTime>` / `_filterDates: List<DateTime>` / render-item class names match across tasks.
- **Edge cases from spec:** null `raceTime` (omitted in `groupRacesByDay` and the PDF path), all-filtered-out (`_EmptyItem` branch), refresh-day-changes (rebuild on each `_buildRenderItems` call), stale fold-state (extra keys in `_expandedDays` are ignored).
- **Frequent commits:** each task ends with a commit.
- **No placeholders:** every code-step shows complete code.
