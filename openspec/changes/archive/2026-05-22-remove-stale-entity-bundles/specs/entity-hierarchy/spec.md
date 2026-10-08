# Spec Delta: entity-hierarchy

## MODIFIED Requirements

### Requirement: Single presenter type for lit and unlit

The addon SHALL provide one primary **animated sprite presenter** implementation (the evolution of `AnimatedEntity`) that supports both unlit and engine-2D-lit sprite display via **configuration** (e.g. exports on the presenter). The addon SHALL NOT require a separate public script subclass whose sole purpose is lit behavior for packaged default scenes. In particular, the addon SHALL NOT ship `addons/godot-pixel-core/entity/lit_animated_entity.gd` or `lit_animated_entity.tscn`; lit behavior is selected entirely by the `use_2d_normal_lighting` export on `AnimatedEntity`.

#### Scenario: Lit toggled without swapping subclass

- **WHEN** a game author enables lit mode on the presenter in the inspector or via code
- **THEN** the presenter SHALL apply the diffuse + normal `CanvasTexture` bundle described in `sprite-engine-2d-lighting` without requiring a distinct `class_name` subclass for that mode

#### Scenario: Unlit remains default path

- **WHEN** lit mode is disabled on the presenter
- **THEN** the presenter SHALL display sprite-sheet frames without requiring a lit material on the `Sprite2D`

#### Scenario: No lit subclass file ships

- **WHEN** the addon directory `addons/godot-pixel-core/entity/` is inspected
- **THEN** there SHALL NOT be a script named `lit_animated_entity.gd` (nor an accompanying `.tscn`, `.gd.uid`, or `.tscn.uid`) defining a `LitAnimatedEntity` subclass of `AnimatedEntity`

---

### Requirement: Packaged player uses one scene pattern

The addon SHALL ship **one** canonical `PlayerEntity` scene (`addons/godot-pixel-core/entity/player_entity.tscn`) where **lit vs unlit** is selected by the child presenter's `use_2d_normal_lighting` export. The addon SHALL NOT require a second player scene whose only difference is instancing a lit-only presenter scene type. In particular, the addon SHALL NOT ship `addons/godot-pixel-core/entity/player_entity_lit.tscn`.

#### Scenario: Single player scene supports lit

- **WHEN** a consumer opens the packaged `player_entity.tscn`
- **THEN** they SHALL be able to enable or disable lit mode on the child presenter without loading a differently structured player scene

#### Scenario: No alternate lit player scene ships

- **WHEN** the addon directory `addons/godot-pixel-core/entity/` is inspected
- **THEN** there SHALL NOT be a scene named `player_entity_lit.tscn` (or any equivalent second player scene whose sole purpose is to swap in a lit-only presenter subclass)

---

### Requirement: Legacy inline character removed

The addon SHALL NOT ship `entity/characters/character.gd` and `character.tscn` as supported API. Character motion with sprite sheets SHALL use `CharacterEntity` (or subclass) with the shared presenter child.

#### Scenario: No duplicate character animation script

- **WHEN** the addon is inspected under `addons/godot-pixel-core/entity/`
- **THEN** there SHALL NOT be a legacy `CharacterBody2D` script that reimplements sprite-sheet timer and lookup logic parallel to the presenter

#### Scenario: Legacy filenames are absent

- **WHEN** the directory `addons/godot-pixel-core/entity/characters/` is inspected
- **THEN** `character.gd`, `character.gd.uid`, and `character.tscn` SHALL NOT exist; the directory MAY remain only if it holds other supported preset scenes (e.g. an updated `player.tscn` preset that instances `player_entity.tscn`)
