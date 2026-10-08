# Spec: addon-structure

## ADDED Requirements

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
