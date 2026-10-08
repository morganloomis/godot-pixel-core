# Spec Delta: test-scene

## ADDED Requirements

### Requirement: Test harness enables ground-shadow spike

The test scene root script (`test/test_scene.gd`) SHALL opt in to the experimental ground-shadow spike on the player's `AnimatedEntity` by setting `use_ground_shadow = true` and assigning `shadow_light` to the scene's primary `DirectionalLight2D` NodePath. This SHALL occur alongside the existing lit-mode wiring and SHALL NOT replace or duplicate the addon's engine 2D lighting path.

#### Scenario: Ground shadow spike enabled at runtime

- **WHEN** `test/test_scene.tscn` loads at runtime
- **THEN** the `AnimatedEntity` under `PlayerEntity` SHALL have `use_ground_shadow = true` AND `shadow_light` SHALL reference the scene's `DirectionalLight2D`

#### Scenario: Lit mode and shadow spike coexist

- **WHEN** the test scene runs with both `use_2d_normal_lighting = true` and `use_ground_shadow = true`
- **THEN** the body sprite SHALL still respond to engine 2D lighting AND the shadow child SHALL render via the shadow shader without requiring `SpriteLighting` autoload

---

### Requirement: Test scene documents manual shadow validation

The test scene SHALL be the manual validation surface for the ground-shadow spike. Automated headless load SHALL succeed with or without `shadow.png` present; visual verification (rotating `DirectionalLight2D` changes shadow direction and apparent length) is a documented manual step in `tasks.md`, not a CI gate.

#### Scenario: Scene loads without shadow pass art

- **WHEN** `shadow.png` is absent under `test/art/sprite/player/` actions
- **THEN** the test scene SHALL still load and run without script errors AND the body sprite SHALL remain visible and controllable

#### Scenario: Shadow pass present enables visual check

- **WHEN** `shadow.png` exists for a test action (e.g. `test/art/sprite/player/idle/shadow.png`) and the scene runs
- **THEN** a ground shadow SHALL be visible under the player when idle/walk displays that action AND rotating the scene `DirectionalLight2D` SHALL visibly change shadow orientation (manual check)

---

### Requirement: Test scripts do not fork shadow implementation

Code under `test/` SHALL configure the spike through `AnimatedEntity` exports and scene NodePaths only. Test scripts SHALL NOT implement a parallel shadow shader, lookup, or smear system that replaces the addon's `shadow_height_project.gdshader` path.

#### Scenario: No duplicate shadow stack in test/

- **WHEN** scripts under `test/` are reviewed for this change
- **THEN** they SHALL not introduce a second, test-only ground-shadow renderer meant to supersede the addon spike
