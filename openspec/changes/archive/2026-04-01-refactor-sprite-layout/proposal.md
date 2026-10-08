## Why

Animated art is currently authored as one PNG per action with stacked diffuse and normal blocks. That forces every lit action to reserve sheet height for normals even when unused, and it couples all passes in one file. Splitting passes into optional files under `…/<entity>/<action>/` makes “this action has no normal (or no occlusion)” explicit at the filesystem level and matches common tooling and version-control workflows.

## What Changes

- **BREAKING**: Replace the per-action single file (`<root>/<entity>/<action>.png` with stacked blocks) with a **directory per action** containing **optional** pass files: `diffuse.png`, `normal.png`, `specular.png`, `occlusion.png` (exact names TBD in design; user requested these four).
- **BREAKING**: Default animated art path tree becomes `{animated_root}/{entity}/{action}/{pass}.png` (e.g. under `res://…/sprite/…` as configured).
- Frame count and cell geometry SHALL be derived from **diffuse** when present; design SHALL define behavior when only non-diffuse maps exist (if allowed).
- Lookup and presenter code SHALL load only passes that exist; missing maps SHALL NOT be required. **Engine 2D lit path** continues to use diffuse + normal where Godot’s `CanvasTexture` supports them; **specular** and **occlusion** SHALL be specified for loading and future/custom shading (not necessarily wired to stock `CanvasTexture` in v1 of this change).
- Test harness art paths and addon README SHALL be updated to the new layout.

## Capabilities

### New Capabilities

- _(none — behavior is covered by modifying existing specs)_

### Modified Capabilities

- `sprite-sheet-layout`: Replace stacked-block convention with per-pass files under `{entity}/{action}/`; document optional passes and naming.
- `sprite-sheet-lookup`: Path resolution per pass; frame count from diffuse; optional presence of each pass; API adjustments as needed (e.g. pass enum or string vs integer `type`).
- `sprite-sheet-normal-pass`: Rephrase from “single image two blocks” to “separate files, paired by grid indices when present.”
- `sprite-presentation`: Update documented path example and `entity_name` / action resolution to the new tree.
- `sprite-engine-2d-lighting`: Clarify diffuse/normal may come from **different source textures** (same cell layout); optional normal → flat/default normal behavior.
- `test-scene`: Test asset paths and any setup scripts reference the new layout.
- `addon-structure`: README / layout docs for consumers match the new conventions.

## Impact

- **Addon**: `AnimatedSpriteSheetLookup`, `SpriteSheetLookupBase` (region math for animated sheets without vertical stacking), `AnimatedEntity` / lit cell baking, cached texture keys (per pass path).
- **Tests**: `test/` art folder structure and `test_scene.gd` (and any static lit demos) updated.
- **Consumers**: Any game using old `walk.png`-style sheets must split into `walk/diffuse.png` (and optional `walk/normal.png`, etc.).
