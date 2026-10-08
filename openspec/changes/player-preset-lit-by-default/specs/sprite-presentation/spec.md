# Spec Delta: sprite-presentation

## ADDED Requirements

### Requirement: Tuned character presets opt in to engine 2D normal lighting

Addon-shipped **tuned character preset scenes** under `addons/godot-pixel-core/entity/characters/` (e.g. `player.tscn`, and any future NPC / enemy presets following the same pattern) SHALL set `use_2d_normal_lighting = true` as a property override on their inherited `AnimatedEntity` child, so that consumers who instance the preset receive a presenter ready for engine 2D normal-mapped lighting under `DirectionalLight2D` / `PointLight2D` without further configuration. The lower-level body scenes that these presets inherit from (`character_entity.tscn`, `player_entity.tscn`) SHALL remain lighting-neutral (`use_2d_normal_lighting` left at its `animated_entity.tscn` default of `false`), so consumers who instance the body scenes directly retain free choice of lit vs unlit rendering.

The override SHALL be expressed as a property edit on the inherited `AnimatedEntity` child (same node name, no `type=`, no `instance=`), consistent with "Preset scenes do not re-instance the inherited presenter".

#### Scenario: Player preset renders lit under a 2D light

- **WHEN** a consumer instances `addons/godot-pixel-core/entity/characters/player.tscn` into a scene that contains a `DirectionalLight2D` (and optionally a `CanvasModulate`), runs the project, and inspects the resulting `Sprite2D` under the player's inherited `AnimatedEntity`
- **THEN** the `Sprite2D` SHALL have a `CanvasItemMaterial` with `light_mode = LIGHT_MODE_NORMAL` and its `texture` SHALL be a `CanvasTexture` carrying both the diffuse and normal cell for the current frame, so the sprite responds visibly to the light direction and intensity

#### Scenario: Body scenes remain lighting-neutral

- **WHEN** a consumer instances `player_entity.tscn` (or `character_entity.tscn`) directly — not via the tuned preset
- **THEN** the inherited `AnimatedEntity` `use_2d_normal_lighting` value SHALL be `false`, so the consumer renders unlit by default and explicitly opts in to lit mode by overriding the flag on their instance

#### Scenario: Consumer can override the preset back to unlit

- **WHEN** a consumer instances the tuned player preset but does not want engine 2D normal lighting
- **THEN** they SHALL be able to override `use_2d_normal_lighting = false` on the inherited `AnimatedEntity` child of their preset instance, and the presenter SHALL render unlit accordingly (no `CanvasItemMaterial`, plain `AtlasTexture` on `Sprite2D.texture`)
