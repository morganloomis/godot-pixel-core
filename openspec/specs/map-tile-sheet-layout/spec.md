# map-tile-sheet-layout

On-disk conventions for **map tile atlases**: per-pass PNGs under a dedicated `tile_sheet_root`, uniform grids, alignment with diffuse for lighting helpers. Distinct from animated (`{entity}/{action}/`) and static (`{id}.png`) families.

## Requirements

### Requirement: Tile set directory and pass files

Tile set assets SHALL live under a configured **`tile_sheet_root`**. Each tile set SHALL be identified by a **`tile_set_id`** (directory name). For each set, optional pass files SHALL use the **same base filenames** as animated sprite actions: `diffuse.png`, `normal.png`, `specular.png`, `occlusion.png`. **`diffuse.png`** SHALL be **required** for that set to be considered layout-valid for lookup and for the default lit-tile integration. Omitted optional passes SHALL NOT be treated as load errors.

#### Scenario: Resolve path for a tile pass

- **WHEN** the system needs pass file P for tile set T
- **THEN** the path SHALL be `{tile_sheet_root}/T/P.png` with P one of `diffuse`, `normal`, `specular`, `occlusion` (matching animated naming) and SHALL NOT use the animated `{entity}/{action}/` tree or the static single-file static root pattern

---

### Requirement: Uniform grid without facing rows

Each present pass file for a tile set SHALL be a **single** rectangular grid of **equal-sized** cells (same width and height for every cell in that file). Tile layout SHALL **not** define direction rows; addressing SHALL be by **row/column** or **linear row-major index** only. **`sprite-sheet-facing`** SHALL NOT apply to tile sheets.

#### Scenario: Grid dimensions are derivable

- **WHEN** `diffuse.png` for tile set T has pixel size (W, H) and cell size (Cw, Ch) is known
- **THEN** columns = W/Cw and rows = H/Ch SHALL be well-defined integers for a valid layout (exact divisibility rules MAY be specified in implementation or follow-up deltas)

---

### Requirement: Pass alignment for lighting

When **`normal.png`** exists for a tile set, it SHALL have the **same pixel width and height** as **`diffuse.png`** for that set, and the **same** cell grid (same cell size and implied rows/columns). This alignment SHALL be sufficient for the **default lit `TileMapLayer` path** to sample matching diffuse and normal texels for each painted tile.

#### Scenario: Normal atlas matches diffuse atlas size

- **WHEN** both `diffuse.png` and `normal.png` exist for tile set T
- **THEN** both images SHALL have identical dimensions **AND** the same uniform cell grid so each tile index maps to the same logical cell in both passes

---

### Requirement: Separation from animated and static trees

The **`tile_sheet_root`** tree SHALL be **distinct** from the configured **animated** sheet root and **static** sheet root. Layout rules for animated (8 direction rows) and static (single file per id) SHALL remain unchanged for those families.

#### Scenario: Tile paths do not collide with animated layout

- **WHEN** a consumer resolves a tile set pass
- **THEN** the resolved path SHALL not be required to sit under `{animated_root}/{entity}/{action}/` nor as `{static_root}/{id}.png`

---

### Requirement: Default tile root mirrors sprite art layout

The addon SHALL use a documented **default** `tile_sheet_root` of **`res://art/tile/`**, so tile sets live beside sprite art under the same **`art/`** tree (e.g. sprites under `res://art/sprite/` in project conventions, tiles under `res://art/tile/`). Consumers MAY override the root (including **`res://test/art/tile/`** for tests). The default SHALL NOT be `res://sprite/tiles/` or other paths that break **art/sprite** ↔ **art/tile** symmetry for this project.

#### Scenario: Default resolution for tile set `paver`

- **WHEN** `tile_sheet_root` is unset or left at the addon default and tile set id is `paver`
- **THEN** `diffuse.png` SHALL resolve to `res://art/tile/paver/diffuse.png` (unless overridden)
