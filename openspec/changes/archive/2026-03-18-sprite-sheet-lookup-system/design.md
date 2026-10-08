# Design: Sprite sheet lookup system

## Context

**Current state:** `character.gd` loads one PNG per frame from a directory (`res://sprite/<name>/`), builds cache keys from `state_direction_frame` (e.g. `idle_SE_01`), and applies a full texture to a Sprite2D. Frame count is hardcoded. There is no normal map support and no shared convention for sheet layout.

**Target state:** Sprite sheets are generated with fixed layouts. We need a single system that (1) understands animated layout (one sheet per action, 8-direction rows, frame columns, diffuse + normal block) and (2) static grid layout (uniform grid of cells, lookup by index or row/column). All cells in a sheet share one resolution; animated entities use one resolution for all frames and directions.

**Constraints:** Godot 4.x; addon lives under `addons/godot-pixel-core`; no switching cell resolution within a sheet or within an animated entity.

## Goals / Non-Goals

**Goals:**

- Define and implement a lookup layer that resolves (action, direction, frame) for animated sprites and (sheet, index) or (sheet, row, col) for static sprites to a texture or region usable by Sprite2D (and optionally normal).
- Derive cell size and block boundaries from sheet dimensions and layout type so the pipeline can produce sheets without extra metadata files if desired.
- Integrate with character (or shared sprite driver) so `update_sprite()` and frame count come from the lookup system.
- Support diffuse and normal in the animated case via the same layout convention.

**Non-Goals:**

- Implementing the asset pipeline that generates the sheets (only consuming the agreed layout).
- Supporting mixed resolutions within one sheet or one animated entity.
- General-purpose texture atlases with arbitrary rects; we only support the two defined layouts.

## Decisions

**1. Region delivery: AtlasTexture vs full ImageTexture + Rect2**

- **Choice:** Use Godot’s `AtlasTexture` (or equivalent sub-resource) so callers receive a texture that already has the correct region. Alternative: return a full texture + `Rect2` and have callers set region on a Sprite2D.
- **Rationale:** `AtlasTexture` keeps region logic in one place and matches Godot’s built-in atlas workflow; callers just assign a texture. Returning raw texture + rect pushes region handling to every caller.

**2. Where layout parameters live (cell size, frame count, block split)**

- **Choice:** Support both (a) derivation from image dimensions + layout type (e.g. 8 rows × N cols → cell size = width/N, height/8 for one block; two blocks → half height per block), and (b) optional metadata (e.g. resource or small config) to override frame count or block layout when derivation isn’t enough.
- **Rationale:** Keeps the common case zero-config (pipeline just exports correct dimensions); allows override for odd layouts or when frame count isn’t inferrable from pixels alone.

**3. Direction ordering and indexing**

- **Choice:** Row index 0 = N; order is clockwise: N (0), NE (1), E (2), SE (3), S (4), SW (5), W (6), NW (7). Direction names are "N", "NE", "E", "SE", "S", "SW", "W", "NW". Document in layout spec so pipeline and code agree.
- **Rationale:** Single canonical order; name-to-index mapping lives in one place; clockwise matches common compass/isometric convention.

**4. Static grid: index vs (row, col)**

- **Choice:** Support both linear index and (row, column). Index = row * columns + col (row-major). Document column count source (derived from image size and cell size, or from metadata).
- **Rationale:** Tiles and placement code often think in (row, col); linear index is convenient for random access or list-based data.

**5. Caching and resource lifetime**

- **Choice:** Load sheet textures (or atlases) once per sheet/action and cache them; produce AtlasTextures (or region views) on demand from the cached sheet. Cache keyed by sheet path or (entity, action) for animated.
- **Rationale:** Avoids reopening the same image per frame; region resolution is cheap once the parent texture is loaded.

**6. Asset paths: separate directories for animated vs static**

- **Choice:** Use separate root directories for animated and static sheets (e.g. animated under `res://sprite/animated/<entity>/` or similar, static under `res://sprite/static/` or `res://tiles/`). Exact names can match addon/project convention; the important part is that animated and static do not share the same tree.
- **Rationale:** Clear separation by usage; different discovery and loading rules per type; avoids mixing layout conventions in one folder.

**7. Base class and subclasses for sprite objects**

- **Choice:** Introduce a base class that owns the lookup logic (loading sheets, resolving regions, caching). Subclasses (or Godot inheritance) represent animated vs static sprite behaviour: one subclass for animated (action, direction, frame; diffuse/normal), one for static (sheet, index or row/col). Scene nodes or resources that drive a Sprite2D use the appropriate subclass so character code uses the animated subclass and tile/placement code uses the static one.
- **Rationale:** Shared lookup and cache in the base; each variant exposes only the API that fits its layout (animated vs grid). Keeps call sites clean and lets us add layout-specific behaviour (e.g. frame count, direction mapping) in one place per type.

## Risks / Trade-offs

- **Risk:** Sheet dimensions not divisible by cell count → wrong cell size if we derive purely from dimensions.  
**Mitigation:** Document required divisibility in layout spec; optional metadata to supply exact frame count and cell size when needed.
- **Risk:** Many sheets or large textures → memory.  
**Mitigation:** Cache by path/usage; consider loading animated sheets per entity on first use and unloading when no longer needed if we add scope later.
- **Trade-off:** Deriving everything from dimensions keeps the pipeline simple but may be fragile for edge cases (e.g. padding). Metadata adds a small dependency (resource or config) for those cases.

## Migration Plan

1. Implement layout spec and lookup API (animated + static) under the addon; no change to character yet.
2. Add or document asset paths: separate directories for animated (e.g. `res://sprite/animated/<entity>/`) and static (e.g. `res://sprite/static/` or `res://tiles/`).
3. Replace character’s preload/cache and `update_sprite()` with calls to the lookup system; obtain frame count from lookup/sheet instead of hardcoding.
4. Optionally migrate existing per-cell PNGs to one sheet per action in the new layout (or keep both until pipeline is ready); document the cutover.

**Rollback:** Character can be reverted to the current key-based cache and per-cell PNGs if lookup is disabled or paths point to the old structure.

## Open Questions

- *(None; direction order and separate directories are decided above.)*

