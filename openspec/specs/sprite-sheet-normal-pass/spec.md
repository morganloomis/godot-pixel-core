# Spec: Sprite sheet normal pass (animated / static)

## Purpose

Define how sprite sheets store and resolve **paired diffuse and normal** regions for the same logical cell (entity, action, direction, frame), for both animated and optional static layouts.

## Requirements

### Requirement: Animated sheet stores diffuse and normal blocks

Animated **normal** data SHALL be stored in an optional **`normal.png`** file alongside **`diffuse.png`** under `{animated_root}/{entity}/{action}/`. Optional **`height.png`**, **`specular.png`**, **`emissive.png`** and **`occlusion.png`** SHALL use the same folder and the same grid. **`height.png`** SHALL encode height above the ground plane in its **R** channel at **one step per pixel**; **`emissive.png`** SHALL encode the literal on-screen colour, so black means "not emissive". Both files SHALL use the **same** 8-row × N-column grid per `sprite-sheet-facing`. There SHALL NOT be a stacked vertical diffuse/normal block inside a single PNG for the default animated layout.

#### Scenario: Separate files for diffuse and normal

- **WHEN** both `diffuse.png` and `normal.png` exist for an action
- **THEN** each file’s height corresponds to eight direction rows and its width corresponds to N frame columns, and row/column indices refer to the same logical pose across files

#### Scenario: Diffuse without normal file

- **WHEN** only `diffuse.png` exists for an action
- **THEN** lookup does not load a normal texture from disk for that action; lit rendering uses documented fallback normal behavior

---

### Requirement: Lookup resolves matching diffuse and normal regions

The addon’s animated sprite sheet lookup SHALL resolve diffuse and normal `AtlasTexture` (or equivalent) regions for the same logical cell: same `entity`, `action`, direction index, and frame index. Diffuse SHALL come from `diffuse.png`; normal SHALL come from `normal.png` when present. When both exist, they MAY reference different underlying texture resources while sharing the same grid indices.

#### Scenario: Same indices yield paired regions when normal exists

- **WHEN** lookup is called for a given entity, action, direction, and frame for diffuse and again for normal, and `normal.png` exists
- **THEN** both results target the same frame column and direction row within their respective pass files

#### Scenario: Normal absent

- **WHEN** `normal.png` is absent
- **THEN** normal lookup yields no texture from file; presenter or lit path applies documented fallback

---

### Requirement: Lit sprite path keeps normal in sync with diffuse

Any addon-provided code path that applies lighting to an animated entity using sheet normals SHALL refresh the bound normal data whenever it refreshes the diffuse for that entity, using the same `entity`, `action`, direction, and `frame` indices in the same update (e.g. the same `update_sprite` or equivalent call chain). When no normal file exists, the path SHALL still refresh diffuse and apply the documented fallback normal.

#### Scenario: Frame advance updates diffuse and normal binding

- **WHEN** an animated lit sprite advances to the next frame or changes action or facing
- **THEN** the renderer receives an updated diffuse sample and a normal sample that matches that pose (from `normal.png` or fallback)

---

### Requirement: Static sheets (optional same layout)

If the addon supports static sprite sheets with paired diffuse/normal **files**, the static lookup documentation SHALL state how pairing works or that static lit sprites use a different convention. Until implemented, the addon documentation SHALL state which static layouts are supported.

#### Scenario: Documented static behavior

- **WHEN** a consumer uses static sheet lookup for lit rendering
- **THEN** the documented API SHALL state whether per-pass static files apply or static lit sprites are unsupported until implemented
