## Context

`AnimatedEntity` (`addons/godot-pixel-core/entity/animated_entity.gd`) is the sprite **presenter**: it owns `action`, `direction`, `frame`, and advances frames on a `Timer` at `frame_rate`. `update_sprite()` resolves textures via `sprite_lookup.get_texture(..., direction, frame, ...)`.

Today `direction` is a plain `String` with no setter. Bodies assign it directly — e.g. `PlayerEntity` sets `animated_entity.direction` every physics frame from input. A sharp turn (e.g. **W** → **E**) updates `direction` instantly, so the next `update_sprite()` jumps four compass rows on the sheet.

The canonical eight-direction ring is already defined in `SpriteSheetLookupBase.DIRECTIONS`: **S, SE, E, NE, N, NW, W, SW** (indices 0–7, counter-clockwise from south). This change adds presenter-side **transition state** so multi-step turns walk the ring one facing per animation tick.

## Goals / Non-Goals

**Goals:**

- Step through intermediate facings on the eight-direction ring when the requested facing is **two or more steps** away from the **currently displayed** facing.
- Advance **one ring step per animation frame** (same `Timer` as existing frame advance) for a quick, readable turn.
- Use the **shortest** clockwise or counter-clockwise arc; on **180°** ties (four steps each way), pick a path **at random**.
- Apply to **all actions** that use facing rows (walk, idle, future attack clips, etc.).
- On a new target while transitioning, **restart** from the current displayed facing toward the new target.
- Keep transition logic entirely in the presenter; bodies only express **target** intent.

**Non-Goals:**

- Sheet layout, lookup, lighting, or tile changes.
- Per-body transition code or animation blending between facings.
- Custom durations, easing, or holding on intermediate facings.
- Editor-time animated transitions (editor preview may snap immediately).

## Decisions

### Decision 1: Split displayed facing from target facing inside `AnimatedEntity`

Introduce internal state:

| Field | Role |
|-------|------|
| `direction` (existing property) | **Displayed** facing — value passed to `get_texture` / `update_sprite` |
| `_target_direction` | **Requested** facing from gameplay or `set_direction()` |
| `_transition_step` | Ring step per tick: `+1` (toward higher index mod 8), `-1` (toward lower), or `0` (not transitioning) |

Bodies call `set_direction(target: String)`. The public `direction` getter continues to reflect what is **on screen** so existing `update_sprite()` and lit normal alignment stay unchanged.

**Rationale:** Separating target from display is the minimal way to support lag during transitions and restart-on-interrupt without bodies tracking presenter internals.

**Alternatives considered:**

- *Bodies own transition queues*: rejected — duplicates logic across `PlayerEntity` and every future driver.
- *Only transition during walk*: rejected — proposal requires all facing-based actions.

### Decision 2: Advance direction on the existing animation `Timer`

Hook direction stepping into `_on_animation_timeout()` **after** (or alongside) frame index advancement:

1. If `_transition_step != 0` and displayed index ≠ target index, move displayed index by `_transition_step` (mod 8), map back to direction name, call `update_sprite()`.
2. When displayed reaches target, set `_transition_step = 0`.

**Rationale:** “One facing per animation frame” maps naturally to the presenter’s existing FPS timer. No second timer, no `_process` polling, and turn speed scales with `frame_rate` (already forwarded from character bodies).

**Alternatives considered:**

- *Separate turn timer*: extra tuning surface and desync from walk cycle; rejected.
- *Step direction in `_physics_process`*: would outpace animation FPS and tie turns to physics rate; rejected.

### Decision 3: Immediate snap for adjacent facings; transition for distance ≥ 2

Compute ring distance from displayed index to target index:

- **Distance 0**: no-op.
- **Distance 1** (adjacent on ring): set displayed = target immediately, `_transition_step = 0`.
- **Distance ≥ 2**: set `_target_direction`, compute `_transition_step` (+1 or −1) via shortest path; leave displayed unchanged until timer ticks.

Shortest-path rule on indices `from`, `to` (0–7):

```
cw  = (to - from + 8) % 8
ccw = (from - to + 8) % 8
if cw < ccw  → step +1
if ccw < cw  → step -1
if cw == ccw → random +1 or -1   # 180° tie (distance 4)
```

**Rationale:** Matches proposal — adjacent turns feel instant; only “skipped” directions get the stepped arc.

### Decision 4: Interrupt = recompute from displayed, not from abandoned target

When `set_direction(new_target)` is called during an active transition:

1. Set `_target_direction = new_target`.
2. Re-run path selection using **current displayed** index (not the old target).
3. Re-roll random direction on a new 180° tie.

**Rationale:** Matches user requirement — rapid input changes should turn from where the sprite **currently** faces, avoiding snap-back to a stale arc.

### Decision 5: Public API — `set_direction()`; property setter delegates

Add:

```gdscript
func set_direction(new_direction: String) -> void
```

`PlayerEntity` (and `test/static_lit_prop.gd` if still relevant) switch from `animated_entity.direction = …` to `animated_entity.set_direction(…)`.

The `direction` property **setter** (new) delegates to `set_direction()` so accidental direct assignment still goes through transition rules. The **getter** returns the displayed facing.

In the **editor** (`Engine.is_editor_hint()`), `set_direction` / setter may snap displayed = target immediately so inspector edits and `refresh_editor_sprite_preview()` stay responsive — transitions are runtime-only.

**Rationale:** One code path for gameplay; editor remains usable without simulating multi-frame turns.

**Alternatives considered:**

- *Setter snaps, only `set_direction` transitions*: two behaviors confuse authors; rejected in favor of unified path with editor exception.

### Decision 6: No opt-out export in v1

Ship transitions always on for runtime presenter instances. No `use_direction_transition` flag unless a consumer need appears during implementation.

**Rationale:** Proposal defers tuning to design; YAGNI for a single global behavior with no known opt-out requirement.

## Risks / Trade-offs

- **[Risk]** Visible facing lags input on sharp reversals (up to three frames for a 180° turn if random path goes the long way — wait, 180° is 4 steps each way, so 4 frames at 12 FPS ≈ 0.33s). → **Mitigation:** acceptable per “quick transition” goal; adjacent taps still snap instantly. Document that `frame_rate` affects turn speed.
- **[Risk]** Rapid oscillation (e.g. left-right tap) could perpetually restart transitions and never settle. → **Mitigation:** each restart still moves one step per frame toward the **latest** target; worst case is responsive following, not deadlock.
- **[Trade-off]** During transition, physics velocity and displayed facing can disagree briefly (body moves **E** while sprite still shows **NW**). → **Accepted:** common in classic eight-direction games; bodies use input vector for movement, presenter catches up visually.
- **[Risk]** Invalid direction strings fall through lookup to row 0 (**S**). → **Mitigation:** validate in `set_direction`; ignore or clamp invalid names same as lookup’s existing fallback (document in implementation).
- **[Risk]** Action changes mid-transition (`set_action`) do not reset direction state. → **Mitigation:** intentional — transition continues on the new action’s rows at the same displayed/target facings; add test-scene manual check.

## Migration Plan

1. Implement transition state and `set_direction()` in `animated_entity.gd`; wire `_on_animation_timeout()`.
2. Update `player_entity.gd` to call `set_direction()`.
3. Grep addon + `test/` for other `animated_entity.direction =` assignments; migrate to `set_direction()`.
4. Manual test in `test/test_scene.tscn`: hold **W**, then tap **E** (or opposite) and confirm stepped facings on walk and idle.
5. **Rollback:** revert presenter changes; bodies can restore direct `direction` assignment (no data migration).

No consumer scene migration required beyond submodule update; behavior change is automatic for all `AnimatedEntity` users.

## Open Questions

- **Test-scene scenario shape:** dedicated on-screen hint text (“tap opposite direction”) vs. relying on natural play — resolve in `test-scene` delta spec / tasks.
- **Invalid direction strings:** silent clamp to **S** vs. `push_warning` — lean toward same behavior as lookup (clamp) unless specs require a warning.
