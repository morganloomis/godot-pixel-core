## MODIFIED Requirements

### Requirement: Animated sheet layout convention

Animated sprite data SHALL be stored under a **directory per action**: `{animated_root}/{entity}/{action}/`. Within that directory, each **pass** is an optional PNG with a fixed filename:

- `diffuse.png` — albedo; **required** for that action to participate in animated lookup and playback
- `normal.png` — tangent-space (or project-defined) normals for the same grid
- `specular.png` — optional; reserved for shading features that consume a specular map
- `occlusion.png` — optional; reserved for ambient occlusion or masking

Each present pass file SHALL be a **single** grid: **8 direction rows** (top to bottom order SHALL match `sprite-sheet-facing`: **S**, **SE**, **E**, **NE**, **N**, **NW**, **W**, **SW**) and **one column per animation frame**. All cells SHALL have equal pixel width and height. **Frame count** and **cell size** SHALL be derived from `diffuse.png` dimensions for that action. When `normal.png`, `specular.png`, or `occlusion.png` exists, it SHALL have the **same** frame count and cell dimensions as `diffuse.png` for that action.

#### Scenario: Derive cell size from diffuse sheet dimensions

- **WHEN** `diffuse.png` for an action has image width W, height H, and frame count F is known (from dimensions or metadata)
- **THEN** cell width is W/F, cell height is H/8, and the region for (direction_index, frame_index) in that pass is uniquely determined

#### Scenario: Direction name maps to row index

- **WHEN** direction is given as name in the canonical set (e.g. "SE", "N")
- **THEN** row index matches `sprite-sheet-facing` (e.g. "S" → 0, "SE" → 1, …, "SW" → 7)

### Requirement: Uniform resolution per sheet

Each sprite sheet file MUST use a single cell resolution: every cell in that file SHALL have the same width and height. For a given **action**, when more than one pass file exists, all pass files for that action SHALL use the **same** cell width, cell height, and frame count as `diffuse.png`. Animated entities SHALL use one resolution for all frames and all directions within an action (no switching resolution mid-action).

#### Scenario: Animated entity single resolution per action

- **WHEN** an entity uses multiple pass files for the same action (e.g. diffuse and normal)
- **THEN** all those files use identical cell dimensions and column count

#### Scenario: Static sheet uniform cells

- **WHEN** a static sheet is loaded
- **THEN** all cells in the grid have identical dimensions

### Requirement: Separate asset directories for animated and static

Animated sprite passes SHALL be stored under the configured animated-sheet root using the `{entity}/{action}/<pass>.png` pattern. Static sprite sheets SHALL remain under a different configured root. The two layout types SHALL NOT share the same directory tree.

#### Scenario: Resolve path for animated pass

- **WHEN** the system needs a pass file for entity E, action A, and pass P
- **THEN** the path is `{animated_root}/E/A/P.png` (with P one of `diffuse`, `normal`, `specular`, `occlusion`) and does not use the static-sheet root

#### Scenario: Resolve path for static sheet

- **WHEN** the system needs the path for a static sheet by identifier
- **THEN** the path is constructed from the static-sheet root, not under the animated entity/action tree

## ADDED Requirements

### Requirement: Optional pass files

Passes other than `diffuse` SHALL be optional. If a pass file does not exist on disk, the system SHALL not load it and SHALL not treat its absence as an error. Behavior for rendering when a pass is missing SHALL follow `sprite-engine-2d-lighting` and presenter rules (e.g. flat normal when normal is absent in lit mode).

#### Scenario: Action with only diffuse

- **WHEN** only `diffuse.png` exists under `{animated_root}/{entity}/{action}/`
- **THEN** animated lookup succeeds for diffuse and omitted passes are not loaded

#### Scenario: Normal optional for lit mode

- **WHEN** `normal.png` is absent but lit mode is enabled
- **THEN** the documented lit presenter path still supplies valid shading inputs (e.g. flat normal) without requiring `normal.png`
