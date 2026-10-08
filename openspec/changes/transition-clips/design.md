## Context

`AnimatedEntity` (`addons/godot-pixel-core/entity/animated_entity.gd`) is the sprite **presenter**: it owns `action`, `direction`, `frame`, and advances frames on a `Timer` at `frame_rate`. `update_sprite()` resolves textures via `sprite_lookup.get_texture(entity, action, direction, frame, ...)`.

Today `set_action(new_action)` assigns `action` immediately, resets `frame` to 0, and restarts the timer. There is no bridge between clips — idle→walk snaps on the first frame.

**Direction transitions** already solve a similar problem: internal state separates **displayed** facing from **target** facing, stepping one ring position per timer tick (`animated-direction-transition`). This change adds parallel **action transition** state so optional `{from}-{to}` sheet folders play once before the target loop begins.

**Important semantic distinction:** transition clips **play through once** but are **not** `PlaybackMode.PLAY_ONCE` actions. `PLAY_ONCE` is reserved for **terminal** logical actions that permanently end animation (e.g. death): the timer stops, `_clip_finished` is set, and `animation_finished` may emit. Transition clips are ephemeral internal playback; when they finish, the presenter **always** continues into the requested target action.

## Goals / Non-Goals

**Goals:**

- On `set_action(target)`, when the previous logical action differs, look up `{previous}-{target}` (e.g. `idle-walk`) via existing lookup (`get_frame_count > 0`).
- If present, play that folder's frames once at `frame_rate`, then start `target` from frame 0 with its normal `playback_modes` entry.
- If absent, behave as today (immediate switch to `target`).
- Expose **logical/target** action through the public `action` property immediately on `set_action`, so bodies like `PlayerEntity` do not re-enter mid-bridge.
- On interrupt during a transition clip, **skip** transition lookup and jump straight to the newly requested logical action.
- Keep direction transition logic unchanged and independent (same timer tick).
- Never emit `animation_finished` for transition playback; never stop the timer solely because a transition clip ended.

**Non-Goals:**

- Inferring reverse clips (`walk-idle` from `idle-walk`), symmetric naming, or fuzzy matching.
- Transition lookup after an interrupt mid-bridge.
- Editor preview of transition clips or multi-frame action bridges in the inspector.
- Blending, cross-fade, or partial-frame resume from arbitrary poses.
- New lookup APIs or sheet layout changes beyond documenting `{from}-{to}` folder names.
- Treating transition folders as assignable logical actions from gameplay code.

## Decisions

### Decision 1: Split logical action from playback action

Introduce internal state alongside the existing `action` field (which becomes the **logical** action):

| Field | Role |
|-------|------|
| `action` (existing, semantic change) | **Logical/target** action — what gameplay requested (`walk`, `idle`, `die`) |
| `_playback_action` | Folder name passed to `get_texture` / `get_frame_count` — equals `action` normally, or `{from}-{to}` during a bridge |
| `_in_action_transition` | `true` while stepping through a transition clip |

`update_sprite()` and frame counting in `_on_animation_timeout()` use `_playback_action`. `playback_modes` lookups use **logical** `action` only (transition folders are never keyed in `playback_modes`).

**Rationale:** Mirrors the direction transition split (`_displayed_direction` vs `_target_direction`). Gameplay reads stable logical state; artists author bridge folders without polluting action enums in body scripts.

**Alternatives considered:**

- *Expose transition name via `action`*: rejected — causes bodies to re-call `set_action` every frame.
- *Separate public `target_action` property*: rejected — extra API surface; overloading `action` semantics is sufficient with documentation.

### Decision 2: Dedicated transition playback path (not `PlaybackMode.PLAY_ONCE`)

Transition clips use a **third playback path** inside `_on_animation_timeout()`, separate from `LOOP`, `PLAY_ONCE`, and `HOLD_LAST_FRAME`:

1. While `_in_action_transition`: advance `_frame` each tick; on last frame, clear `_in_action_transition`, set `_playback_action = action`, reset `_frame = 0`, call `update_sprite()`, **keep timer running**.
2. Do **not** consult `playback_modes` for the transition folder name.
3. Do **not** set `_clip_finished`, stop the timer, or emit `animation_finished`.

After the bridge, normal mode handling applies to logical `action` (typically `LOOP` for idle/walk).

**Rationale:** User requirement — one-shot **transitions** must not behave like one-shot **death** clips. Reusing `PLAY_ONCE` would incorrectly stop animation and fire terminal signals.

**Alternatives considered:**

- *Register transitions in `playback_modes` as `PLAY_ONCE`*: rejected — conflates terminal and bridge semantics; would require special-case signal/timer logic anyway.
- *Synthetic `PlaybackMode.TRANSITION` enum value*: viable but unnecessary; a boolean flag keeps `playback_modes` author-facing only.

### Decision 3: `set_action` flow

```gdscript
func set_action(new_action: String) -> void:
    if action == new_action and not _in_action_transition:
        return
    var previous := action
    action = new_action          # logical target immediately
    _clip_finished = false

    if _in_action_transition:
        # Interrupt: no transition lookup
        _in_action_transition = false
        _playback_action = new_action
    else:
        var transition_name := "%s-%s" % [previous, new_action]
        if _transition_clip_exists(transition_name):
            _playback_action = transition_name
            _in_action_transition = true
        else:
            _playback_action = new_action

    frame = 0
    # restart timer if stopped (e.g. after terminal PLAY_ONCE)
    ...
```

`_transition_clip_exists(name)` := `sprite_lookup.get_frame_count(entity, name) > 0`.

**Previous action for naming:** always the logical `action` **before** assignment (never a `{from}-{to}` folder), because `action` always holds logical state.

**Rationale:** Matches proposal and user answers: normal path tries `{from}-{to}`; interrupt path skips lookup entirely.

### Decision 4: Interrupt during transition → direct snap to new logical action

If `set_action` is called while `_in_action_transition` is true, abandon the bridge and set `_playback_action = new_action` with **no** `{current_bridge}-{new}` lookup.

**Rationale:** Half-played bridge frames have no well-defined source pose for a new transition name; gameplay expects immediate responsiveness.

### Decision 5: Timer hook ordering unchanged for direction

Keep `_advance_direction_transition()` at the end of `_on_animation_timeout()` so direction steps still occur once per tick during action transitions. Transition frame advance and direction step share the same cadence as today.

**Rationale:** User confirmed direction behavior is independent; reusing the timer avoids a second clock.

### Decision 6: `animation_finished` unchanged for logical actions only

Emit `animation_finished` only when a **logical** action with `PlaybackMode.PLAY_ONCE` completes (e.g. `die`). Transition completion silently hands off to the target action.

**Rationale:** Signal is for terminal or explicitly one-shot **gameplay** actions; nothing in the repo connects it yet, but the contract must stay clear for future death/interact handlers.

### Decision 7: Transition into or from terminal `PLAY_ONCE` actions

- **Into terminal action** (e.g. `walk` → `die`): if `walk-die` exists, play bridge then begin `die` under `PLAY_ONCE` rules.
- **From terminal action**: if `_clip_finished` is true (timer stopped after death), a new `set_action` already restarts the timer; transition lookup uses the previous logical action (`die`) as `from` if a `die-idle` folder exists (edge case for respawn flows).
- **During terminal playback**: `set_action` while a `PLAY_ONCE` clip plays is already possible via timer restart; transition rules apply normally from that logical previous action.

**Rationale:** Consistent application of `{from}-{to}` without special cases; rare respawn paths remain artist-driven via optional folders.

### Decision 8: No opt-out flag in v1

Always attempt transition discovery on non-interrupt `set_action` calls. No export to disable action transitions.

**Rationale:** Same YAGNI pattern as direction transitions; absence of folder already falls back to instant switch.

## Risks / Trade-offs

- **[Risk]** Artists name a transition folder that collides with a desired logical action (e.g. a real action literally named `idle-walk`). → **Mitigation:** document convention — transition folders use hyphenated `{from}-{to}` and should not be assigned via `set_action` from gameplay; logical action names remain simple tokens (`idle`, `walk`).
- **[Risk]** Logical `action` is `walk` while visuals show `idle-walk`, confusing debug prints. → **Mitigation:** document semantics; optional debug-only accessor can be added later if needed.
- **[Trade-off]** During bridge playback, `playback_modes[action]` does not describe what is on screen. → **Accepted:** transitions are presenter-internal; modes apply only after handoff.
- **[Risk]** Rapid `set_action` oscillation skips bridges entirely (always interrupt path after the first frame). → **Mitigation:** acceptable — responsiveness over playing partial bridges; matches interrupt spec.
- **[Risk]** `set_action` to same logical action during transition (`set_action("walk")` while bridging to walk) must not restart unnecessarily. → **Mitigation:** early-out when `new_action == action` **and** not `_in_action_transition`; if mid-bridge to the same target, allow no-op or continue current bridge (prefer **continue** — target unchanged).

## Migration Plan

1. Add `_playback_action`, `_in_action_transition`, and `_transition_clip_exists()` to `animated_entity.gd`.
2. Refactor `update_sprite()` / `_on_animation_timeout()` to use `_playback_action` for lookup and add transition completion handoff branch.
3. Rewrite `set_action()` per Decision 3–4; initialize `_playback_action = action` in `_ready()`.
4. Add tests under `test/` for: transition present, absent, interrupt, and verify `PLAY_ONCE` terminal action does not conflate with bridge completion.
5. Manual check in test scene if idle-walk art exists for an entity.
6. **Rollback:** revert presenter changes; no data or scene migration required.

No body script changes expected (`PlayerEntity` unchanged).

## Open Questions

- **Same-target no-op during bridge:** if `action` is already `walk` and `_in_action_transition` is true (bridging to walk), should a redundant `set_action("walk")` be ignored? Lean **yes** (no-op) — resolve in specs/tasks.
- **Test entity art:** which test entity will ship an `idle-walk` folder for automated/visual verification — resolve in specs/tasks (code-only constraint: tests can use `frame_count_override` without new PNGs).
