## 1. CharacterEntity forwards

- [x] 1.1 Add `@export` **movement_speed** on `CharacterEntity` with get/set delegating to `animated_entity.movement_speed` when the child exists; use fallback 200.0 for get when absent; in `@tool` editor hint, refresh presenter preview when movement speed changes if needed (match `entity_name` pattern).
- [x] 1.2 Add `@export` **frame_rate** on `CharacterEntity` with the same `@export_range` as `AnimatedEntity`, delegating to `animated_entity.frame_rate` with fallback 12.0 when the child is missing.
- [x] 1.3 In `_ready()`, after `_push_entity_name_to_presenter()`, ensure any root-authored values are pushed to the child when the child had empty defaults (or rely on setters when `@onready` assigns `animated_entity`—verify order and null safety).
- [x] 1.4 Update `CharacterEntity` class doc to state that movement speed and frame rate are authored on the root (forwarded) as well as on the child presenter; note that `speed` remains a read-only alias of presenter movement speed.

## 2. PlayerEntity and scenes

- [x] 2.1 Update `PlayerEntity` class doc to mention inherited **movement_speed** and **frame_rate** exports on the player root (no new properties unless inheritance is insufficient).
- [x] 2.2 Optionally align packaged `character_entity.tscn`, `player_entity.tscn`, and `entity/characters/player.tscn` so root exports show intended defaults in the inspector (only if values currently exist only on the child and you want parity).

## 3. Verification

- [x] 3.1 In the editor, select `PlayerEntity` and `CharacterEntity` instances and confirm inspector shows **movement speed** and **animation framerate** on the root; change values and confirm child `AnimatedEntity` updates and motion/animation behave correctly.
- [x] 3.2 Run or smoke-test `test/test_scene.gd` / relevant demo scenes to confirm player movement and animation timing still work.
