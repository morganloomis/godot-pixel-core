## 1. Presenter action transition state (`animated_entity.gd`)

- [x] 1.1 Add internal fields `_playback_action: String` and `_in_action_transition: bool`; initialize `_playback_action = action` in `_ready()`.
- [x] 1.2 Add `_transition_clip_exists(transition_name: String) -> bool` using `sprite_lookup.get_frame_count(entity, transition_name) > 0`.
- [x] 1.3 Refactor `update_sprite()` and frame-count lookup in `_on_animation_timeout()` to use `_playback_action` instead of `action` for `get_texture` / `get_frame_count`.
- [x] 1.4 In `_on_animation_timeout()`, add a dedicated branch for `_in_action_transition`: advance frames once through the bridge; on last frame, clear `_in_action_transition`, set `_playback_action = action`, reset `_frame = 0`, keep timer running (no `_clip_finished`, no `animation_finished`).
- [x] 1.5 Rewrite `set_action(new_action)`: set logical `action` immediately; on non-interrupt path try `{previous}-{new_action}` transition; on interrupt path skip transition lookup and set `_playback_action = new_action`; early-out when `new_action == action and not _in_action_transition`; no-op when mid-bridge to same logical target.
- [x] 1.6 Confirm `_get_playback_mode(action)` uses logical `action` only; transition folders are never keyed in `playback_modes`.
- [x] 1.7 Confirm `_advance_direction_transition()` still runs after frame logic and is unaffected by action transition state.

## 2. Documentation

- [x] 2.1 Add a brief `{from}-{to}` transition folder convention note to `addons/godot-pixel-core/README.md` (naming, optional, not `PLAY_ONCE`, not assigned via `set_action` from gameplay).

## 3. Automated verification (test harness, code-only)

- [x] 3.1 Add a small test script under `test/` (or extend an existing harness) that instances `AnimatedEntity` with a stub lookup using `frame_count_override` to simulate `idle`, `walk`, and `idle-walk` without new art.
- [x] 3.2 Assert transition-present path: after `set_action("walk")` from `idle`, `_playback_action` is `idle-walk` and `action` is `walk`.
- [x] 3.3 Assert fall-through path: without `idle-walk` frames, `_playback_action` becomes `walk` immediately.
- [x] 3.4 Assert interrupt path: mid-bridge `set_action("run")` sets `_playback_action` to `run` with no transition lookup.
- [x] 3.5 Assert `animation_finished` does not emit when a bridge completes into looping `walk`; assert it does emit when a terminal `PLAY_ONCE` logical action completes.
- [x] 3.6 Run the test script headless via Godot CLI (`--headless --script …` or documented project test entry) and confirm pass.

## 4. Manual test scene check

- [x] 4.1 If test art includes an `{from}-{to}` folder for the player entity, play `test/test_scene.tscn`: idle → walk should show the bridge once before walk loops. *(N/A — no `idle-walk` folder under `test/art/sprite/player/`.)*
- [x] 4.2 Rapidly change action during a bridge (if art exists) and confirm immediate snap to the new action without a new transition lookup. *(N/A — same missing art.)*

## 5. Validation

- [x] 5.1 Run `openspec validate transition-clips --strict`; expect pass.
- [x] 5.2 Cross-read delta specs (`animated-action-transition`, `sprite-presentation`, `sprite-sheet-layout`) against the implementation; confirm logical `action`, interrupt skip, non-terminal bridge playback, and direction independence match requirements.
