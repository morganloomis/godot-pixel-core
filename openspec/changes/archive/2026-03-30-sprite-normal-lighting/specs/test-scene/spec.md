# Spec Delta: test-scene

## ADDED Requirements

### Requirement: Pseudo-lighting is visible in the test scene

The test scene SHALL exercise **pseudo-lighting** provided by the addon: at minimum it SHALL configure **ambient**, the **global directional / scene** light, and at least one **point light** (or a documented stand-in such as a mouse-follow light) so that a human running the project can observe lighting changing the sprite’s appearance. Player movement, idle/walk behavior, and lookup configuration from existing requirements SHALL remain satisfied.

#### Scenario: Running the scene shows lit character

- **WHEN** the project is run with the test scene as the main scene
- **THEN** the `PlayerEntity` SHALL remain visible and controllable as today **AND** the character SHALL be rendered with pseudo-lighting effects that respond to configured or runtime-updated light parameters

#### Scenario: Lights can change during play

- **WHEN** the test scene runs and the test harness updates light parameters over time (e.g. moving a point light or varying intensity)
- **THEN** the visible lighting on the character SHALL update without requiring a scene reload

### Requirement: Test scene defers to addon implementations

The test scene SHALL drive behavior by instantiating and configuring addon scenes, classes, shaders, and documented APIs. Test scripts SHALL NOT reimplement sprite-sheet rect computation, animation timing, or pseudo-lighting math that the addon owns.

#### Scenario: Core logic lives in the addon

- **WHEN** the test scene implementation is reviewed for lookup, animation, and lighting
- **THEN** shared behavior SHALL be implemented under `addons/godot-pixel-core/` and invoked from `test/` only for wiring, tuning, and demo inputs

---

## REMOVED Requirements

### Requirement: No addon code changes

**Reason**: Delivering pseudo-lighting and normal-pass support requires implementing and maintaining behavior under `addons/godot-pixel-core/`. The test scene must demonstrate those addon features rather than forbidding addon edits.

**Migration**: Use **Requirement: Test scene defers to addon implementations** for constraints on how the test scene interacts with the addon.
