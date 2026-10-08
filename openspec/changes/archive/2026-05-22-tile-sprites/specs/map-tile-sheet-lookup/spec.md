# Spec Delta: map-tile-sheet-lookup

## ADDED Requirements

### Requirement: Tile sheet lookup class

The addon SHALL provide a **tile sheet lookup** type (subclass of or peer to the existing sheet lookup base, as implemented) that loads pass textures from `{tile_sheet_root}/{tile_set_id}/` using the same pass filenames as animated sheets. It SHALL cache loaded textures **per resource path** so repeated requests for the same pass reuse memory.

#### Scenario: Cache hit on second request

- **WHEN** the same pass file path is requested twice
- **THEN** the second request SHALL reuse the cached texture without reloading from disk

---

### Requirement: Region resolution without direction

Tile lookup SHALL resolve **`(tile_set_id, row, col, sheet_pass)`** (and/or **`(tile_set_id, linear_index, columns, sheet_pass)`** with row-major index) to an **`AtlasTexture`** (or documented equivalent view) for that cell. The API SHALL **not** take a facing or direction argument. If **`diffuse.png`** is missing or **`cell_size`** does not evenly divide the diffuse dimensions, the implementation SHALL return a documented empty / null-safe result without crashing.

#### Scenario: Optional pass missing

- **WHEN** caller requests `specular` or `occlusion` for a tile set where that file is absent
- **THEN** the system SHALL NOT error **AND** SHALL return a documented empty texture handle consistent with animated optional-pass behavior

#### Scenario: Linear index matches row-major grid

- **WHEN** caller requests linear index i with C columns
- **THEN** row = i / C and col = i % C SHALL address the same cell as explicit (row, col)

---

### Requirement: Optional use beside TileMap

Tile lookup SHALL support **non-`TileMap`** consumers (tools, procedural `Sprite2D` placement, tests). **`TileMapLayer`** authoring MAY use **`TileSet`** only; this lookup remains the **programmatic** mirror of the same on-disk passes.

#### Scenario: Lookup usable without TileMap node

- **WHEN** game code requests a tile cell texture without a `TileMapLayer` in the scene
- **THEN** tile lookup SHALL still return atlas regions for the requested indices when assets exist
