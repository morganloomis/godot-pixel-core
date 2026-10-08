# Spec Delta: sprite-engine-2d-lighting

## ADDED Requirements

### Requirement: Lit tile maps use engine 2D lighting

The addon SHALL document and support a **default lit path for tile maps** where **`TileMapLayer`** (or a documented thin wrapper node) participates in Godot’s **built-in 2D lighting** using the same light node types as lit sprites (`DirectionalLight2D`, `PointLight2D`, `SpotLight2D`, `CanvasModulate`, as applicable). The default path SHALL **not** require authors to write custom shader code for the common case.

#### Scenario: Authors enable lit tiles like lit characters

- **WHEN** a consumer follows addon documentation for lit tiles
- **THEN** they SHALL enable lighting via a **single documented toggle or preset** (analogous in intent to **`use_2d_normal_lighting`** on `AnimatedEntity`) **AND** add the same class of 2D light nodes used for lit characters

---

### Requirement: Dual-atlas normal sampling for tiles

For the default lit tile path, **diffuse** SHALL come from the **`TileSet`** / **`TileMapLayer`** drawing pipeline (atlas source texture(s) used for painting). **Normals** SHALL come from a **second full atlas texture** whose **pixel dimensions and cell grid** match the tile set’s **`diffuse.png`** for that layer’s source (per `map-tile-sheet-layout`). The implementation SHALL sample **diffuse and normal with consistent mapping** so each painted tile uses the correct normal texels. The implementation SHALL **not** rely on **per-tile** baking of atlas regions to **`ImageTexture`** for this default path (map-scale performance).

#### Scenario: Normal aligns with diffuse for each tile

- **WHEN** a tile is painted from the diffuse atlas and `normal.png` exists with matching layout
- **THEN** rendered lit tiles SHALL show normal-driven lighting consistent with the corresponding cell in `normal.png`

#### Scenario: Missing normal file

- **WHEN** `normal.png` is absent for the tile set backing the layer
- **THEN** the lit tile path SHALL still run **AND** SHALL use a **flat** (or project-documented) normal so 2D lighting receives valid inputs, consistent in spirit with lit sprites without a normal pass

---

### Requirement: Material receives 2D lights

When lit tiles are enabled, the **`TileMapLayer`** (or wrapper) SHALL use a **`CanvasItemMaterial`** (or equivalent) configured so the layer **receives** 2D lighting (not an unshaded replacement for the full lighting model). **`texture_filter`** policy SHALL match pixel-art expectations (e.g. **nearest**) unless another spec overrides it.

#### Scenario: Lit tile layer is not unshaded engine bypass

- **WHEN** lit tiles are enabled
- **THEN** the drawable SHALL participate in Godot’s 2D light rendering pipeline as documented for the project’s renderer
