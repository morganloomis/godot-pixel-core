## ADDED Requirements

### Requirement: Player root inherits forwarded tuning exports

The player entity SHALL inherit from `CharacterEntity` the forwarded **movement speed** and **animation framerate** exports; it SHALL NOT declare separate duplicate exports for those scalars.

#### Scenario: Player inspector exposes movement and framerate on root

- **WHEN** a `PlayerEntity` node is selected in the editor
- **THEN** the inspector on the player root SHALL list **movement speed** and **animation framerate** as inherited character exports (same semantics as `CharacterEntity`)

#### Scenario: Input-driven motion uses forwarded speed

- **WHEN** the player entity applies velocity from input using inherited speed
- **THEN** the magnitude SHALL reflect the presenter movement speed as edited from the player root or the child presenter
