# Race Results: Group by Day + Date Filter

## Background

The Race Results page (`lib/src/races/race_results_list_view.dart`) currently
renders all races for an event as a single flat, race-number-sorted list. For
multi-day events this makes the schedule hard to scan and offers no way to
narrow the view to a specific day.

Each `RaceResult` already has a `raceTime: DateTime?` field, so day grouping
can be derived client-side without any backend or model changes.

## Goals

- Group races by day on the Race Results page.
- Day sections are collapsible, with always-visible headers.
- Provide a date multi-select filter inside the existing Filters dialog.
- Keep the existing PDF export consistent with the on-screen grouping.

## Non-goals

- No changes to the backend, API, or `RaceResult` model.
- No changes to the per-race expand/collapse behaviour or race-row layout.
- No new top-level navigation, no new screens.
- No special handling for unscheduled races (see "Edge cases" — they are
  hidden).

## UX

### Day sections

- Within the list, races are grouped by date key
  `DateTime(raceTime.year, raceTime.month, raceTime.day)`.
- Each group renders a **day header row** above its races containing:
  - Weekday + date in the form `Saturday, 13 Jun 2026` (formatted via
    `intl`'s `DateFormat('EEEE, d MMM yyyy')`).
  - The race count for that day (e.g. `12 races`).
  - A chevron indicating expanded/collapsed state.
- Tapping the day header toggles the group fold state.
- The header uses the same competition colour band as race rows but with
  larger/bolder typography and the chevron so it reads as a section header,
  not a race tile.
- Day headers are **always shown**, even when only one day is present.

### Default state

- On initial load, **all day sections are expanded** (so the page looks
  similar to today's flat list, just with section dividers).
- Individual races remain collapsed by default (current behaviour).

### Expand All / Collapse All

These existing header buttons act on **both** levels:

- **Expand All** — opens every day section AND expands every race row
  (adds all race ids to `_expandedRaces` and all day keys to `_expandedDays`).
- **Collapse All** — folds every day section AND collapses every race row
  (clears both sets).

### Date filter

- A new **"Date"** section is added to the Filters dialog (`_showFilters`),
  placed **first** in the dialog (above Age Group), because it is the most
  coarse-grained filter.
- Renders as a `Wrap` of `FilterChip`s, one per available date in the
  current `_raceResults`, formatted as `EEE, d MMM` (e.g., `Sat, 13 Jun`).
- Multi-select with the same OR-within / AND-between semantics as the other
  list-based filters.

### Active filter chips

The active-filter chip strip (`_buildActiveFiltersChips`) gains date chips
styled like the existing chips, labeled `Date: Sat 13 Jun`, with a delete
icon that removes the date from `_filterDates` and re-applies filters.

### Single-day events

When only one date is present, the day header still renders (per the
"always show day headers" decision). The date filter section in the dialog
will simply show a single chip.

## Implementation

### State additions in `_RaceResultsListViewState`

```dart
final Set<DateTime> _expandedDays = <DateTime>{};
final List<DateTime> _filterDates = [];
```

Convention matches the existing `_expandedRaces` (membership = expanded) and
the other list-based filters.

### Date-key helper

A small private helper:

```dart
DateTime _dayKey(DateTime t) => DateTime(t.year, t.month, t.day);
```

Used for grouping, fold state, and filter equality.

### Grouping at render time

In `_buildBody()`:

1. Take `races = _filteredRaceResults ?? _raceResults ?? []`.
2. Filter out races where `raceTime == null` (they do not appear).
3. Sort by `raceNumber` as today.
4. Build `LinkedHashMap<DateTime, List<RaceResult>>` keyed by `_dayKey`,
   iterating in chronological order (ascending by date).
5. Flatten into a render item list:
   `[Header, DayHeader(d1), races..., DayHeader(d2), races..., ...]`
   with an "empty" message when the list is otherwise empty.

The `ListView.builder` `itemCount` and `itemBuilder` are updated to walk this
flattened render-item list. A race row is only built when the containing
day's key is in `_expandedDays`.

### Filter wiring

`_applyFilters()` gains:

```dart
if (_filterDates.isNotEmpty) {
  if (race.raceTime == null) return false;
  final key = _dayKey(race.raceTime!);
  if (!_filterDates.any((d) => _dayKey(d) == key)) return false;
}
```

`_showFilters()` is extended with a "Date" `Wrap` of `FilterChip`s using
the set of unique day keys derived from `_raceResults`.

`_buildActiveFiltersChips()` gains date chips that remove from
`_filterDates` and call `_applyFilters()`.

### Expand All / Collapse All wiring

```dart
void _expandAll() {
  setState(() {
    final races = _filteredRaceResults ?? _raceResults ?? [];
    _expandedRaces.addAll(races.map((r) => r.id));
    _expandedDays.addAll(
      races
          .where((r) => r.raceTime != null)
          .map((r) => _dayKey(r.raceTime!))
          .toSet(),
    );
  });
}

void _collapseAll() {
  setState(() {
    _expandedRaces.clear();
    _expandedDays.clear();
  });
}
```

### Initial expansion

After `_raceResults` is set in `_loadRaceResults`, pre-populate
`_expandedDays` with every day key found in the freshly loaded list. On a
refresh that introduces a new day, that new day is also added so it appears
expanded by default. (Days that have disappeared can be left in the set
harmlessly.)

### PDF export

`_exportToPDF()` builds the same date-keyed groups and emits a styled day
header (e.g., a coloured `pw.Container` with the formatted day string)
before each day's races. PDF already operates on the filtered list, so the
date filter applies automatically.

## Edge cases

- **Race with `raceTime == null`**: omitted from the on-screen list and the
  PDF. Will not appear as an "Unscheduled" group.
- **All races filtered out**: existing "No race results match your filters"
  message remains; no day headers shown.
- **Refresh changes a race's day**: harmless — the new grouping is computed
  fresh on each build.
- **Fold state stale after refresh**: `_expandedDays` may contain day keys
  that no longer have any races (after delete/edit upstream). They're
  ignored at render and re-added if those days come back.

## Files touched

- `lib/src/races/race_results_list_view.dart` (only file modified)

No backend, model, API, or routing changes.

## Testing

Manual verification on the Race Results page for `Nihao Festival, Belgrade
2026` (the event from the user's screenshot):

- Multiple day headers appear in chronological order.
- Tapping a day header folds/unfolds its races.
- Expand All opens every day and every race; Collapse All folds everything.
- Filters dialog shows a Date section with one chip per available day.
- Selecting one or more dates filters the list and adds active chips.
- Removing the active date chip restores the full list.
- PDF export renders day headers above each day's races and respects the
  active date filter.
