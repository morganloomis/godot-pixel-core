# Spec delta: entity-hierarchy (change: entity-refactor)

## ADDED Requirements

### Requirement: Single presenter type for lit and unlit

The addon SHALL provide one primary **animated sprite presenter** implementation (the evolution of `AnimatedEntity`) that supports both unlit and pseudo-lit sprite display via **configuration** (e.g. exports on the presenter). The addon SHALL NOT require a separate public script subclass whose sole purpose is pseudo-lit behavior for packaged default scenes.

#### Scenario: Lit toggled without swapping subclass

- **WHEN** a game author enables pseudo-lighting on the presenter in the inspector or via code
- **THEN** the presenter SHALL apply diffuse and normal binding consistent with `sprite_lit.gdshader` without requiring a distinct `class_name` subclass for that mode

#### Scenario: Unlit remains default path

- **WHEN** pseudo-lighting is disabled on the presenter
- **THEN** the presenter SHALL display sprite-sheet frames without requiring a lit material on the `Sprite2D`

---

### Requirement: Packaged player uses one scene pattern

The addon SHALL ship **one** canonical `PlayerEntity` scene (or one documented composition pattern) where **pseudo-lit vs unlit** is selected by presenter configuration. The addon SHALL NOT require a second player scene whose only difference is instancing a lit-only presenter scene type.

#### Scenario: Single player scene supports lit

- **WHEN** a consumer opens the packaged `player_entity.tscn` (or documented equivalent)
- **THEN** they SHALL be able to enable or disable pseudo-lighting on the child presenter without loading a differently structured player scene

---

### Requirement: Legacy inline character removed

The addon SHALL NOT ship `entity/characters/character.gd` and `character.tscn` as supported API. Character motion with sprite sheets SHALL use `CharacterEntity` (or subclass) with the shared presenter child.

#### Scenario: No duplicate character animation script

- **WHEN** the addon is inspected under `addons/godot-pixel-core/entity/`
- **THEN** there SHALL NOT be a legacy `CharacterBody2D` script that reimplements sprite-sheet timer and lookup logic parallel to the presenter

---

### Requirement: Tiles are not character subclasses

The addon’s character entity type SHALL NOT imply that `TileMapLayer` or tile data types inherit from or extend the character-entity script hierarchy. Map authoring via `TileSet` / `TileMapLayer` remains orthogonal; reuse of sheet conventions SHALL be specified under sprite-presentation, not as a tile subclass of `CharacterEntity`.

#### Scenario: Documentation does not claim tile inheritance

- **WHEN** addon documentation describes tiles vs characters
- **THEN** it SHALL state that tiles are not subclasses of character entity and that per-cell pseudo-lit props MAY use scene instances (body + presenter) instead
