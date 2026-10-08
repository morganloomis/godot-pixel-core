## Why

The addon has no runnable test scene that exercises the entity hierarchy and sprite sheet lookup end-to-end. The existing `main.tscn` uses a legacy `Character` script pattern that bypasses the addon's `PlayerEntity` → `CharacterEntity` → `AnimatedEntity` chain. A proper test scene is needed to visually verify the addon works, to serve as a usage example, and to catch regressions during development.

## What Changes

- Add a test scene at `test/test_scene.tscn` that instantiates a `PlayerEntity` driven by arrow-key/gamepad input, displaying the `girl` entity's walk animation via the addon's sprite sheet lookup pipeline.
- Rename `test/art/sprite/girl/girl_walk.png` → `test/art/sprite/girl/walk.png` so the file matches the addon's `{root}/{entity}/{action}.png` path convention.
- Add an idle sprite sheet at `test/art/sprite/girl/idle.png` (same layout: diffuse/normal blocks, 8 directions) so the entity displays a proper idle animation when the player isn't moving.
- Configure the `PlayerEntity`'s `AnimatedEntity` lookup to use `res://test/art/sprite/` as `animated_sheet_root` and `"girl"` as `entity_id`.
- Update `project.godot` to launch the test scene as the main scene.
- Add a simple ground layer (e.g. paver tiles) so the character has visual context.

## Capabilities

### New Capabilities

- `test-scene`: Conventions and structure for test scenes that exercise the addon — asset path configuration, entity wiring, and what a minimal playable test looks like.

### Modified Capabilities

_(none — this change exercises existing addon capabilities without altering their requirements)_

## Impact

- **Test assets**: `test/art/sprite/girl/girl_walk.png` renamed to `walk.png`; `idle.png` added. The `.import` files will regenerate.
- **Project config**: `project.godot` main scene changes from `main.tscn` to `test/test_scene.tscn`.
- **Existing main.tscn**: Left in place but no longer the default launch scene. Can be removed or kept as a legacy reference.
- **Addon code**: No changes to `addons/godot-pixel-core/`.
