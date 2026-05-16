# Drag-and-Reorder Races in Grid Tab

**Date:** 2026-05-16
**Scope:** Frontend (EurocupFrontEnd) + Backend (eventsmotion)

## Goal

Let the schedule organizer reorder generated races by dragging rows in the Grid tab, instead of editing each race's time manually.

## Constraints from the existing data model

- Races have no `block_id` column. Each race's "block" is implicit, determined at generation time by matching race attributes (discipline distance/gender, race stage) against block filters in Setup.
- Race ordering is driven purely by `race_time`. The Grid tab already sorts by `race_time` then `race_number`.
- `renumberRaces` reassigns `race_number` sequentially over the event in chronological order after any generation.
- Races past `SCHEDULED` status (running or finished) must not be reorderable, mirroring the existing rule in `regenerateDiscipline`.

## Design: slot-swap reorder

### Semantics

Races sit in chronological "slots", one slot per `race_time` value. When the user drags race **R** from list index *i* to list index *j*, the **slot times stay put** and only the race-to-slot assignment changes within the affected slice.

Example, original order:

```
09:00  A
09:15  B
09:30  C
09:45  D
```

After dragging `D` to the top:

```
09:00  D
09:15  A
09:30  B
09:45  C
```

The four time values are unchanged; ownership rotates within the slice `[0..3]`.

### Why slot-swap works without `block_id`

- For drags **within a block**: existing times are block-aligned (start + gap*n). Permuting them within the slice preserves the alignment.
- For drags **across blocks** (e.g., morning → afternoon): the dragged race adopts the destination slot's time, effectively moving it to the other block. This is intuitive even without a block concept in the UI.
- No backend logic needs to infer "which block does this race belong to". The implicit block is whatever the new `race_time` falls into.

### What slot-swap does NOT do

- Insert into a new time outside the existing slot grid → still requires manual time edit (existing edit dialog).
- Reorder across calendar days → out of scope. Within-day only.
- Drag handles on lane sub-rows of an expanded race card → only the race row itself is draggable.

## Implementation

### Frontend (EurocupFrontEnd)

**File:** `lib/src/administration/schedule/tabs/grid_tab.dart`

- Replace the current race-row list with `ReorderableListView` (Flutter built-in).
- Drag handle: leading icon on each race row. Disabled (icon hidden or greyed) for races whose `status != 'SCHEDULED'`.
- Reorder callback:
  1. Compute the slice `[min(oldIndex, newIndex) .. max(oldIndex, newIndex)]` over the current `_races` list (which is sorted chronologically).
  2. Collect the time values for that slice in their original order.
  3. Build the new list by removing the dragged race and reinserting at `newIndex`.
  4. Assign the saved time values to the slice positions in order. Result: each race in the slice gets a new `race_time` corresponding to its new position's slot.
  5. POST the affected `(race_id, new_race_time)` pairs to the backend.
  6. On success, reload via `_load()` (which re-sorts and refetches). On failure, show snackbar and reload to revert.
- Cross-day guard: if any race in the slice has a different calendar date from the others, abort with a snackbar ("Cross-day reorder isn't supported — edit the time manually"). This prevents accidental day-jumps.

**API helper:** add `reorderRaces({required List<({int raceId, DateTime raceTime})> updates})` in `lib/src/api_helper.dart`. Single POST to the new endpoint below.

### Backend (eventsmotion)

**New endpoint:** `POST /api/race-results/reorder`

**Request body:**
```json
{
  "updates": [
    { "race_id": 123, "race_time": "2026-06-07 09:15:00" },
    { "race_id": 456, "race_time": "2026-06-07 09:00:00" }
  ]
}
```

**Validation:**
- `updates` array required, non-empty, max 200 entries.
- Each `race_id` must exist and belong to an event the caller can edit (existing auth rules).
- Each referenced race must have `status === 'SCHEDULED'`. Reject the whole batch otherwise.

**Behavior:**
- Wrap in DB transaction.
- Update `race_time` for each provided race.
- Call existing `renumberRaces(event)` so `race_number` stays chronological.
- Return the updated race list (or just `{ updated: N }`).

**Controller location:** add a `reorder` action on `RaceResultController` (or `ScheduleGenerationController` — wherever `regenerateDiscipline` lives, for cohesion).

**Route:** registered in `routes/api.php` next to existing race-result routes.

### Permissions

Same rule as existing race-result edit endpoints — the caller must be authorized to edit the event. Reuse the existing middleware/policy.

### Error handling

| Case | Frontend behavior |
|---|---|
| User drags a non-SCHEDULED race | Backend rejects 422; frontend shows snackbar + reloads |
| Network failure | Snackbar + reload |
| Cross-day slice detected client-side | Snackbar before sending request |
| Empty slice (drop on self) | No-op, no request |

## Testing checklist

- Drag race down a few slots within the same block → times reassign correctly, race_number updates after reload.
- Drag race up a few slots → same.
- Drag race across blocks within the same day → race takes destination slot's time, block membership implicitly shifts.
- Drag attempt across days → snackbar, no backend call.
- Drag attempt on a STARTED/FINISHED race → handle hidden/disabled; if somehow bypassed, backend 422.
- Verify chronological re-sort after reload matches drag intent.

## Out of scope (future enhancements)

- Adding a `block_id` column for explicit block membership.
- Drag-to-new-time (free-form, inserting into gaps).
- Multi-day reorder.
- Multi-select drag (move several races together).
- Undo/redo.
