# Spec Delta: sprite-presentation

## ADDED Requirements

### Requirement: Preset scenes do not re-instance the inherited presenter

When the addon ships a preset scene that **inherits from** or **instances** `character_entity.tscn` or `player_entity.tscn`, the preset SHALL configure the inherited child `AnimatedEntity` via **property overrides only** (e.g. `entity_name`, `use_2d_normal_lighting`, `movement_speed`, `frame_rate`). The preset SHALL NOT add a second `[node ... instance=ExtResource("animated_entity.tscn")]` block, whether under the same name (`AnimatedEntity`), a scoped name (e.g. `player#AnimatedEntity`), or another name with `parent="."` and `index="0"`. This rule keeps the canonical presenter child the single source of truth for sprite lookup, lit mode, and tuning on preset scenes.

#### Scenario: Preset edits inherited child via overrides

- **WHEN** an addon preset (such as `entity/characters/player.tscn`) is opened in Godot 4.6
- **THEN** the scene tree SHALL show exactly **one** `AnimatedEntity` child under the inherited body, and any custom values (e.g. tuned `entity_name`, `use_2d_normal_lighting`, framerate, movement speed) SHALL be set as overrides on that inherited node rather than on a fresh re-instance

#### Scenario: Preset CollisionShape is also an override

- **WHEN** a preset wants to tune the inherited `CollisionShape2D` (different shape, rotation, or offset)
- **THEN** the preset SHALL override properties on the inherited collision child or add a clearly distinct named collider, but SHALL NOT re-instance `animated_entity.tscn` to satisfy collision tuning

#### Scenario: Removing the preset is not required

- **WHEN** the addon decides not to ship a tuned preset
- **THEN** consumers SHALL be able to use `player_entity.tscn` directly and set overrides on their own instance; this requirement does not mandate that a preset must exist, only that any preset that does exist obeys the rule above
