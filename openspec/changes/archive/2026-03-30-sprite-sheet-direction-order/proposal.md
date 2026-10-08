## Why

Animated sprite sheets and gameplay code must agree on which row corresponds to which compass direction. The project standard is a fixed top-to-bottom row order starting at south and stepping counter-clockwise; the addon currently maps rows with a different convention, so art and facing labels can disagree.

## What Changes

- Align `SpriteSheetLookupBase` direction names and row indices with sheet rows **S, SE, E, NE, N, NW, W, SW** (top → bottom).
- Align `PlayerEntity` (and any other code) that converts movement vectors to direction names so the same strings select the correct row.
- Document the convention as the single source of truth for animated sheet layout.
- **No sprite sheet edits**: Existing PNGs (including under `test/`) stay as-is; code is adjusted to match the project’s row order.

## Capabilities

### New Capabilities

- `sprite-sheet-facing`: Defines the canonical mapping between eight compass direction labels and animated sprite sheet row index (top to bottom).

### Modified Capabilities

- (none)

## Impact

- `addons/godot-pixel-core/sprite_sheet/sprite_sheet_lookup_base.gd` — `DIRECTIONS` constant and any comments describing row order.
- `addons/godot-pixel-core/entity/player_entity.gd` — `_vector_to_direction` and its `DIRECTIONS` / angle segmentation must match the lookup order.
- `addons/godot-pixel-core/sprite_sheet/animated_sprite_sheet_lookup.gd` — comments that reference the old 8-row convention if any.
- No changes to sprite sheet image files.
