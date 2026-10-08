# sprite-engine-2d-lighting

How the addon participates in Godot **built-in 2D lighting** as the default integration path, for **sprites** (`AnimatedEntity`) and **tiles** (`TileMapLayer`) alike, via one shared `canvas_item` shader that reads world-space normals and per-pixel height and keeps the engine's own light nodes.

## Requirements

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
- **THEN** the lit tile path SHALL still run **AND** SHALL use a documented fallback normal so 2D lighting receives valid inputs. For a tile layer that fallback SHALL be **world up**, which is the correct normal for a ground plane

---

### Requirement: Normals are world space and height is per pixel

Normal passes SHALL be authored in **world space** (Z up), unit length, linearly encoded. The lit path SHALL therefore write **`NORMAL`** directly rather than **`NORMAL_MAP`**, because the stock path flips green and reconstructs `z` non-negative, which misreads world-space data and discards back-facing normals.

The rotation from world space into the shading basis SHALL be driven by a **project-wide camera basis** (yaw and elevation) exposed as global shader parameters, so changing the camera angle re-lights existing art instead of invalidating it.

Where a **`height.png`** pass exists, the lit path SHALL report each fragment's **ground position and height** to the engine's light math (e.g. via **`LIGHT_VERTEX`**), so a light's direction is computed in three dimensions rather than on a flat plane.

#### Scenario: Light orbits rather than slides

- **WHEN** a positional light is moved in a circle on the ground plane around a tall lit sprite that has a height pass
- **THEN** the shading terminator SHALL sweep **around** the sprite **AND** SHALL NOT merely translate vertically up and down it

#### Scenario: Camera angle is a runtime change

- **WHEN** the project's camera yaw or elevation global is changed at runtime
- **THEN** existing lit sprites and tiles SHALL re-shade accordingly **AND** SHALL NOT require re-rendering any pass file

---

### Requirement: Material receives 2D lights

When lit tiles are enabled, the **`TileMapLayer`** (or wrapper) SHALL use a material configured so the layer **receives** 2D lighting (not an unshaded replacement for the full lighting model). The addon's default is a **`ShaderMaterial`** that keeps Godot's light nodes, energy, colour, texture and blend modes and overrides only the shading math via **`light()`**. **`texture_filter`** policy SHALL match pixel-art expectations (e.g. **nearest**) unless another spec overrides it.

The same material and shader SHALL serve **both** tile layers and sprite presenters, so lit floors and lit characters cannot drift apart in their interpretation of normals, height or ambient.

#### Scenario: Lit tile layer is not unshaded engine bypass

- **WHEN** lit tiles are enabled
- **THEN** the drawable SHALL participate in Godot’s 2D light rendering pipeline as documented for the project’s renderer
