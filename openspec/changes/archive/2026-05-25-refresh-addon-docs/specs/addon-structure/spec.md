# Spec Delta: addon-structure

## MODIFIED Requirements

### Requirement: README documents animated pass layout

`addons/godot-pixel-core/README.md` SHALL describe the animated sprite directory layout: `{animated_root}/{entity}/{action}/` with optional pass files `diffuse.png` (required for an action), `normal.png`, `specular.png`, and `occlusion.png`; SHALL reference optional passes and engine-lit behavior (diffuse + normal in `CanvasTexture`, fallback normal when normal is absent); and SHALL note that `specular`/`occlusion` are loaded when present for forward-compatible use. The README SHALL NOT describe deprecated layouts (e.g. a single-PNG action sheet with a top diffuse block and a bottom normal block) or removed files (e.g. `LitAnimatedEntity`, `player_entity_lit.tscn`, `entity/characters/character.gd`, the duplicate `shaders/` shader bundle, or the top-level `lighting/sprite_lighting.gd`) as part of the current API.

#### Scenario: Consumer reads animated layout from README

- **WHEN** a consumer opens `addons/godot-pixel-core/README.md` to author art
- **THEN** they find the pass filenames, directory nesting, and which passes affect stock engine 2D lighting

#### Scenario: Removed files do not appear as live API

- **WHEN** a contributor searches `addons/godot-pixel-core/README.md` for the names `LitAnimatedEntity`, `player_entity_lit.tscn`, `entity/characters/character.gd`, `shaders/sprite_lit`, or top-level `lighting/sprite_lighting.gd`
- **THEN** any mentions SHALL be in a migration / changelog context (describing past removal), not in current-API instructions or feature lists

---

### Requirement: Asset Library doc is consistent with README

`docs/ASSET_LIBRARY.md` SHALL describe sprite sheet layout in a way that is consistent with `addons/godot-pixel-core/README.md`. In particular, it SHALL describe animated sheets as **per-pass files under `{entity}/{action}/`** and SHALL NOT describe a single combined PNG with a top diffuse block and bottom normal block. Detailed pass behavior MAY be linked or briefly summarized; the README remains the source of truth.

#### Scenario: Asset Library doc points to README pass table

- **WHEN** a contributor reads `docs/ASSET_LIBRARY.md` "Sprite sheets" section
- **THEN** it SHALL describe `{entity}/{action}/{pass}.png` layout (matching `sprite-sheet-layout`) and SHALL either include or link to the README's pass table; it SHALL NOT describe a two-block combined PNG

#### Scenario: No contradiction with README

- **WHEN** the same fact is stated in both `docs/ASSET_LIBRARY.md` and `addons/godot-pixel-core/README.md` (e.g. number of direction rows, default `animated_sheet_root`, optional pass behavior)
- **THEN** the two documents SHALL agree; if they diverge, the README SHALL be treated as authoritative and `docs/ASSET_LIBRARY.md` SHALL be updated to match

## ADDED Requirements

### Requirement: README contains a class inheritance overview

`addons/godot-pixel-core/README.md` SHALL contain a "Class overview" section with a flow chart (Mermaid `graph TD`) that names every `class_name`-registered script in the addon together with its immediate Godot base. The chart SHALL group classes into two subgraphs: **scene-node classes** (those a user instances under a parent in a scene) and **`RefCounted` helper classes** (those constructed in code). The chart SHALL NOT draw composition relationships (e.g. `CharacterEntity` containing an `AnimatedEntity` child); composition MAY be described in prose under the chart. The legacy `addons/godot-pixel-core/lighting/legacy/sprite_lighting.gd` SHALL be named in a callout outside the chart and SHALL NOT appear inside either subgraph. `docs/ASSET_LIBRARY.md` SHALL link to this section rather than duplicating the chart.

#### Scenario: New reader finds the class inheritance overview in the README

- **WHEN** a new reader opens `addons/godot-pixel-core/README.md`
- **THEN** they find a "Class overview" section near the top that names every `class_name` in the addon and shows its Godot base in a single rendered diagram, with scene-node classes and `RefCounted` helpers visually separated

#### Scenario: Chart stays in sync with the addon's class set

- **WHEN** a `class_name`-registered script is added, removed, or its `extends` base changes anywhere under `addons/godot-pixel-core/`
- **THEN** the "Class overview" chart in `addons/godot-pixel-core/README.md` SHALL be updated in the same change so that the chart's nodes match the set of `class_name`s on disk, and an out-of-date chart SHALL be treated as a documentation defect

#### Scenario: Legacy bundle is not part of the canonical tree

- **WHEN** a reader looks for `lighting/legacy/sprite_lighting.gd` in the "Class overview" chart
- **THEN** it SHALL NOT appear as a node inside either subgraph; instead a callout under the chart SHALL name it, note it has no `class_name`, and state that it loads only when a project manually autoloads it
