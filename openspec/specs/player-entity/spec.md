# Spec: Player Entity

## Purpose

Define the requirements for a player-controlled character entity that extends the character-entity type, reads input from the project input map, and drives movement, action, and direction via the child presenter (`AnimatedEntity` or documented successor).

## Requirements

### Requirement: Extends character entity

The player entity SHALL extend the character-entity type (script inheritance). It SHALL inherit body, collision, character attributes (e.g. health, speed), and the reference to the child **presenter** (`AnimatedEntity` or documented successor). It SHALL NOT reimplement or duplicate character-entity or presenter logic.

#### Scenario: Player entity is a character entity

- **WHEN** a player entity is instantiated
- **THEN** it SHALL be a CharacterBody2D with the same structure as character entity (child presenter, CollisionShape2D) and SHALL expose or use the same attributes (e.g. speed, health) from the base

### Requirement: Player input drives movement

The player entity SHALL read movement input from the project input map (e.g. ui_left, ui_right, ui_up, ui_down or custom actions) and SHALL set velocity from that input using the inherited speed (or equivalent). Before applying speed, it SHALL call the inherited **`CharacterEntity.remap_input_to_screen`** helper so screen velocity uses **2:1 (~26.6°)** diagonals and unchanged cardinals. It SHALL call move_and_slide() so the character moves in the scene.

#### Scenario: Movement from input

- **WHEN** the player holds movement input (e.g. right and down)
- **THEN** the player entity SHALL set velocity along the **isometric south-east** screen direction at the configured speed (not along a 45° raw axis diagonal), and move_and_slide() SHALL be called so the body moves

#### Scenario: Cardinal movement from input

- **WHEN** the player holds a single axis (e.g. right only)
- **THEN** velocity SHALL be purely horizontal or vertical on screen at the configured speed

#### Scenario: Idle when no input

- **WHEN** no movement input is pressed
- **THEN** velocity SHALL be (approximately) zero so the character does not move

### Requirement: Action and direction from input

The player entity SHALL update the child **presenter's** action and **target** facing from input. When input is (approximately) zero, action SHALL be set to idle; when input is non-zero, action SHALL be set to walk (or the project's walk action name). The player entity SHALL call `set_direction` on the presenter with **`CharacterEntity._vector_to_direction`** applied to the **remapped** movement vector from `remap_input_to_screen`, not raw axis input. The **displayed** facing on the presenter MAY lag behind the input-derived target during multi-step transitions per `animated-direction-transition`; when idle, the last requested target direction SHALL be kept so the character eventually faces the way it was moving.

#### Scenario: Walk when moving, idle when not

- **WHEN** the player provides non-zero movement input
- **THEN** the child presenter's action SHALL be set to walk (or equivalent)

#### Scenario: Idle when no input

- **WHEN** the player provides no movement input
- **THEN** the child presenter's action SHALL be set to idle (or equivalent)

#### Scenario: Target direction reflects remapped movement

- **WHEN** the player moves the character (e.g. right and down)
- **THEN** the child presenter's target facing SHALL be set via `set_direction` to a value that matches the **remapped** movement direction (e.g. **SE** for south-east)

#### Scenario: Sharp reversal requests new target without body-side transition logic

- **WHEN** the player changes input from one facing to an opposed facing (e.g. from **W** to **E**) in a single frame
- **THEN** the player entity SHALL call `set_direction` with the new facing only and SHALL NOT implement ring-stepping or path selection in `PlayerEntity`

#### Scenario: Last direction when idle

- **WHEN** the player stops moving (input zero) after requesting a facing
- **THEN** the presenter's target and displayed facings SHALL eventually remain at the last movement facing so the character faces that way when idle

### Requirement: Player root inherits forwarded tuning exports

The player entity SHALL inherit from `CharacterEntity` the forwarded **movement speed** and **animation framerate** exports; it SHALL NOT declare separate duplicate exports for those scalars.

#### Scenario: Player inspector exposes movement and framerate on root

- **WHEN** a `PlayerEntity` node is selected in the editor
- **THEN** the inspector on the player root SHALL list **movement speed** and **animation framerate** as inherited character exports (same semantics as `CharacterEntity`)

#### Scenario: Input-driven motion uses forwarded speed

- **WHEN** the player entity applies velocity from input using inherited speed
- **THEN** the magnitude SHALL reflect the presenter movement speed as edited from the player root or the child presenter
