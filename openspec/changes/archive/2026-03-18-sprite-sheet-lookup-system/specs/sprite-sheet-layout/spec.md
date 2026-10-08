# Spec: Sprite sheet layout

## ADDED Requirements

### Requirement: Animated sheet layout convention

Animated sprite sheets SHALL use one image file per action. The image MUST be divided into two vertical blocks of equal height: the first block is diffuse, the second block is normal. Within each block, rows SHALL represent the 8 directions and columns SHALL represent frames. Direction row order SHALL be N (row 0), NE (1), E (2), SE (3), S (4), SW (5), W (6), NW (7) — clockwise from N. All cells in the sheet MUST have the same pixel dimensions (cell width and cell height). Frame count and cell size SHALL be derivable from image dimensions and layout type, or overridable via optional metadata.

#### Scenario: Derive cell size from animated sheet dimensions

- **WHEN** an animated sheet has image width W, height H, and frame count F is known (from dimensions or metadata)
- **THEN** each block height is H/2; cell width is W/F; cell height is (H/2)/8; and the region for (direction_index, frame_index, diffuse) or (direction_index, frame_index, normal) is uniquely determined

#### Scenario: Direction name maps to row index

- **WHEN** direction is given as name (e.g. "SE", "N")
- **THEN** row index is 0 for "N", 1 for "NE", 2 for "E", 3 for "SE", 4 for "S", 5 for "SW", 6 for "W", 7 for "NW"

### Requirement: Static grid layout convention

Static sprite sheets SHALL be a single image arranged as a uniform grid of cells. All cells in the sheet MUST have the same pixel dimensions. Lookup SHALL be by linear index (row-major: index = row * columns + col) or by (row, column). Column count SHALL be derivable from image dimensions and cell size, or from optional metadata.

#### Scenario: Derive grid dimensions from static sheet

- **WHEN** a static sheet has image width W, height H, and cell width Cw, cell height Ch
- **THEN** columns = W/Cw, rows = H/Ch, and the region for a given (row, col) or linear index is uniquely determined

#### Scenario: Linear index equals row-major order

- **WHEN** lookup uses linear index i with columns per row = C
- **THEN** row = i / C, col = i % C (integer division), and the same cell is addressed as (row, col)

### Requirement: Uniform resolution per sheet

Each sprite sheet MUST use a single cell resolution: every cell in that sheet SHALL have the same width and height. Animated entities SHALL use one resolution for all frames and all directions (no switching resolution mid-entity).

#### Scenario: Animated entity single resolution

- **WHEN** an entity uses animated sheets for multiple actions
- **THEN** all sheets for that entity use the same cell width and cell height

#### Scenario: Static sheet uniform cells

- **WHEN** a static sheet is loaded
- **THEN** all cells in the grid have identical dimensions

### Requirement: Separate asset directories for animated and static

Animated sprite sheets SHALL be stored under a dedicated directory (e.g. under a path reserved for animated sheets). Static sprite sheets SHALL be stored under a different directory (e.g. for tiles or static grids). The two layout types SHALL NOT share the same directory tree.

#### Scenario: Resolve path for animated sheet

- **WHEN** the system needs the path for an animated sheet for entity E and action A
- **THEN** the path is under the configured animated-sheet root (e.g. animated root + entity + action), not under the static root

#### Scenario: Resolve path for static sheet

- **WHEN** the system needs the path for a static sheet by identifier
- **THEN** the path is under the configured static-sheet root, not under the animated root
