## Why

The `test-scene` spec and the live `test/test_scene.tscn` configure `entity_name = "girl"` and expect art under `res://test/art/sprite/girl/`, but the only sprite art on disk lives at `test/art/sprite/player/{idle,walk}/{diffuse,normal}.png`. With the current scene, `AnimatedSpriteSheetLookup.get_texture(...)` returns an empty `AtlasTexture` every frame, so the test scene renders no character and the "Engine 2D lighting demonstrator" scenarios in `test-scene` cannot pass.

The on-disk art is the source of truth (project rule: code does not generate or rename images), so the spec and scenes need to track the existing `player/` folder name. The packaged `player_entity.tscn` already bakes `entity_name = "player"` on its `AnimatedEntity` child, so aligning everything on `"player"` removes a small inconsistency too.

## What Changes

- **BREAKING** for any external consumer that depended on the test entity name: rename the documented test entity from `girl` to `player` everywhere in the test-scene spec.
- Update `test/test_scene.tscn` so the `PlayerEntity` root has `entity_name = "player"`.
- Update `test/static_lit_prop.tscn` so the `AnimatedEntity` child has `entity_name = "player"`.
- Sweep stray `girl` references in the codebase (specs, scenes, code, docs) and replace them with `player`.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `test-scene`: every `girl` reference becomes `player`; paths like `res://test/art/sprite/girl/walk/diffuse.png` become `res://test/art/sprite/player/walk/diffuse.png`.

## Impact

- **Specs**: `openspec/specs/test-scene/spec.md` (delta).
- **Scenes**: `test/test_scene.tscn`, `test/static_lit_prop.tscn`.
- **Assets**: no asset changes; `test/art/sprite/player/` already exists.
- **Risk**: minimal — `player_entity.tscn` already defaults its child `entity_name` to `"player"`, so the change reduces inconsistency rather than introducing it.
