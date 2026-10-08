## ADDED Requirements

### Requirement: AnimatedEntity exports movement speed

`AnimatedEntity` SHALL expose an `@export` property for **movement speed** in the same units used by `CharacterBody2D` motion in this addon (pixels per second when velocity is set from input). The default value SHALL match the prior default motion speed of packaged character scenes before this change.

#### Scenario: Inspector shows movement speed on AnimatedEntity

- **WHEN** an `AnimatedEntity` node is selected in the editor
- **THEN** the inspector includes an exported **movement speed** property that can be edited and saved on the scene

#### Scenario: Runtime read for physics

- **WHEN** game code on a `CharacterEntity` computes movement using the addon’s standard parent/child layout (`CharacterEntity` with child `AnimatedEntity`)
- **THEN** the magnitude of motion SHALL be derived from that child’s exported movement speed (not from a separate duplicate export on the body for the default case)

---

### Requirement: AnimatedEntity exports animation framerate

`AnimatedEntity` SHALL expose an `@export` property for **animation framerate** (frames per second) that controls how often the animation timer advances frames. Values SHALL be positive for normal playback; non-positive values SHALL be handled in a defined, non-crashing way (e.g. same minimum behavior as today).

#### Scenario: Inspector shows animation framerate

- **WHEN** an `AnimatedEntity` node is selected in the editor
- **THEN** the inspector includes an exported property for animation framerate (FPS) that can be edited and saved on the scene

#### Scenario: Framerate drives timer

- **WHEN** the animation framerate export is set or changed such that playback should update
- **THEN** the internal animation timer’s step interval SHALL reflect the reciprocal of that framerate (consistent with existing `_apply_frame_rate` behavior)

---

### Requirement: CharacterEntity uses child movement speed

`CharacterEntity` SHALL NOT expose a separate exported **speed** field that duplicates the child `AnimatedEntity` movement speed in the default addon design. It SHALL obtain the scalar used for movement from the child `AnimatedEntity` when present.

#### Scenario: Player movement uses AnimatedEntity speed

- **WHEN** `PlayerEntity` (or equivalent) sets velocity from input using the addon’s standard pattern
- **THEN** the speed multiplier SHALL come from the `AnimatedEntity` child’s movement speed property

#### Scenario: Missing child does not crash

- **WHEN** `CharacterEntity` logic reads movement speed and the `AnimatedEntity` child is absent or not yet ready
- **THEN** the implementation SHALL use a safe fallback default rather than failing with a null access
