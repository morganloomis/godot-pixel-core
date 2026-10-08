# Proposal: Isometric movement

## Why

Pixel Core targets **orthographic isometric** pre-rendered pixel art, but `PlayerEntity` today applies raw `Input.get_vector()` velocity. That moves the body along **45°** screen diagonals (equal X and Y), which does not match typical iso presentation where **NE, NW, SE, and SW** travel at **~26.6°** from horizontal (classic **2:1** diamond axes). Characters slide at the wrong angle relative to the art and tile grid.

## What Changes

- Add two small helpers on **`CharacterEntity`**: isometric axis-input remap (2:1 diagonals, unchanged cardinals) and **`_vector_to_direction`** (moved up from `PlayerEntity`).
- **`PlayerEntity`** calls those inherited helpers for velocity and facing — no new scripts, no toggle, no option.
- Preserve normalized speed magnitude (diagonal travel is not faster than cardinal).

**Non-goals:** new files, `AnimatedEntity` changes, tile collision, pathfinding, camera rotation, grid snapping, README churn, or changes to sprite sheet row order / direction transition logic.

## Capabilities

### New Capabilities

- *(None.)*

### Modified Capabilities

- `character-entity`: Standard isometric input remap and movement-vector-to-facing helper for all movable character bodies (including `PlayerEntity` wiring).

## Impact

- **Shipped addon** (`addons/godot-pixel-core/entity/`): `character_entity.gd` (+helpers), thin edits to `player_entity.gd`.
- **Test harness** (`test/`): manual play in `test/test_scene.tscn` to confirm diagonal slide angle.
- **OpenSpec only**: delta spec for `character-entity`.
- **Not affected:** presenter (`AnimatedEntity`), lookup, lighting, tiles, input map action names.
