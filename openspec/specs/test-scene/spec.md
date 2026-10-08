# Spec: test-scene

## Purpose

Define the repository test scene, harness wiring, and test asset paths used to exercise the addon end-to-end.

## Requirements

### Requirement: Test scene file location

The test scene SHALL be located at `test/test_scene.tscn`. It SHALL be a standalone scene that exercises the addon's entity and sprite-sheet-lookup pipeline end-to-end using test assets.

#### Scenario: Scene exists at expected path

- **WHEN** the repository is inspected for the test scene
- **THEN** `test/test_scene.tscn` SHALL exist and be a valid Godot scene file

---

### Requirement: Uses addon PlayerEntity

The test scene SHALL instantiate the addon's `PlayerEntity` (from `addons/godot-pixel-core/entity/player_entity.tscn`) as a child node. It SHALL NOT use the legacy `Character` script or duplicate addon logic.

#### Scenario: PlayerEntity is present in the scene tree

- **WHEN** the test scene is loaded
- **THEN** the scene tree SHALL contain a `PlayerEntity` node that is an instance of `res://addons/godot-pixel-core/entity/player_entity.tscn`

#### Scenario: Player input drives movement

- **WHEN** the player presses arrow keys or gamepad directional input
- **THEN** the `PlayerEntity` SHALL move in the corresponding direction and the child `AnimatedEntity` SHALL display the walk animation facing that direction

#### Scenario: Idle animation when no input

- **WHEN** the player releases all movement input
- **THEN** the child `AnimatedEntity` SHALL display the idle animation facing the last movement direction

---

### Requirement: Lookup configured for test assets

The test scene SHALL configure the `AnimatedEntity`'s sprite lookup to resolve test assets. The `animated_sheet_root` SHALL be set to `"res://test/art/sprite/"` and the **`entity_name`** SHALL be set to `"player"`.

#### Scenario: Walk animation resolves from test asset path

- **WHEN** the `AnimatedEntity` looks up action `"walk"` for entity `"player"`
- **THEN** diffuse SHALL resolve from `res://test/art/sprite/player/walk/diffuse.png` and optional passes from sibling files under `player/walk/` when present

#### Scenario: Idle animation resolves from test asset path

- **WHEN** the `AnimatedEntity` looks up action `"idle"` for entity `"player"`
- **THEN** diffuse SHALL resolve from `res://test/art/sprite/player/idle/diffuse.png` and optional passes from sibling files under `player/idle/` when present

#### Scenario: Configuration done from scene root

- **WHEN** the test scene initializes
- **THEN** a script on the scene root node SHALL configure the lookup path, not a subclass of `PlayerEntity` or `AnimatedEntity`

---

### Requirement: Test asset naming convention

Test animated passes SHALL follow `{animated_sheet_root}/{entity}/{action}/<pass>.png`. Under `test/art/sprite/player/`, actions SHALL be **directories** (e.g. `walk/`, `idle/`) containing at least `diffuse.png` per action used in the test. Optional `normal.png` (and other passes) MAY be present per the addon layout spec.

#### Scenario: Walk passes at correct path

- **WHEN** the directory `test/art/sprite/player/walk/` is inspected
- **THEN** `diffuse.png` SHALL exist and follow the animated sprite grid (8 directions, uniform cells, frame columns)

#### Scenario: Idle passes at correct path

- **WHEN** the directory `test/art/sprite/player/idle/` is inspected
- **THEN** `diffuse.png` SHALL exist and follow the animated sprite grid (8 directions, uniform cells, frame columns)

---

### Requirement: Main scene set to test scene

The project SHALL launch the test scene when the game is run. `project.godot` SHALL set the main scene to `res://test/test_scene.tscn`.

#### Scenario: Running the project launches the test scene

- **WHEN** the Godot project is run (F5 or play button)
- **THEN** the test scene SHALL load and the player character SHALL be visible and controllable

---

### Requirement: Visual ground plane

The test scene SHALL include a visual ground element so the character is not rendered against a bare background. The ground SHALL be a simple `ColorRect` or equivalent — a full tile map is not required.

#### Scenario: Ground is visible behind character

- **WHEN** the test scene is running
- **THEN** a colored ground plane SHALL be visible behind/beneath the player character

---

### Requirement: Test harness does not fork addon core

The test scene SHALL exercise the addon through scene structure and configuration (including root scripts that set lookup paths or exports). Code under **`test/`** SHALL NOT implement parallel sprite lookup, animation, or **lighting** systems that replace or duplicate the addon’s documented behavior.

#### Scenario: No shadow lighting stack in test scripts

- **WHEN** scripts under `test/` are reviewed alongside the lighting refactor
- **THEN** they SHALL not introduce a second, test-only lighting implementation meant to supersede the addon’s engine-lit path

---

### Requirement: Engine 2D lighting demonstrator

The test scene SHALL include at least one **`DirectionalLight2D`** or **`PointLight2D`** (or both) positioned so a **lit-mode** presenter using test assets is visibly affected by Godot’s 2D lighting. The scene SHALL enable the presenter’s lit mode on **`PlayerEntity`**’s child `AnimatedEntity` (or a documented equivalent lit subject) so diffuse and normal data from `res://test/art/sprite/player/` participate in shading when those passes exist.

#### Scenario: Lit presenter responds to scene lights

- **WHEN** the test scene runs
- **THEN** at least one 2D light node SHALL be present and the lit presenter SHALL show shading attributable to engine 2D lighting (not merely flat albedo with lights ignored)

#### Scenario: Walk and idle still resolve test assets when lit

- **WHEN** the player moves or idles with lit mode enabled on the test `AnimatedEntity`
- **THEN** textures SHALL still resolve per **Requirement: Lookup configured for test assets** and normals SHALL stay aligned with diffuse for each frame when `normal.png` is present, or use documented fallback when absent

---

### Requirement: Direction transition manual check

The test scene SHALL support manual verification of multi-step direction transitions on the `PlayerEntity` child presenter. The scene SHALL include an on-screen hint (e.g. `Label` or equivalent UI text) instructing the tester to move in one direction then quickly reverse to the **opposed** facing (e.g. **W** then **E**) so intermediate facings are observable during play. The hint SHALL be visible when the test scene runs and SHALL NOT require reading repository documentation to perform the check.

#### Scenario: Hint visible at runtime

- **WHEN** the test scene is running
- **THEN** on-screen text SHALL describe reversing direction (e.g. hold left then tap right) to observe stepped facings

#### Scenario: Sharp reversal shows stepped facings on walk

- **WHEN** the tester holds movement input for one facing (e.g. **W**), then switches to the opposed facing (**E**) while still moving
- **THEN** the child `AnimatedEntity` SHALL display **walk** frames that step through intermediate compass facings along one arc before reaching **E**, rather than snapping instantly from **W** to **E**

#### Scenario: Sharp reversal observable on idle after stop

- **WHEN** the tester requests an opposed facing during movement and then releases input before the transition completes
- **THEN** the presenter SHALL continue stepping displayed facings on the **idle** action until the target facing is reached, showing intermediate idle rows if the transition was still active
