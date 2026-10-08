# Spec: addon-structure

## Purpose

Define where addon code lives, how consumers install it, and how in-repo `test/` content relates to the distributed `addons/godot-pixel-core/` folder.

## Requirements

### Requirement: Addon root location

All addon content SHALL live at `addons/godot-pixel-core/` within this repository. All exportable scripts, scenes, and resources MUST be under that folder. Nothing outside `addons/godot-pixel-core/` is part of the distributed addon.

#### Scenario: Addon content is under correct path

- **WHEN** the repository is inspected for addon content
- **THEN** all addon scripts, scenes, and resources exist under `addons/godot-pixel-core/` or a subpath thereof

#### Scenario: No addon content outside addon folder

- **WHEN** the repository is inspected for addon distribution
- **THEN** no scripts, scenes, or resources that belong to the addon exist at `addons/entity/`, `addons/sprite_sheet/`, or any path outside `addons/godot-pixel-core/`

---

### Requirement: Path consistency

All `res://` paths in addon `.tscn` and `.gd` files MUST use the `res://addons/godot-pixel-core/` prefix. This ensures paths are identical in the development project and in consumer projects.

#### Scenario: Scene references use addon prefix

- **WHEN** an addon `.tscn` file references another addon resource via `ext_resource`
- **THEN** the path starts with `res://addons/godot-pixel-core/`

#### Scenario: Script references use addon prefix

- **WHEN** an addon `.gd` file uses `preload()` or `load()` to reference another addon resource
- **THEN** the path starts with `res://addons/godot-pixel-core/`

---

### Requirement: Submodule consumption

The addon MUST be consumable by other projects via git submodule. Consumers submodule this repo into a staging location and symlink or copy `addons/godot-pixel-core/` into their project's `addons/` folder. The repo MUST document this pattern.

#### Scenario: Consumer adds addon via submodule and symlink

- **WHEN** a consumer submodules this repo into a staging path (e.g. `.addons-src/godot-pixel-core`) and symlinks `addons/godot-pixel-core/` into their own `addons/`
- **THEN** the consumer project can use all addon classes and scenes at `res://addons/godot-pixel-core/...`

#### Scenario: Consumer adds addon via folder copy

- **WHEN** a consumer copies `addons/godot-pixel-core/` from this repo into their project's `addons/`
- **THEN** the consumer project can use all addon classes and scenes at `res://addons/godot-pixel-core/...`

---

### Requirement: Test layout

The repository SHALL provide a `test/` directory for in-repo testing. This directory holds scenes, assets, and minimal game content used only to exercise addon behavior. Content in `test/` MUST NOT be shipped with the addon.

#### Scenario: Test content is isolated from addon

- **WHEN** a consumer obtains the addon folder (`addons/godot-pixel-core/`)
- **THEN** no files from `test/` are included

#### Scenario: Test content references addon via standard paths

- **WHEN** a test scene or script in `test/` uses addon functionality
- **THEN** it references resources under `res://addons/godot-pixel-core/`

---

### Requirement: No plugin.cfg for script-only addon

The addon MUST NOT include a `plugin.cfg` unless editor tools (extending `EditorPlugin`) are added. Script classes using `class_name` are automatically available without plugin registration.

#### Scenario: Addon works without plugin registration

- **WHEN** a consumer project includes `addons/godot-pixel-core/` with scripts that declare `class_name`
- **THEN** those classes (e.g. `CharacterEntity`, `PlayerEntity`) are available in the editor and at runtime without enabling a plugin

---

### Requirement: Addon self-containment

The addon folder SHALL contain a copy of `LICENSE` and `README.md` so consumers who keep only that folder have license and usage information.

#### Scenario: License is available in addon folder

- **WHEN** a consumer has only the `addons/godot-pixel-core/` folder
- **THEN** `addons/godot-pixel-core/LICENSE` exists with full license text

#### Scenario: Readme is available in addon folder

- **WHEN** a consumer has only the `addons/godot-pixel-core/` folder
- **THEN** `addons/godot-pixel-core/README.md` exists with addon overview and usage

---

### Requirement: README documents animated pass layout

`addons/godot-pixel-core/README.md` SHALL describe the animated sprite directory layout: `{animated_root}/{entity}/{action}/` with optional pass files `diffuse.png` (required for an action), `normal.png`, `height.png`, `specular.png`, `emissive.png`, and `occlusion.png`; SHALL state the **world-space** normal encoding and the **one step per pixel** height encoding; SHALL reference engine-lit behaviour (shared `ShaderMaterial`, documented fallbacks when a pass is absent); SHALL document the project-wide global shader parameters and the light placement convention; and SHALL state the import settings that data passes require. The README SHALL NOT describe deprecated layouts (e.g. a single-PNG action sheet with a top diffuse block and a bottom normal block) or removed files (e.g. `LitAnimatedEntity`, `player_entity_lit.tscn`, `entity/characters/character.gd`, the duplicate `shaders/` shader bundle, or the top-level `lighting/sprite_lighting.gd`) as part of the current API.

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

---

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

---

### Requirement: ext_resource UIDs match referenced resources

Every `ext_resource` declaration in addon and in-repo test `.tscn` files SHALL specify a `uid://...` value that exactly matches the current UID of the referenced resource (the `uid://` written at the top of the target `.tscn` file, or the contents of the target's `.gd.uid` / `.gdshader.uid` sidecar). When an `ext_resource` references a resource whose UID has since changed, the referencing scene SHALL be updated so Godot does not emit a "UID does not match resource_path" warning on load.

#### Scenario: Addon scene references current UIDs

- **WHEN** any `.tscn` in `addons/godot-pixel-core/` is loaded in Godot 4.6
- **THEN** every `ext_resource uid="..."` in that scene SHALL resolve to the same file as its `path="..."` without a UID-mismatch warning

#### Scenario: Test scene references current UIDs

- **WHEN** any `.tscn` in `test/` is loaded in Godot 4.6
- **THEN** every `ext_resource uid="..."` in that scene SHALL resolve to the same file as its `path="..."` without a UID-mismatch warning

#### Scenario: Resource UID changes flow to references

- **WHEN** the canonical UID of a referenced resource (e.g. `addons/godot-pixel-core/entity/animated_entity.tscn`) changes
- **THEN** every `.tscn` in this repository that references that resource SHALL be updated in the same change so its `ext_resource` UID stays in sync; relying on Godot's path-based fallback SHALL NOT be considered an acceptable steady state
