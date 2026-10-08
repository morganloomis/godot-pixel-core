# Proposal: Sprite sheet lookup system

## Why

Sprite sheets are generated with a pre-arranged layout. We need a single, consistent way to look up the correct texture region from those sheets. Two cases: (1) **Animated** — one sheet per action, rows = 8 directions, columns = frames, with diffuse then normal block; characters look up by (action, direction, frame). (2) **Non-animated** — a sheet is a grid of distinct sprites (e.g. floor tiles) with lookup by grid position or index. Right now `character.gd` assumes one PNG per cell and a naming convention; moving to atlas-style sheets (and supporting static grids) requires a shared lookup system. Sprites can be different resolutions across the project, but **each sprite sheet must use a single cell/sprite resolution** (all cells same size), and **each animated entity must use one resolution for all frames and all directions** so we never switch resolution mid-sheet or mid-entity.

## What Changes

- **Sprite sheet layout convention**: Define and document two layouts. (1) **Animated**: one sheet per action; rows = 8 directions; columns = frames; first block = diffuse, second = normal; frame size and block boundaries deterministic from sheet dimensions and frame count. (2) **Static grid**: one sheet = a grid of distinct sprites (e.g. floor tiles); lookup by grid index or (row, column). In both cases, **all cells in a given sheet share the same resolution** (cell width/height uniform per sheet). For animated entities, all frames and all directions use that single resolution (no switching).
- **Lookup API**: (1) Animated: resolve (action, direction, frame) and optional type (diffuse/normal) to a texture or atlas region. (2) Static: resolve (sheet, index) or (sheet, row, column) to a texture or region. Callers use this instead of building file names or loading many small PNGs.
- **Character integration**: Update character (or a shared sprite driver) to use the lookup system for `update_sprite()` and animation (frame count per action comes from the sheet/lookup, not hardcoded).
- **Asset path and format**: Clarify where sheets live (e.g. animated under `res://sprite/<entity>/`, static elsewhere) and that the pipeline produces sheets in the agreed layouts; the lookup system is the single consumer of those layouts.

## Capabilities

### New Capabilities

- `sprite-sheet-layout`: The convention for animated sheets (one per action, 8-direction rows, frame columns, diffuse then normal block) and for static grids (uniform grid of distinct sprites); how frame/cell size and block bounds are derived; rule that all cells in a sheet share one resolution and animated entities do not switch resolution.
- `sprite-sheet-lookup`: The mechanism and API for animated lookup (action, direction, frame, optional diffuse/normal) and for static lookup (sheet, index or row/column) to a texture or region for rendering.

### Modified Capabilities

- *(none)*

## Impact

- **character.gd / entity sprites**: Replace per-cell PNG loading and key-based cache with the lookup system; animation frame counts come from the lookup or sheet metadata instead of hardcoded values.
- **Static/tile usage**: Any system that places floor tiles or other grid sprites uses the same lookup for (sheet, index) or (row, col) instead of ad-hoc loading.
- **Asset pipeline**: Sprite sheet generation must output the agreed layouts (animated and static grid) with uniform cell size per sheet; the lookup system interprets them.
- **Paths and resources**: Sheets are loaded or referenced by action/entity (animated) or by sheet id (static); the lookup layer hides layout details from game code.

