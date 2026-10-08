## 1. Presenter transition state (`animated_entity.gd`)

- [x] 1.1 Add internal fields `_target_direction: String` and `_transition_step: int` (0 = idle, +1 / −1 = stepping on the ring), initialized so displayed and target both start at the current default facing.
- [x] 1.2 Add a private helper that maps a direction name to a ring index via `SpriteSheetLookupBase.DIRECTIONS` and computes shortest-path step (+1, −1, or 0 for snap/no-op) using clockwise vs counter-clockwise distance; on equal distance (180° opposition), pick +1 or −1 at random.
- [x] 1.3 Implement `set_direction(new_direction: String)`: validate or clamp invalid names consistently with lookup fallback; if editor hint, snap displayed and target immediately and refresh sprite; at runtime, if ring distance from **displayed** to target is 0 → no-op, if 1 → snap displayed to target, if ≥ 2 → store target and `_transition_step` without snapping displayed.
- [x] 1.4 Replace the plain `direction` var with a property whose getter returns the **displayed** facing and whose setter delegates to `set_direction()`.
- [x] 1.5 In `_on_animation_timeout()`, after frame index logic, if `_transition_step != 0` and displayed index ≠ target index, advance displayed by one ring step, call `update_sprite()`, and clear `_transition_step` when displayed reaches target.
- [x] 1.6 When `set_direction` is called mid-transition, recompute path from **current displayed** index toward the new target (re-roll random on 180° ties); do not reset transition state on `set_action()`.

## 2. Body scripts use presenter API

- [x] 2.1 In `addons/godot-pixel-core/entity/player_entity.gd`, replace `animated_entity.direction = _vector_to_direction(...)` with `animated_entity.set_direction(...)`.
- [x] 2.2 Grep `addons/godot-pixel-core/` and `test/` for remaining `animated_entity.direction =` or presenter `.direction =` assignments; migrate callers to `set_direction()` (e.g. `test/static_lit_prop.gd` if still assigning direction directly).

## 3. Test scene manual check

- [x] 3.1 Add a `Label` (or equivalent UI node) to `test/test_scene.tscn` with on-screen hint text instructing the tester to hold one direction then reverse to the opposed facing (e.g. left then right) to observe stepped facings.
- [x] 3.2 Play `test/test_scene.tscn` (F5): hold **W**, tap **E** while moving — confirm **walk** rows step through intermediate facings (not an instant **W** → **E** snap).
- [x] 3.3 Repeat a sharp reversal, then release input before the turn finishes — confirm **idle** rows continue stepping until the target facing is reached.
- [x] 3.4 Tap adjacent facings only (e.g. **E** → **NE**) — confirm immediate snap with no multi-frame arc.
- [x] 3.5 With lit mode enabled on the test `AnimatedEntity`, repeat 3.2 and confirm diffuse/normal stay aligned on each intermediate facing during the transition.

## 4. Validation

- [x] 4.1 Run `openspec validate direction-change --strict`; expect pass.
- [x] 4.2 Cross-read delta specs (`animated-direction-transition`, `sprite-presentation`, `player-entity`, `test-scene`) against the implementation; confirm adjacent snap, 180° random arc, interrupt-from-displayed, all-actions scope, and `set_direction` API match requirements.
