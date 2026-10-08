## Why

Map tiles should use the same **multi-pass texture model** as character sprites (diffuse, normal, optional passes) so lighting and shading stay consistent, but tiles are **pure grid atlases**: many cells of one tile size per sheet, **no** eight-direction rows. Today specs center on **animated** (8 rows × frames) and **static** grids; we need an explicit contract for **tile sets** so layout, paths, and lookup stay coherent.

## What Changes

- Introduce **tile-set** asset conventions: configurable root, one **PNG per pass** per tile set (same pass names and optionality as animated sheets where applicable), each file a **single uniform grid** of same-sized cells (row-major indexing).
- Define **lookup** for tiles: resolve `(tile_set, linear index or row/column, pass)` to atlas regions, with caching and “missing pass” behavior aligned with existing pass semantics.
- **Lit tiles:** support **Godot 2D lighting** on tile maps with **comparable author effort** to `AnimatedEntity`’s `use_2d_normal_lighting` (documented default path: **TileMapLayer** + **matching normal atlas**, not per-cell `CanvasTexture` baking).
- **Do not** apply `sprite-sheet-facing` or any view-direction dimension to tile sheets; callers use **grid indices only**.
- WireImpact: addon/resource code that loads sheets, **lit tile map** wiring (material/shader or thin wrapper), and any editor or scene glue that references tile textures.

## Capabilities

### New Capabilities

- `map-tile-sheet-layout`: Directory and file naming for tile sets; per-pass files; uniform cell size; column/row derivation from image dimensions; relationship to animated pass naming (`diffuse`, `normal`, etc.) without direction rows.
- `map-tile-sheet-lookup`: APIs (and base/subclass or shared resolver pattern) to load/cache per-pass tile textures and return `AtlasTexture` (or equivalent) regions for a given cell and pass; optional passes behave like animated optional passes.

### Modified Capabilities

- `sprite-engine-2d-lighting`: Extend the default engine-lit story to cover **tile maps** (diffuse from `TileSet` drawing path + aligned **normal atlas** / flat normal fallback), with a **single documented preset or toggle** for the default integration so authors are not required to hand-author shaders for the common case.

## Impact

- **Specs:** New delta specs for `map-tile-sheet-layout` and `map-tile-sheet-lookup`; delta for `sprite-engine-2d-lighting` for lit tiles; possible follow-on delta for `sprite-sheet-lookup` if shared cache/API requirements change.
- **Code:** Godot addon(s) under `addons/` that implement sheet loading and region math; any project settings for asset roots; presenters or tile layers that consume tile atlases.
- **Assets:** New or migrated tile set folders under **`res://art/tile/{tile_set_id}/`** (parallel to **`res://art/sprite/`** for sprites; tests may use `res://test/art/tile/`).
