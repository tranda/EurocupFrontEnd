# Drag-and-Reorder Races in Grid Tab — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let organizers reorder generated races by dragging rows in the Grid tab. The dragged race takes the destination slot's time; the slot times themselves do not change.

**Architecture:** Slot-swap reorder. Frontend uses `ReorderableListView` per date-section in `grid_tab.dart`. On drop, the affected slice of races has its `race_time` values permuted to match the new visual order. Frontend sends batch `(race_id, race_time)` updates to a new backend endpoint that updates in a DB transaction and re-runs `renumberRaces`. No new schema columns; race-to-block membership stays implicit.

**Tech Stack:** Flutter (Dart) frontend with Material `ReorderableListView`; Laravel 11 backend with PHPUnit feature tests; existing `auth:sanctum` middleware for routes.

**Spec:** [docs/superpowers/specs/2026-05-16-drag-reorder-races-design.md](../specs/2026-05-16-drag-reorder-races-design.md)

**Repo layout reminder:** Frontend repo `EurocupFrontEnd/` and backend repo `eventsmotion/` are independent git repositories. Each task notes which directory to work in. Always `cd` into the right one before running git commands.

---

## Task 0: Delete obsolete unit-test for removed lane-count check

**Context:** We earlier removed the `lane_count must be 4, 6, or 8` guard from `ScheduleGeneratorService::generate()`. A test in the backend repo still asserts that exception. It will fail next time CI runs. Delete it before adding new work.

**Files:**
- Modify: `eventsmotion/tests/Feature/Schedule/ScheduleGeneratorServiceTest.php` (lines 193-201)

- [ ] **Step 1: Delete the obsolete test method**

In `eventsmotion/tests/Feature/Schedule/ScheduleGeneratorServiceTest.php`, find the method below and delete the whole method including its preceding blank line:

```php
    public function test_throws_when_lane_count_unsupported(): void
    {
        $event = $this->makeEvent(laneCount: 5);
        $this->addBlock($event, 'Morning', '09:00:00');

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('lane_count must be 4, 6, or 8');
        $this->service->generate($event);
    }
```

- [ ] **Step 2: Run the test file to confirm nothing else regressed**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/eventsmotion
php artisan test --filter=ScheduleGeneratorServiceTest
```

Expected: all remaining tests pass. If any fail, stop and report — do not move on.

- [ ] **Step 3: Commit (backend repo)**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/eventsmotion
git add tests/Feature/Schedule/ScheduleGeneratorServiceTest.php
git commit -m "$(cat <<'EOF'
Remove obsolete lane-count exception test

The 4/6/8 lane-count restriction was lifted in 57979cb; the matching
test must go too.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 1: Backend — expose a public renumber method on ScheduleGeneratorService

**Why:** The new reorder endpoint must re-run chronological renumbering after updating `race_time`. The existing `renumberRaces` is private. Cleanest fix: make a public wrapper, leave the private method intact.

**Files:**
- Modify: `eventsmotion/app/Services/Schedule/ScheduleGeneratorService.php` (end of class, around line 438)

- [ ] **Step 1: Add public wrapper method**

In `eventsmotion/app/Services/Schedule/ScheduleGeneratorService.php`, find the existing `private function renumberRaces(Event $event): void` method. Immediately **before** it, add:

```php
    /**
     * Public entry point to renumber an event's races by chronological order.
     * Used by edit/reorder flows that update race_time outside generation.
     */
    public function renumberEventRaces(Event $event): void
    {
        $this->renumberRaces($event);
    }

```

- [ ] **Step 2: Sanity-check syntax**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/eventsmotion
php -l app/Services/Schedule/ScheduleGeneratorService.php
```

Expected: `No syntax errors detected ...`

No commit yet — bundle with Task 3.

---

## Task 2: Backend — write failing feature test for reorder endpoint

**Files:**
- Create: `eventsmotion/tests/Feature/Schedule/RaceReorderTest.php`

- [ ] **Step 1: Inspect the existing ScheduleGeneratorServiceTest helpers**

Read `eventsmotion/tests/Feature/Schedule/ScheduleGeneratorServiceTest.php` lines 250-end to see how `makeEvent`, `addBlock`, `makeDiscipline` build fixtures. Reuse the same factory style in the new test.

- [ ] **Step 2: Create the failing test file**

Create `eventsmotion/tests/Feature/Schedule/RaceReorderTest.php`:

```php
<?php

namespace Tests\Feature\Schedule;

use App\Models\Crew;
use App\Models\Discipline;
use App\Models\Event;
use App\Models\EventDay;
use App\Models\RaceResult;
use App\Models\ScheduleBlock;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Feature tests for POST /api/race-results/reorder.
 *
 * The endpoint accepts a batch of (race_id, race_time) pairs, applies
 * them atomically, and renumbers the event's races chronologically.
 * Intended use: drag-reorder in the Grid tab.
 */
class RaceReorderTest extends TestCase
{
    use RefreshDatabase;

    public function test_reorder_endpoint_updates_race_times_and_renumbers(): void
    {
        [$user, $races] = $this->seedThreeScheduledRaces();
        Sanctum::actingAs($user);

        // races initially at 09:00, 09:15, 09:30 (race_number 1, 2, 3).
        // Permute to put race[2] first, race[0] second, race[1] third.
        $updates = [
            ['race_id' => $races[2]->id, 'race_time' => '2026-06-07 09:00:00'],
            ['race_id' => $races[0]->id, 'race_time' => '2026-06-07 09:15:00'],
            ['race_id' => $races[1]->id, 'race_time' => '2026-06-07 09:30:00'],
        ];

        $response = $this->postJson('/api/race-results/reorder', ['updates' => $updates]);

        $response->assertOk();

        $fresh = RaceResult::orderBy('race_time')->get();
        $this->assertSame(
            [$races[2]->id, $races[0]->id, $races[1]->id],
            $fresh->pluck('id')->all(),
            'race_time values should be permuted to match new order'
        );
        $this->assertSame([1, 2, 3], $fresh->pluck('race_number')->all(),
            'race_number should be re-run chronologically');
    }

    public function test_reorder_endpoint_rejects_non_scheduled_race(): void
    {
        [$user, $races] = $this->seedThreeScheduledRaces();
        $races[1]->update(['status' => 'IN_PROGRESS']);
        Sanctum::actingAs($user);

        $updates = [
            ['race_id' => $races[1]->id, 'race_time' => '2026-06-07 09:00:00'],
            ['race_id' => $races[0]->id, 'race_time' => '2026-06-07 09:15:00'],
        ];

        $response = $this->postJson('/api/race-results/reorder', ['updates' => $updates]);

        $response->assertStatus(422);
        // Times must NOT have been written.
        $this->assertSame('SCHEDULED', $races[0]->fresh()->status);
        $this->assertNotEquals('2026-06-07 09:15:00', $races[0]->fresh()->race_time?->format('Y-m-d H:i:s'));
    }

    public function test_reorder_endpoint_rejects_empty_updates(): void
    {
        [$user] = $this->seedThreeScheduledRaces();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/race-results/reorder', ['updates' => []]);

        $response->assertStatus(422);
    }

    public function test_reorder_endpoint_requires_auth(): void
    {
        [, $races] = $this->seedThreeScheduledRaces();

        $response = $this->postJson('/api/race-results/reorder', [
            'updates' => [
                ['race_id' => $races[0]->id, 'race_time' => '2026-06-07 09:00:00'],
            ],
        ]);

        $response->assertStatus(401);
    }

    /**
     * Matches the fixture style in ScheduleGeneratorServiceTest: plain Model::create
     * rather than factories. User uses the standard factory (admin level).
     *
     * @return array{0: User, 1: array<int, RaceResult>}
     */
    private function seedThreeScheduledRaces(): array
    {
        $user = User::factory()->create(['access_level' => 3]);

        $event = Event::create([
            'name' => 'Test Event',
            'location' => 'Lake',
            'year' => 2026,
            'lane_count' => 6,
            'schedule_status' => 'draft',
        ]);
        $day = EventDay::create([
            'event_id' => $event->id,
            'date' => '2026-06-07',
            'name' => 'Day 1',
            'sort_order' => 0,
        ]);
        ScheduleBlock::create([
            'event_day_id' => $day->id,
            'name' => 'Morning',
            'start_time' => '09:00:00',
            'gap_seconds' => 900,
            'sort_order' => 0,
        ]);

        $discipline = Discipline::create([
            'event_id' => $event->id,
            'distance' => '200m',
            'age_group' => 'Senior',
            'gender_group' => 'M',
            'boat_group' => 'Standard',
            'status' => 'active',
        ]);
        for ($i = 0; $i < 6; $i++) {
            $team = Team::create(['name' => 'Team ' . ($i + 1)]);
            Crew::create([
                'team_id' => $team->id,
                'discipline_id' => $discipline->id,
                'seed_number' => $i + 1,
            ]);
        }

        $races = [];
        foreach (['09:00:00', '09:15:00', '09:30:00'] as $i => $time) {
            $races[] = RaceResult::create([
                'race_number' => $i + 1,
                'discipline_id' => $discipline->id,
                'race_time' => "2026-06-07 $time",
                'stage' => 'Heat ' . ($i + 1),
                'status' => 'SCHEDULED',
            ]);
        }

        return [$user, $races];
    }
}
```

- [ ] **Step 3: Run the new test file and confirm it fails because the route doesn't exist**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/eventsmotion
php artisan test --filter=RaceReorderTest
```

Expected: 4 tests, all fail with 404 (route not found) or similar. **If a test fails for a different reason** (missing factory, model column mismatch), stop and report — the fixture setup needs adjustment first.

No commit yet.

---

## Task 3: Backend — implement reorder controller method + route

**Files:**
- Modify: `eventsmotion/app/Http/Controllers/API/RaceResultController.php` (add method)
- Modify: `eventsmotion/routes/api.php` (add route near line 142)

- [ ] **Step 1: Add the `reorder` method to RaceResultController**

In `eventsmotion/app/Http/Controllers/API/RaceResultController.php`, add at the end of the class (before the closing `}`):

```php
    /**
     * Bulk-update race_time values for a slice of races (drag-reorder in Grid tab).
     * All races must be SCHEDULED. Renumbers the affected event(s) after update.
     *
     * Request body:
     *   { "updates": [ { "race_id": int, "race_time": ISO8601 string }, ... ] }
     *
     * Response 200: { "success": true, "updated": N }
     * Response 422: validation or status-guard failure (atomic — no writes).
     */
    public function reorder(\Illuminate\Http\Request $request)
    {
        try {
            $request->validate([
                'updates' => 'required|array|min:1|max:200',
                'updates.*.race_id' => 'required|integer|exists:race_results,id',
                'updates.*.race_time' => 'required|date',
            ]);

            $updates = $request->input('updates');
            $raceIds = array_column($updates, 'race_id');
            $races = \App\Models\RaceResult::whereIn('id', $raceIds)->get()->keyBy('id');

            // Reject if any race is not SCHEDULED.
            foreach ($races as $race) {
                if ($race->status !== 'SCHEDULED') {
                    return $this->sendError(
                        'Validation error',
                        ['updates' => ["Race {$race->id} is {$race->status} and cannot be reordered."]],
                        422
                    );
                }
            }

            // Find the unique event(s) touched so we can renumber after writes.
            $eventIds = $races
                ->map(fn($r) => $r->discipline?->event_id)
                ->filter()
                ->unique()
                ->values();

            \Illuminate\Support\Facades\DB::transaction(function () use ($updates, $races) {
                foreach ($updates as $u) {
                    $race = $races[$u['race_id']];
                    $race->race_time = $u['race_time'];
                    $race->save();
                }
            });

            $generator = app(\App\Services\Schedule\ScheduleGeneratorService::class);
            foreach ($eventIds as $eventId) {
                $event = \App\Models\Event::find($eventId);
                if ($event) {
                    $generator->renumberEventRaces($event);
                }
            }

            return response()->json([
                'success' => true,
                'updated' => count($updates),
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->sendError('Validation error', $e->errors(), 422);
        } catch (\Exception $e) {
            return $this->sendError('Error reordering races', [$e->getMessage()], 500);
        }
    }
```

- [ ] **Step 2: Register the route**

In `eventsmotion/routes/api.php`, find the line:

```
Route::middleware('auth:sanctum')->put('race-results/{id}', [RaceResultController::class, 'update']);
```

Immediately **after** it (so before the DELETE on line 143), add:

```
Route::middleware('auth:sanctum')->post('race-results/reorder', [RaceResultController::class, 'reorder']);
```

- [ ] **Step 3: Run the test suite and confirm it passes**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/eventsmotion
php artisan test --filter=RaceReorderTest
```

Expected: all 4 tests pass. If any fail, fix the controller/route and re-run. Do not modify the test assertions to "make it pass" — diagnose the controller code.

- [ ] **Step 4: Run the full schedule-related suite to confirm nothing else regressed**

```bash
php artisan test --filter=Schedule
```

Expected: all pass.

- [ ] **Step 5: Commit (backend repo)**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/eventsmotion
git add app/Services/Schedule/ScheduleGeneratorService.php \
        app/Http/Controllers/API/RaceResultController.php \
        routes/api.php \
        tests/Feature/Schedule/RaceReorderTest.php
git commit -m "$(cat <<'EOF'
Add POST /race-results/reorder for drag-reorder in Grid tab

Bulk-updates race_time for a slice of SCHEDULED races atomically, then
runs renumberEventRaces so race_number stays chronological. Rejects the
whole batch if any race is non-SCHEDULED.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 6: Push (auto-deploys; no migration in this change)**

```bash
git push
```

---

## Task 4: Frontend — add `reorderRaces` API helper

**Files:**
- Modify: `EurocupFrontEnd/lib/src/api_helper.dart` (add function near line 1695, just after `updateRaceResultFields`)

- [ ] **Step 1: Add the helper function**

In `EurocupFrontEnd/lib/src/api_helper.dart`, find `updateRaceResultFields` (ends around line 1695). Immediately **after** its closing `}`, add:

```dart
/// Bulk-update race_time for drag-reorder in the Grid tab. Each entry is
/// `{ raceId, newTime }`. Backend updates atomically and renumbers chronologically.
Future<void> reorderRaces(List<({int raceId, DateTime newTime})> updates) async {
  final body = {
    'updates': [
      for (final u in updates)
        {
          'race_id': u.raceId,
          'race_time': u.newTime.toIso8601String(),
        },
    ],
  };
  final res = await http.post(
    Uri.parse('$apiURL/race-results/reorder'),
    headers: _jsonAuthHeaders(),
    body: jsonEncode(body),
  );
  _unwrap(res, action: 'reorder races');
}
```

- [ ] **Step 2: Confirm it analyzes clean**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/EurocupFrontEnd
flutter analyze lib/src/api_helper.dart
```

Expected: `No issues found!`

No commit yet — bundle with Task 5.

---

## Task 5: Frontend — wrap race rows in `ReorderableListView` with slot-swap onReorder

**Context:** The Grid tab is grouped by date (see `_grid()` and `_dateSection()` in `grid_tab.dart`). Each date section renders its races with `for (final r in rows) _raceCard(r)`. We replace that with a `ReorderableListView` so drag-reorder is naturally constrained to within-day (cross-day requires manual edit, per spec).

**Files:**
- Modify: `EurocupFrontEnd/lib/src/administration/schedule/tabs/grid_tab.dart` (replace race-row rendering in `_dateSection` around line 427)

- [ ] **Step 1: Locate the rendering site**

Open `EurocupFrontEnd/lib/src/administration/schedule/tabs/grid_tab.dart`. Inside `_dateSection`, find:

```dart
        for (final r in rows) _raceCard(r),
      ]),
    );
```

That single `for` loop is what becomes the `ReorderableListView`.

- [ ] **Step 2: Replace the loop with `ReorderableListView`**

Replace the line `        for (final r in rows) _raceCard(r),` with:

```dart
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: rows.length,
          itemBuilder: (ctx, i) {
            final race = rows[i];
            final canDrag = race.status == 'SCHEDULED';
            return Row(
              key: ValueKey('race-${race.id}'),
              children: [
                if (canDrag)
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.drag_indicator, color: Colors.grey),
                    ),
                  )
                else
                  const SizedBox(width: 40),
                Expanded(child: _raceCard(race)),
              ],
            );
          },
          onReorder: (oldIndex, newIndex) => _onReorder(rows, oldIndex, newIndex),
        ),
```

- [ ] **Step 3: Add the `_onReorder` method**

In the same file, inside `_GridTabState`, add this method (place it just below `_load` for cohesion):

```dart
  Future<void> _onReorder(List<RaceResult> rows, int oldIndex, int newIndex) async {
    // Flutter ReorderableListView quirk: newIndex is post-removal; adjust when moving down.
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex == oldIndex) return;

    final lo = oldIndex < newIndex ? oldIndex : newIndex;
    final hi = oldIndex < newIndex ? newIndex : oldIndex;

    // Block reorder if any race in the slice isn't SCHEDULED — slot-swap would
    // shift times for races that are already running/finished.
    for (var i = lo; i <= hi; i++) {
      if (rows[i].status != 'SCHEDULED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot reorder: a race in this range is running or finished.')),
        );
        return;
      }
    }

    // Capture the time values for the slice in original order — these are the
    // slot times that stay put.
    final slotTimes = [for (var i = lo; i <= hi; i++) rows[i].raceTime];

    // Compute the new ordering of races in the slice.
    final reordered = List<RaceResult>.from(rows);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Pair each slice position with the race now occupying it, and the original
    // slot time for that position.
    final updates = <({int raceId, DateTime newTime})>[];
    for (var i = lo; i <= hi; i++) {
      final race = reordered[i];
      final time = slotTimes[i - lo];
      if (time == null) continue; // skip "Unscheduled" rows — they have no slot
      if (race.raceTime == time) continue; // no-op for unchanged positions
      updates.add((raceId: race.id!, newTime: time));
    }

    if (updates.isEmpty) return;

    await _runWithBusy(() => api.reorderRaces(updates));
  }
```

- [ ] **Step 4: Static analysis**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/EurocupFrontEnd
flutter analyze lib/src/administration/schedule/tabs/grid_tab.dart lib/src/api_helper.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Manual verification (user-driven; required before commit)**

Tell the user to test in the running app:

1. Open the Grid tab on an event with multiple generated races.
2. Drag a race up — handle on the left edge of the row.
3. Confirm: the moved race adopts the destination slot's time; the displaced race adopts the moved race's old time; race numbers update after the implicit reload.
4. Try dragging a race that is `IN_PROGRESS` (if any exist) — expect snackbar refusal.
5. Confirm cross-day drag is impossible (the lists are separate sections per date).

**Wait for user confirmation that all five behaviors look right before moving on.**

- [ ] **Step 6: Bump version**

In `EurocupFrontEnd/lib/config/app_version.dart`, increment `patch` by 1. (For example, if currently `'56'`, change to `'57'`.)

- [ ] **Step 7: Commit (frontend repo)**

```bash
cd /Users/zorantrandafilovic/Documents/GitHub/EventsPlatform/EurocupFrontEnd
git add lib/src/administration/schedule/tabs/grid_tab.dart \
        lib/src/api_helper.dart \
        lib/config/app_version.dart
git commit -m "$(cat <<'EOF'
Drag-and-reorder races in Grid tab

Each date section is now a ReorderableListView. Dragging a race
permutes race_time values within the affected slice (slot-swap),
keeping slot times block-aligned. Non-SCHEDULED rows are not
draggable and block the operation if caught in the slice.

Bump version to 0.6.XX.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Replace `0.6.XX` in the commit message with the actual new version.)

- [ ] **Step 8: Deploy (push main + fast-forward release)**

```bash
git push
git checkout release
git merge main --ff-only
git push origin release
git checkout main
```

---

## Self-review checklist (run after implementation, before merging to release)

- [ ] Backend test file passes: `php artisan test --filter=RaceReorderTest`
- [ ] No new linter/analyzer warnings in the modified Dart files
- [ ] Existing edit-time dialog in Grid tab still works (we didn't break `_editRace`)
- [ ] Race numbers re-sequence chronologically after a drag
- [ ] Drag handles only show on `SCHEDULED` rows
- [ ] Cross-day drag is structurally impossible (each date renders its own `ReorderableListView`)
