## 1. Spec sync

- [x] 1.1 Update `openspec/specs/test-scene/spec.md` to replace every `"girl"` with `"player"` and rewrite the example paths under "Lookup configured for test assets" and "Test asset naming convention" to use `res://test/art/sprite/player/...`.

## 2. Test scene wiring

- [x] 2.1 In `test/test_scene.tscn`, change the `PlayerEntity` instance override from `entity_name = "girl"` to `entity_name = "player"`; verify `frame_rate = 24.0` and the `position` are preserved.
- [x] 2.2 In `test/static_lit_prop.tscn`, change the `AnimatedEntity` child instance override from `entity_name = "girl"` to `entity_name = "player"`.

## 3. Stray references

- [x] 3.1 Grep the repo for `girl` across `*.tscn`, `*.gd`, `*.md` and confirm no remaining references exist except in archived OpenSpec history (which stays as-is to preserve the record).

## 4. Verification

- [x] 4.1 Open `test/test_scene.tscn` in Godot 4.6 (`Godot_v4.6.1-stable_win64.exe`); confirm the player sprite renders, walk and idle animations play with WASD/arrow input, and the `DirectionalLight2D` + `PointLight2D` visibly affect shading on the lit `AnimatedEntity` child.
- [x] 4.2 Open `test/static_lit_prop.tscn` and confirm the static prop renders with the same lit setup.
