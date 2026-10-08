## 1. Canonical direction order in lookup

- [x] 1.1 Update `DIRECTIONS` in `addons/godot-pixel-core/sprite_sheet/sprite_sheet_lookup_base.gd` to `S, SE, E, NE, N, NW, W, SW` and fix comments (`direction_name_to_index`, `compute_rect_animated`) to state row 0 = S, proceeding counter-clockwise
- [x] 1.2 Update docstrings in `addons/godot-pixel-core/sprite_sheet/animated_sprite_sheet_lookup.gd` (and `sprite_sheet_lookup_base.gd` if needed) so direction index 0–7 matches the new row semantics

## 2. Player facing alignment

- [x] 2.1 Update `addons/godot-pixel-core/entity/player_entity.gd` so `_vector_to_direction` produces the canonical direction strings in lockstep with `SpriteSheetLookupBase` (remove or replace the local `DIRECTIONS` constant if redundant)

## 3. Verification

- [x] 3.1 Run the test scene: confirm walk/idle show the correct facing for eight-way input after code updates (do not modify sprite sheet PNGs)
