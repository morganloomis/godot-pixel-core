## MODIFIED Requirements

### Requirement: CharacterEntity uses child movement speed

`CharacterEntity` SHALL obtain movement speed and animation framerate from the child `AnimatedEntity` as the single runtime source of truth. For packaged character layouts, `CharacterEntity` SHALL expose **forwarded** `@export` properties on the **character root** for **movement speed** and **animation framerate** that read and write the child presenter’s `movement_speed` and `frame_rate`, so authors can tune them without selecting the child node. `CharacterEntity` SHALL NOT keep separate scalar storage that can diverge from the presenter.

#### Scenario: Inspector shows movement speed and framerate on character root

- **WHEN** a `CharacterEntity` (or subclass such as player entity) with the standard child presenter layout is selected in the editor
- **THEN** the inspector on the character root SHALL include exported **movement speed** and **animation framerate** alongside other character attributes

#### Scenario: Forwarded values drive presenter

- **WHEN** movement speed or animation framerate is set on the character root export
- **THEN** the child `AnimatedEntity`’s `movement_speed` and `frame_rate` SHALL reflect that value; editing the child’s exports SHALL be reflected when reading the root forwards

#### Scenario: Player movement uses presenter movement speed

- **WHEN** `PlayerEntity` (or equivalent) sets velocity from input using the addon’s standard pattern
- **THEN** the speed multiplier SHALL come from the presenter’s movement speed (whether last edited from the character root or the child)

#### Scenario: Missing child does not crash

- **WHEN** `CharacterEntity` logic reads or writes forwarded movement speed or framerate and the `AnimatedEntity` child is absent or not yet ready
- **THEN** the implementation SHALL use safe fallback defaults or defer writes rather than failing with a null access
