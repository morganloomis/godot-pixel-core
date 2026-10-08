## Why

After `fix-main-tscn-player-preset` removed the duplicate `AnimatedEntity` sibling from `addons/godot-pixel-core/entity/characters/player.tscn`, the preset correctly resolves to a single inherited presenter — but that presenter is **unlit**. The lit-mode flag is set nowhere in the chain:

- `animated_entity.tscn` defaults `use_2d_normal_lighting = false`.
- `player_entity.tscn` instances `animated_entity.tscn` and overrides only `entity_name`.
- `entity/characters/player.tscn` (the tuned preset) overrides only the root and the collider.

Consequently, `main.tscn`'s `Player` — placed under `DirectionalLight2D` + `CanvasModulate` — renders as a flat, dim sprite (`CanvasModulate` still tints it), not a normal-mapped sprite that responds to the directional light. This contradicts the proposal scenario in `fix-main-tscn-player-preset` task 3.1 ("renders the lit player sprite under the `DirectionalLight2D` and `CanvasModulate`").

`player_entity.tscn` SHOULD remain lighting-neutral so consumers can choose lit vs. unlit per scene; the *tuned* preset under `entity/characters/` is the right place to opt in. The art under `test/art/sprite/player/{idle,walk}/` already ships both `diffuse.png` and `normal.png`, so the lit path has data to render.

## What Changes

- In `addons/godot-pixel-core/entity/characters/player.tscn`, add a property override on the inherited `AnimatedEntity` child: `use_2d_normal_lighting = true`. This is the only behavior change.
- Update the `sprite-presentation` spec to record that the addon's tuned character preset(s) under `entity/characters/` SHALL opt in to engine 2D normal lighting on their inherited presenter, while the lower-level body scenes (`character_entity.tscn`, `player_entity.tscn`) SHALL remain lighting-neutral and let consumers opt in.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `sprite-presentation`: add a requirement specifying where lit-mode opt-in lives — the addon's tuned character presets (e.g. `entity/characters/player.tscn`) opt in to `use_2d_normal_lighting = true`; the body scenes they inherit (`character_entity.tscn`, `player_entity.tscn`) remain lighting-neutral.

## Impact

- **Addon**: one-line property override on the inherited `AnimatedEntity` inside `addons/godot-pixel-core/entity/characters/player.tscn`. No script changes.
- **Dev harness**: `main.tscn` benefits transitively — its `Player` instance now renders lit under the existing `DirectionalLight2D` + `CanvasModulate` with no edit to `main.tscn`.
- **Consumers**: anyone instancing `player_entity.tscn` directly is unaffected (still unlit by default). Anyone instancing `entity/characters/player.tscn` now gets a lit player; if they want unlit, they override the flag back to `false` on their instance.
- **Risk**: low. The lit path is already exercised by `LitTileMapLayer` and `AnimatedEntity._apply_2d_normal_lighting_setup()`; this change just flips the authoring-time flag on one preset. No new spec capabilities.
