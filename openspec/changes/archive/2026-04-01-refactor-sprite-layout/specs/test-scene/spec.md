## MODIFIED Requirements

### Requirement: Lookup configured for test assets

The test scene SHALL configure the `AnimatedEntity`'s sprite lookup to resolve test assets. The `animated_sheet_root` SHALL be set to `"res://test/art/sprite/"` and the **`entity_name`** SHALL be set to `"girl"`.

#### Scenario: Walk animation resolves from test asset path

- **WHEN** the `AnimatedEntity` looks up action `"walk"` for entity `"girl"`
- **THEN** diffuse SHALL resolve from `res://test/art/sprite/girl/walk/diffuse.png` and optional passes from sibling files under `girl/walk/` when present

#### Scenario: Idle animation resolves from test asset path

- **WHEN** the `AnimatedEntity` looks up action `"idle"` for entity `"girl"`
- **THEN** diffuse SHALL resolve from `res://test/art/sprite/girl/idle/diffuse.png` and optional passes from sibling files under `girl/idle/` when present

#### Scenario: Configuration done from scene root

- **WHEN** the test scene initializes
- **THEN** a script on the scene root node SHALL configure the lookup path, not a subclass of `PlayerEntity` or `AnimatedEntity`

---

### Requirement: Test asset naming convention

Test animated passes SHALL follow `{animated_sheet_root}/{entity}/{action}/<pass>.png`. Under `test/art/sprite/girl/`, actions SHALL be **directories** (e.g. `walk/`, `idle/`) containing at least `diffuse.png` per action used in the test. Optional `normal.png` (and other passes) MAY be present per the addon layout spec.

#### Scenario: Walk passes at correct path

- **WHEN** the directory `test/art/sprite/girl/walk/` is inspected
- **THEN** `diffuse.png` SHALL exist and follow the animated sprite grid (8 directions, uniform cells, frame columns)

#### Scenario: Idle passes at correct path

- **WHEN** the directory `test/art/sprite/girl/idle/` is inspected
- **THEN** `diffuse.png` SHALL exist and follow the animated sprite grid (8 directions, uniform cells, frame columns)

---

### Requirement: Engine 2D lighting demonstrator

The test scene SHALL include at least one **`DirectionalLight2D`** or **`PointLight2D`** (or both) positioned so a **lit-mode** presenter using test assets is visibly affected by Godot’s 2D lighting. The scene SHALL enable the presenter’s lit mode on **`PlayerEntity`**’s child `AnimatedEntity` (or a documented equivalent lit subject) so diffuse and normal data from `res://test/art/sprite/girl/` participate in shading when those passes exist.

#### Scenario: Lit presenter responds to scene lights

- **WHEN** the test scene runs
- **THEN** at least one 2D light node SHALL be present and the lit presenter SHALL show shading attributable to engine 2D lighting (not merely flat albedo with lights ignored)

#### Scenario: Walk and idle still resolve test assets when lit

- **WHEN** the player moves or idles with lit mode enabled on the test `AnimatedEntity`
- **THEN** textures SHALL still resolve per **Requirement: Lookup configured for test assets** and normals SHALL stay aligned with diffuse for each frame when `normal.png` is present, or use documented fallback when absent
