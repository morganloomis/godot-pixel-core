## ADDED Requirements

### Requirement: Forwarded movement speed and animation framerate on character root

The character entity SHALL expose editor-visible forwarded exports for **movement speed** and **animation framerate** on the **character body root** that map to the child presenter’s `movement_speed` and `frame_rate`. Units and default semantics SHALL match the presenter (`AnimatedEntity`).

#### Scenario: Root tuning updates presenter

- **WHEN** a game author changes movement speed or animation framerate on the character root in the inspector
- **THEN** the child presenter’s corresponding properties SHALL update and runtime motion and animation timing SHALL behave as if those presenter exports were edited directly

#### Scenario: Single underlying state

- **WHEN** movement speed or framerate is read from the character root export after editing the child presenter directly
- **THEN** the read value SHALL match the presenter’s current value (no independent duplicate state on the character body)
