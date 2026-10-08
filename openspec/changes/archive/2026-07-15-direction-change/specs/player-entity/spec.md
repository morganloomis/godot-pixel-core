## MODIFIED Requirements

### Requirement: Action and direction from input

The player entity SHALL update the child **presenter’s** action and **target** facing from input. When input is (approximately) zero, action SHALL be set to idle; when input is non-zero, action SHALL be set to walk (or the project’s walk action name). The player entity SHALL call `set_direction` on the presenter (not assign displayed facing directly) with the movement-derived facing from the canonical eight-direction set. The **displayed** facing on the presenter MAY lag behind the input-derived target during multi-step transitions per `animated-direction-transition`; when idle, the last requested target direction SHALL be kept so the character eventually faces the way it was moving.

#### Scenario: Walk when moving, idle when not

- **WHEN** the player provides non-zero movement input
- **THEN** the child presenter’s action SHALL be set to walk (or equivalent)

#### Scenario: Idle when no input

- **WHEN** the player provides no movement input
- **THEN** the child presenter’s action SHALL be set to idle (or equivalent)

#### Scenario: Target direction reflects movement input

- **WHEN** the player moves the character (e.g. right and down)
- **THEN** the child presenter’s target facing SHALL be set via `set_direction` to a value that matches that movement (e.g. **SE** for south-east)

#### Scenario: Sharp reversal requests new target without body-side transition logic

- **WHEN** the player changes input from one facing to an opposed facing (e.g. from **W** to **E**) in a single frame
- **THEN** the player entity SHALL call `set_direction` with the new facing only and SHALL NOT implement ring-stepping or path selection in `PlayerEntity`

#### Scenario: Last direction when idle

- **WHEN** the player stops moving (input zero) after requesting a facing
- **THEN** the presenter’s target and displayed facings SHALL eventually remain at the last movement facing so the character faces that way when idle
