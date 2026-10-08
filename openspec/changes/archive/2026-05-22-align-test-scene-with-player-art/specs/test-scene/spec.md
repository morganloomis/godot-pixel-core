# Spec Delta: test-scene

## MODIFIED Requirements

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
