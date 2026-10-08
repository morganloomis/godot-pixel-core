## ADDED Requirements

### Requirement: Test scene file location

The test scene SHALL be located at `test/test_scene.tscn`. It SHALL be a standalone scene that exercises the addon's entity and sprite-sheet-lookup pipeline end-to-end using test assets.

#### Scenario: Scene exists at expected path

- **WHEN** the repository is inspected for the test scene
- **THEN** `test/test_scene.tscn` SHALL exist and be a valid Godot scene file

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

### Requirement: Lookup configured for test assets

The test scene SHALL configure the `AnimatedEntity`'s sprite lookup to resolve test assets. The `animated_sheet_root` SHALL be set to `"res://test/art/sprite/"` and the `entity_id` SHALL be set to `"girl"`.

#### Scenario: Walk animation resolves from test asset path

- **WHEN** the `AnimatedEntity` looks up action `"walk"` for entity `"girl"`
- **THEN** the lookup SHALL resolve the sheet at `res://test/art/sprite/girl/walk.png`

#### Scenario: Idle animation resolves from test asset path

- **WHEN** the `AnimatedEntity` looks up action `"idle"` for entity `"girl"`
- **THEN** the lookup SHALL resolve the sheet at `res://test/art/sprite/girl/idle.png`

#### Scenario: Configuration done from scene root

- **WHEN** the test scene initializes
- **THEN** a script on the scene root node SHALL configure the lookup path, not a subclass of `PlayerEntity` or `AnimatedEntity`

### Requirement: Test asset naming convention

Test sprite sheets SHALL follow the addon's `{animated_sheet_root}/{entity}/{action}.png` path convention. The walk sheet SHALL be named `walk.png` (not `girl_walk.png`) and the idle sheet SHALL be named `idle.png`, both under `test/art/sprite/girl/`.

#### Scenario: Walk sheet at correct path

- **WHEN** the test asset directory `test/art/sprite/girl/` is inspected
- **THEN** `walk.png` SHALL exist and follow the animated sprite sheet layout (diffuse/normal blocks, 8 directions)

#### Scenario: Idle sheet at correct path

- **WHEN** the test asset directory `test/art/sprite/girl/` is inspected
- **THEN** `idle.png` SHALL exist and follow the animated sprite sheet layout (diffuse/normal blocks, 8 directions)

### Requirement: Main scene set to test scene

The project SHALL launch the test scene when the game is run. `project.godot` SHALL set the main scene to `res://test/test_scene.tscn`.

#### Scenario: Running the project launches the test scene

- **WHEN** the Godot project is run (F5 or play button)
- **THEN** the test scene SHALL load and the player character SHALL be visible and controllable

### Requirement: Visual ground plane

The test scene SHALL include a visual ground element so the character is not rendered against a bare background. The ground SHALL be a simple `ColorRect` or equivalent — a full tile map is not required.

#### Scenario: Ground is visible behind character

- **WHEN** the test scene is running
- **THEN** a colored ground plane SHALL be visible behind/beneath the player character

### Requirement: No addon code changes

The test scene SHALL exercise the addon purely through instantiation and configuration. No files under `addons/godot-pixel-core/` SHALL be added, removed, or modified by this change.

#### Scenario: Addon directory is unchanged

- **WHEN** the changes for this test scene are reviewed
- **THEN** no files under `addons/godot-pixel-core/` SHALL have been modified
