## 1. Character entity helpers (`character_entity.gd`)

- [x] 1.1 Add `const _ISO_DIAG_Y_RATIO := 0.5` and `func remap_input_to_screen(input: Vector2) -> Vector2` (zero / cardinal / 2:1 diagonal cases; unit output).
- [x] 1.2 Move `_vector_to_direction(v: Vector2) -> String` from `player_entity.gd` unchanged (8-sector bucket via `SpriteSheetLookupBase.DIRECTIONS`).

## 2. Player entity (`player_entity.gd`)

- [x] 2.1 Compute `move_dir := remap_input_to_screen(input_direction)` once per frame.
- [x] 2.2 Set `velocity = move_dir * speed`; pass `move_dir` to `_vector_to_direction()` for `set_direction()`.
- [x] 2.3 Remove the local `_vector_to_direction` definition.

## 3. Manual verification (`test/test_scene.tscn`)

- [x] 3.1 Hold **SE** input — movement shallower than old 45° diagonal.
- [x] 3.2 Hold pure **E** and **S** — axis-aligned, same speed as diagonals.
- [x] 3.3 On each diagonal, walk facing matches travel direction.

## 4. Validation

- [x] 4.1 Run `openspec validate iso-movement --strict`; expect pass.
- [x] 4.2 Cross-read delta specs against implementation.
