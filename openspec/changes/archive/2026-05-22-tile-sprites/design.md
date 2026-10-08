## Context

The addon already models:

- **Animated** sheets via `SpriteSheetLookupBase` + `AnimatedSpriteSheetLookup`: `{animated_root}/{entity}/{action}/{pass}.png`, eight direction rows × frame columns, shared `SpriteSheetPass` filenames (`diffuse`, `normal`, optional passes).
- **Static** sheets via `StaticSpriteSheetLookup`: single `{static_root}/{sheet_id}.png`, uniform grid, caller supplies `cell_size` (and columns for linear index); no per-pass files.

Map tiles need the **pass-file model** of animated sheets (one PNG per pass, aligned grids, optional passes) but the **topological layout** of a simple uniform grid—**no** direction rows and **no** use of `sprite-sheet-facing`. Layout and lookup behavior should stay consistent with existing caching and “missing optional pass” patterns.

## Goals / Non-Goals

**Goals:**

- Add a **third asset family**: tile sets under their own configurable root, one file per pass per set, each file a single uniform cell grid.
- Reuse **`SpriteSheetPass`** and the same **`diffuse` / `normal` / `specular` / `occlusion` filename convention** as animated actions.
- Provide lookup that returns **`AtlasTexture`** regions for `(tile_set_id, row, col [, pass])` or linear index + columns, mirroring `StaticSpriteSheetLookup` ergonomics while loading per-pass paths.
- **Lighting parity:** lit **tile maps** use Godot’s **built-in 2D lights** with a **default addon integration** that is as simple for authors as flipping **`use_2d_normal_lighting`** on characters (one toggle / preset, documented wiring).
- Keep tile resolution **independent** of facing APIs; no direction parameters on the public tile lookup surface.

**Non-Goals:**

- Defining full **autotiling** or **terrain** UX (only textures, lookup, and lit-tile wiring contracts).
- **Per-tile** baking of atlas cells to **`ImageTexture`** for `TileMap` scale (characters may bake for `CanvasTexture` compatibility; tiles SHALL use a **map-scale** approach such as a **dual-atlas fragment path**).
- Changing animated row order or static single-file layout (**not BREAKING** for existing assets).
- Mandating a new metadata file format in this design (optional follow-up if specs require it).

## Decisions

1. **Directory and path pattern**  
   **Choice:** `{tile_sheet_root}/{tile_set_id}/{pass}.png`, where `pass` uses the same filenames as animated sheets.  
   **Rationale:** Matches artist and tooling expectations from character sheets; keeps pass alignment (diffuse vs normal share the same cell grid).  
   **Alternative considered:** Reuse `static_sheet_root` with a naming convention—rejected to preserve the spec rule that animated and static trees stay separate; tiles are neither `{entity}/{action}` nor single-file static.

2. **New root on the base vs only on a subclass**  
   **Choice:** Add `tile_sheet_root` (default **`res://art/tile/`**) to `SpriteSheetLookupBase`, alongside existing roots, and implement path resolution in a dedicated **`TileSpriteSheetLookup`** (or equivalent name) extending the base.  
   **Project convention:** Same **art/** layout as sprites: game content uses **`res://art/sprite/`** (animated tree under that root per project wiring) and **`res://art/tile/{tile_set_id}/`** for tiles—not `res://sprite/...`. Tests and demos MAY override to e.g. **`res://test/art/tile/`** (matching existing `test/art/sprite/` usage).  
   **Rationale:** Same pattern as `static_sheet_root` / `animated_sheet_root`; one place for caches if subclasses share an instance, or document separate instances if used that way.

3. **Grid math**  
   **Choice:** Reuse **`compute_rect_static(cell_size, row, col)`** for all passes. Each pass image **must** use the same cell width, height, and grid dimensions as `diffuse.png` for that tile set (specs will nail down validation and mismatch behavior; implementation can mirror `_warn_pass_size_mismatch` from animated lookup where helpful).

4. **Who provides `cell_size` (and columns for linear index)**  
   **Choice:** Match **static** lookup: caller passes **`cell_size`**; **columns** for linear indexing can be derived as `floor(sheet_width / cell_size.x)` from **diffuse** when needed, or passed explicitly—prefer **deriving columns from loaded diffuse** when diffuse exists so callers need not duplicate column counts unless specs require both.  
   **Rationale:** Avoids inventing a new metadata pipeline in the first iteration; tile size is game-defined.  
   **Alternative:** JSON next to PNGs—deferred unless Open Questions close in favor of it.

5. **Required diffuse**  
   **Choice:** Treat **`diffuse.png`** as required to define a usable grid for a tile set; missing diffuse ⇒ empty atlas / zero columns, consistent with animated “no diffuse, no frames.”

6. **Optional passes**  
   **Choice:** Same semantics as animated: if `normal.png` (etc.) is absent, lookup returns an empty atlas handle and does not error; lighting presenters reuse existing flat-normal behavior when integrating tile layers later.

7. **Naming**  
   **Choice:** **`tile_set_id`** is a filesystem-safe folder name under `tile_sheet_root` (same practical constraints as `entity` / `sheet_id` today).

8. **Why tiles do not copy the character `CanvasTexture` + bake path**  
   **`AnimatedEntity`** bakes each visible cell to **`ImageTexture`** pairs for **`CanvasTexture`** because atlas-backed textures are unreliable for that lit path on some builds. **`TileMapLayer`** draws **many** tiles per frame; baking per cell would be **prohibitively slow** and memory-heavy.  
   **Choice:** Treat **lit tiles** as a **`TileMapLayer`** (or documented subclass/wrapper) that uses **`CanvasItemMaterial`** / **shader** so each fragment samples **diffuse** (from the tile atlas as Godot draws it) and **normals** from a **second full atlas texture** whose **pixel dimensions and grid** match **`diffuse.png`** for that tile set. **Same UV / atlas mapping** for both textures ⇒ correct normal per painted tile without per-tile texture objects.

9. **Authoring: `TileSet` + sibling `normal.png`**  
   **Choice:** Authors point **`TileSetAtlasSource`** at **`diffuse.png`** (or a copy) for painting. The addon’s lit preset loads **`normal.png`** from the **same tile-set folder** (or an explicit export override) and assigns it to the **normal atlas** uniform on the layer material. **`texture_region_size`** in the `TileSet` MUST match the **cell size** implied by the sheet layout (same as today for static grids).

10. **Ease-of-use parity with characters**  
   **Choice:** Expose a **single boolean or preset** (e.g. `use_2d_normal_lighting` on a thin **`LitTileMapLayer`** script, or documented “apply lit tile material” helper) that: sets **light-receiving** material mode, **nearest** filtering policy consistent with pixel art, binds **normal** from convention or export, and applies a **documented default shader** shipped with the addon. **Missing `normal.png`** ⇒ shader uses the same **flat normal** idea as `sprite-engine-2d-lighting` for characters.

## Risks / Trade-offs

- **[Risk]** Callers pass wrong `cell_size` → wrong regions or apparent “stretched” tiles.  
  **→ Mitigation:** Document clearly; optional future validation comparing `diffuse` dimensions to integer multiple of `cell_size`.

- **[Risk]** Duplication between static and tile lookup APIs.  
  **→ Mitigation:** Shared `compute_rect_static` and shared pass path naming; thin tile-specific class.

- **[Risk]** Three separate roots increase configuration drift.  
  **→ Mitigation:** Defaults in base class; project can centralize assignment in one bootstrap.

- **[Risk]** Diffuse texture in `TileSet` is not byte-identical to `diffuse.png` on disk (reimport, different file) while **`normal.png`** follows the folder layout → **grid mismatch** in the shader.  
  **→ Mitigation:** Document that **lit** tile sets must use **matching** diffuse and normal atlases (same pixel size); recommend pointing the atlas source at the canonical **`diffuse.png`** resource.

- **[Risk]** Godot **tile shader** UVs or internal atlasing change between engine versions.  
  **→ Mitigation:** Keep the **default lit shader** inside the addon with version-pinned behavior documented in release notes.

## Migration Plan

1. Add `tile_sheet_root` and `TileSpriteSheetLookup` (or equivalent) implementation.  
2. Create tile set folders under the new root; migrate or copy assets into `{set}/diffuse.png`, `{set}/normal.png`, …  
3. Point **`TileSet`** atlas sources at **`diffuse.png`**; enable the **addon lit tile preset** on **`TileMapLayer`** where lighting is desired.  
4. Integrate consumers (e.g. procedural placement) via lookup when not using `TileMap`.  
5. **Rollback:** Remove tile root usage; remove lit material from layers; no change required for existing animated/static paths.

## Open Questions

- Should **column count** be required from the caller always, or **only** derived from diffuse dimensions ÷ `cell_size` (and what if not evenly divisible)?  
- Do we need **optional metadata** (cell size, columns) colocated with the tile set for editor tooling, or is caller-supplied `cell_size` enough for v1?
