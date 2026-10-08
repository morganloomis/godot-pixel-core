## 1. Tile sheet root and path resolution

- [x] 1.1 Add `tile_sheet_root` with default **`res://art/tile/`** (symmetric to game art under **`res://art/sprite/`**; tests may set `res://test/art/tile/`) to `SpriteSheetLookupBase` alongside existing roots, without changing animated/static path behavior.
- [x] 1.2 Implement `tile_pass_texture_path(tile_set_id: String, sheet_pass: SpriteSheetPass) -> String` resolving `{tile_sheet_root}/{tile_set_id}/{pass}.png` using the same filenames as `animated_pass_texture_path`.

## 2. TileSpriteSheetLookup

- [x] 2.1 Add `TileSpriteSheetLookup` (or agreed name) extending `SpriteSheetLookupBase` with `get_texture(tile_set_id, row, col, cell_size, sheet_pass) -> AtlasTexture` using `get_cached_texture`, `compute_rect_static`, and `create_atlas_texture`.
- [x] 2.2 Add `get_texture_by_index(tile_set_id, index, columns, cell_size, sheet_pass)` with row-major indexing; derive `columns` from diffuse width and `cell_size.x` when the design’s helper API is defined, or document required caller input if deferred.
- [x] 2.3 Return empty-safe `AtlasTexture` when `diffuse.png` is missing, `cell_size` is invalid for the sheet, or an optional pass file is absent (no errors); optionally log or warn on pass size mismatch vs diffuse like animated lookup.
- [x] 2.4 Expose the class to Godot (`class_name` / script registration) consistent with existing lookup types.

## 3. Lit TileMapLayer default path

- [x] 3.1 Add a **default lit tile shader** under `addons/godot-pixel-core/` that samples diffuse from the tile path and normals from a **second full atlas** uniform with matching UV mapping; use a **flat normal** when the normal atlas is not bound or is stubbed.
- [x] 3.2 Add a **ShaderMaterial** preset (resource or factory) with **nearest** filtering policy aligned with pixel art and `CanvasItemMaterial` / light mode so the layer **receives** 2D lights per `sprite-engine-2d-lighting` delta.
- [x] 3.3 Implement a thin **`TileMapLayer` script or subclass** (or documented helper) with an export such as `use_2d_normal_lighting` that applies the preset, binds `normal.png` from `{tile_sheet_root}/{tile_set_id}/` (or an optional override texture path), and documents how `tile_set_id` is determined from exports or from the atlas source’s `resource_path`.

## 4. Documentation and demo

- [x] 4.1 Document tile folder layout, `TileSet` authoring (`texture_region_size` vs cell size), lit toggle usage, and flat-normal fallback in `addons/godot-pixel-core/README.md` (or the addon’s primary doc file).
- [x] 4.2 Update `test/` or `main.tscn` with an optional example: one tile set under `tile_sheet_root` with `diffuse.png` / `normal.png` and a `TileMapLayer` using the lit preset, so the behavior is manually verifiable.

## 5. Spec sync (post-implementation)

- [x] 5.1 Run `/opsx-verify` (or `openspec verify`) for change `tile-sprites` and fix any gaps between code and delta specs before archive/sync.
