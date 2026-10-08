## ADDED Requirements

### Requirement: Standard isometric input remap on character bodies

`CharacterEntity` SHALL provide a shared helper that converts a 2D axis input vector (e.g. from `Input.get_vector`) into a **screen-space unit direction** for orthographic isometric movement. Pure horizontal input SHALL map to **E/W** (±X, 0). Pure vertical input SHALL map to **N/S** (0, ±Y) in Godot screen coordinates (Y down). Combined horizontal and vertical input SHALL map to **NE, NW, SE, or SW** at a **2:1 screen slope (~26.6°, `atan(0.5)`)**, not 45°. The helper SHALL return `Vector2.ZERO` for approximately zero input and a **unit-length** vector otherwise so `velocity = remap(input) * speed` preserves uniform speed for cardinals and diagonals.

#### Scenario: Cardinal input stays axis-aligned

- **WHEN** `remap_input_to_screen` receives input approximately `(1, 0)`, `(-1, 0)`, `(0, 1)`, or `(0, -1)`
- **THEN** the returned direction SHALL be the corresponding unit vector along X or Y only

#### Scenario: Diagonal input uses 2-to-1 screen slope

- **WHEN** `remap_input_to_screen` receives input with both X and Y non-zero (e.g. `(1, 1)` for south-east)
- **THEN** the returned unit vector SHALL have a screen angle of approximately **26.6°** from horizontal in the appropriate quadrant (e.g. SE ≈ `(1, 0.5)` normalized), not a 45° raw axis diagonal

#### Scenario: Zero input returns zero

- **WHEN** `remap_input_to_screen` receives approximately zero input
- **THEN** it SHALL return `Vector2.ZERO`

### Requirement: Movement vector to facing on character bodies

`CharacterEntity` SHALL provide `_vector_to_direction(v: Vector2) -> String` that maps a movement direction vector to one of the canonical compass labels **S**, **SE**, **E**, **NE**, **N**, **NW**, **W**, **SW** (matching `SpriteSheetLookupBase.DIRECTIONS`). Subclasses that drive the child presenter’s facing from movement SHALL use this helper rather than duplicating sector math.

#### Scenario: Eight compass labels from movement vector

- **WHEN** `_vector_to_direction` is called with a non-zero unit vector aligned to each of the eight remapped isometric directions
- **THEN** it SHALL return the matching canonical direction string for that compass sector

#### Scenario: Subclasses reuse shared facing helper

- **WHEN** a `CharacterEntity` subclass (e.g. `PlayerEntity`) sets presenter facing from movement
- **THEN** it SHALL call `_vector_to_direction` on the remapped movement vector, not reimplement the mapping locally
