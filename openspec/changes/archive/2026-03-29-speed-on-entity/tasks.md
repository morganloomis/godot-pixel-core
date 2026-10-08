## 1. AnimatedEntity exports

- [x] 1.1 Add `@export var movement_speed: float` to `animated_entity.gd` with default `200.0` (match prior `CharacterEntity.speed`).
- [x] 1.2 Keep `@export var frame_rate` as the animation FPS control; add an `@export` hint or class doc so the inspector intent reads clearly as animation framerate (per design—no rename unless you accept `.tscn` migration).
- [x] 1.3 Ensure changing `frame_rate` in the editor updates the timer (e.g. `_apply_frame_rate()` on set or `NOTIFICATION_EDITOR_PRE_SAVE` / property setter) so exported framerate stays authoritative.

## 2. CharacterEntity wiring

- [x] 2.1 Remove `@export var speed` from `character_entity.gd` and expose a read-only `speed` (getter) that returns `animated_entity.movement_speed` when the child exists, otherwise the same numeric fallback as the design default.
- [x] 2.2 Confirm `player_entity.gd` and any other addon code using `speed` still compile and behave with the getter-only body API.

## 3. Scenes and verification

- [x] 3.1 Update packaged `.tscn` under `addons/godot-pixel-core/entity/` if any instance overrides `speed` on the body; move values to `AnimatedEntity`’s `movement_speed` / `frame_rate` as needed.
- [x] 3.2 Run `test/test_scene.tscn` (or main entry) and verify walk speed and animation timing match expectations when tuning `AnimatedEntity` exports.
