# Spec: Animated entity speed and framerate

## Purpose

Define how `AnimatedEntity` exports movement speed and animation framerate, and how `CharacterEntity` forwards those values from the character root and from the child `AnimatedEntity` as a single runtime source of truth.

## Requirements

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

---

### Requirement: Presenter exports pseudo-lighting configuration

`AnimatedEntity` (or the renamed successor presenter type) SHALL expose an **editor-visible** configuration (e.g. `@export`) that enables **pseudo-lighting** for the child `Sprite2D`. When enabled, the presenter SHALL apply the addon’s lit material and normal-map binding behavior; when disabled, the presenter SHALL behave as an unlit sprite-sheet display without requiring a separate public subclass for lit mode.

#### Scenario: Inspector shows pseudo-lighting option

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include an exported property (or equivalent) to enable or disable pseudo-lighting that persists on the scene

#### Scenario: Runtime toggling does not require subclass swap

- **WHEN** game code or scene configuration enables pseudo-lighting on the presenter
- **THEN** the implementation SHALL NOT require loading a different `class_name` solely to obtain lit behavior
