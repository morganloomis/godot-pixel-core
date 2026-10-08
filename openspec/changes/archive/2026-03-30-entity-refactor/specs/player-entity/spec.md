# Spec delta: player-entity (change: entity-refactor)

## MODIFIED Requirements

### Requirement: Extends character entity

The player entity SHALL extend the character-entity type (script inheritance). It SHALL inherit body, collision, character attributes (e.g. health, speed), and the reference to the child **presenter** (`AnimatedEntity` or documented successor). It SHALL NOT reimplement or duplicate character-entity or presenter logic.

#### Scenario: Player entity is a character entity

- **WHEN** a player entity is instantiated
- **THEN** it SHALL be a CharacterBody2D with the same structure as character entity (child presenter, CollisionShape2D) and SHALL expose or use the same attributes (e.g. speed, health) from the base

---

### Requirement: Action and direction from input

The player entity SHALL update the child **presenter’s** action and direction from input. When input is (approximately) zero, action SHALL be set to idle; when input is non-zero, action SHALL be set to walk (or the project’s walk action name). Direction SHALL reflect the movement direction (e.g. 8-direction); when idle, the last direction SHALL be kept so the character faces the way it was moving.

#### Scenario: Walk when moving, idle when not

- **WHEN** the player provides non-zero movement input
- **THEN** the child presenter’s action SHALL be set to walk (or equivalent)

#### Scenario: Idle when no input

- **WHEN** the player provides no movement input
- **THEN** the child presenter’s action SHALL be set to idle (or equivalent)

#### Scenario: Direction reflects movement

- **WHEN** the player moves the character (e.g. right and down)
- **THEN** the child presenter’s direction SHALL be set to a value that matches that facing (e.g. SE for south-east)

#### Scenario: Last direction when idle

- **WHEN** the player stops moving (input zero)
- **THEN** the presenter’s direction SHALL remain the last movement direction so the character faces that way
