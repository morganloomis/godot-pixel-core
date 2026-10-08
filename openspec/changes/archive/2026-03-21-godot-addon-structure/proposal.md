# Proposal: Godot addon structure

## Why

This project is a Godot addon that provides core features for isometric pre-rendered pixel art games. We need a documented, consistent structure so that (1) the deployable addon lives in one clear place with consistent `res://` paths, (2) consumers can add it to their projects via git submodule, and (3) we can test and develop functionality in-repo without importing the addon elsewhere. Defining this structure — including how deployment works — avoids drift and makes onboarding and tooling predictable.

## What Changes

- **Consolidate addon layout**: Move `addons/entity/` and `addons/sprite_sheet/` under `addons/godot-pixel-core/`. All addon content lives in one folder with consistent `res://addons/godot-pixel-core/...` paths that work identically in this dev project and in consumer projects.
- **Document deployment**: Consumers submodule this repo into a staging location and symlink or copy `addons/godot-pixel-core/` into their project. This avoids double-nesting that would occur if the whole repo were submoduled directly at `addons/godot-pixel-core`.
- **Document the test layout**: `test/` holds scenes, assets, and minimal game content used only to exercise addon behavior in this repo (not shipped with the addon).
- **No `plugin.cfg`**: This is a script-only addon using `class_name`. Godot's `plugin.cfg` requires an `EditorPlugin` script, which is unnecessary here. Can be added later if editor tools are introduced.
- **Self-contained addon folder**: Include `LICENSE` and `README.md` in `addons/godot-pixel-core/` so the folder stands alone.

## Capabilities

### New Capabilities

- `addon-structure`: Where the deployable addon lives (`addons/godot-pixel-core/`), how it is consumed (submodule + symlink/copy), path consistency requirements, what belongs in the addon vs the host project, and how the repo is organized for development and testing.

### Modified Capabilities

- *(none)*

## Impact

- **Code and assets**: `addons/entity/` and `addons/sprite_sheet/` move under `addons/godot-pixel-core/`. All `res://` references update to `res://addons/godot-pixel-core/...`. `test/` and root-level Godot files remain for this repo only.
- **Deployment**: Consumers submodule the repo into a staging path, then symlink or copy `addons/godot-pixel-core/` into their project's `addons/`.
- **Docs and tooling**: README and project docs describe the submodule consumption pattern, folder layout, and path conventions.
