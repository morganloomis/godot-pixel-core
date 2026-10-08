# Spec: Player Entity

## ADDED Requirements

### Requirement: Extends character entity

The player entity SHALL extend the character-entity type (script inheritance). It SHALL inherit body, collision, character attributes (e.g. health, speed), and the reference to the child AnimatedEntity. It SHALL NOT reimplement or duplicate character-entity or animated-entity logic.

#### Scenario: Player entity is a character entity

- **WHEN** a player entity is instantiated
- **THEN** it SHALL be a CharacterBody2D with the same structure as character entity (child AnimatedEntity, CollisionShape2D) and SHALL expose or use the same attributes (e.g. speed, health) from the base

### Requirement: Player input drives movement

The player entity SHALL read movement input from the project input map (e.g. ui_left, ui_right, ui_up, ui_down or custom actions) and SHALL set velocity from that input using the inherited speed (or equivalent). It SHALL call move_and_slide() so the character moves in the scene.

#### Scenario: Movement from input

- **WHEN** the player holds movement input (e.g. right and down)
- **THEN** the player entity SHALL set velocity so the character moves in that direction at the configured speed, and move_and_slide() SHALL be called so the body moves

#### Scenario: Idle when no input

- **WHEN** no movement input is pressed
- **THEN** velocity SHALL be (approximately) zero so the character does not move

### Requirement: Action and direction from input

The player entity SHALL update the child AnimatedEntity’s action and direction from input. When input is (approximately) zero, action SHALL be set to idle; when input is non-zero, action SHALL be set to walk (or the project’s walk action name). Direction SHALL reflect the movement direction (e.g. 8-direction); when idle, the last direction SHALL be kept so the character faces the way it was moving.

#### Scenario: Walk when moving, idle when not

- **WHEN** the player provides non-zero movement input
- **THEN** the child AnimatedEntity’s action SHALL be set to walk (or equivalent)

#### Scenario: Idle when no input

- **WHEN** the player provides no movement input
- **THEN** the child AnimatedEntity’s action SHALL be set to idle (or equivalent)

#### Scenario: Direction reflects movement

- **WHEN** the player moves the character (e.g. right and down)
- **THEN** the child AnimatedEntity’s direction SHALL be set to a value that matches that facing (e.g. SE for south-east)

#### Scenario: Last direction when idle

- **WHEN** the player stops moving (input zero)
- **THEN** the AnimatedEntity’s direction SHALL remain the last movement direction so the character faces that way
