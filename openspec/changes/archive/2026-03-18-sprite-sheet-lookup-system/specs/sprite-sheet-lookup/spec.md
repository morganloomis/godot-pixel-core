# Spec: Sprite sheet lookup

## ADDED Requirements

### Requirement: Base class owns lookup and caching

A base class SHALL own the logic for loading sheet textures, resolving regions from layout rules, and caching loaded sheets. It SHALL be the single place where layout conventions (animated vs static) are applied to produce texture regions. Subclasses SHALL represent animated vs static behaviour and expose only the API appropriate to each layout type.

#### Scenario: Base class loads and caches sheet

- **WHEN** a sheet is requested by path or (entity, action) for the first time
- **THEN** the base class loads the texture, caches it, and subsequent requests for the same sheet reuse the cached texture

#### Scenario: Subclasses delegate region resolution to base

- **WHEN** an animated subclass requests a region for (action, direction, frame) or a static subclass requests (sheet, index) or (sheet, row, col)
- **THEN** the base class (or shared logic) computes the correct Rect2 / region from the cached sheet and layout rules

### Requirement: Animated lookup returns texture region

The animated lookup SHALL resolve (entity, action, direction, frame) and optional type (diffuse or normal) to a texture that can be assigned to a Sprite2D (e.g. AtlasTexture with the correct region). Direction MAY be given as name ("N", "NE", …) or as row index 0–7. The system SHALL return a texture view (region) so the caller does not manage Rect2 manually.

#### Scenario: Get diffuse frame for animated sprite

- **WHEN** caller requests (entity, action, direction, frame) with type diffuse (or default)
- **THEN** the system returns a texture (e.g. AtlasTexture) that displays only the correct cell in the diffuse block for that action, direction, and frame

#### Scenario: Get normal frame for animated sprite

- **WHEN** caller requests (entity, action, direction, frame) with type normal
- **THEN** the system returns a texture that displays only the correct cell in the normal block for that action, direction, and frame

#### Scenario: Direction name resolves to row

- **WHEN** caller passes direction as string (e.g. "SE")
- **THEN** the system maps it to the canonical row index (e.g. "SE" → 3) and uses that row for region lookup

### Requirement: Static lookup by index or row and column

The static lookup SHALL resolve (sheet, index) or (sheet, row, column) to a texture that can be assigned to a Sprite2D. Linear index SHALL follow row-major order: index = row * columns + col. The system SHALL return a texture view (region) so the caller does not manage Rect2 manually.

#### Scenario: Get cell by linear index

- **WHEN** caller requests (sheet_id, index) for a static sheet
- **THEN** the system returns a texture that displays only the cell at the corresponding row-major position

#### Scenario: Get cell by row and column

- **WHEN** caller requests (sheet_id, row, col) for a static sheet
- **THEN** the system returns a texture that displays only the cell at that grid position

### Requirement: Frame count available for animated sheets

The system SHALL provide the frame count per action for a given entity so that animation logic (e.g. character update_sprite and timer) can use it instead of hardcoded values. Frame count SHALL be derived from sheet dimensions and layout or from optional metadata.

#### Scenario: Query frame count for action

- **WHEN** caller requests the number of frames for (entity, action)
- **THEN** the system returns the frame count (e.g. number of columns in the animated sheet for that action) from the loaded sheet or metadata

### Requirement: Animated and static use separate directories

When resolving paths to sheet files, the lookup SHALL use the configured animated-sheet root for animated sheets and the configured static-sheet root for static sheets, in accordance with the layout spec.

#### Scenario: Animated sheet path under animated root

- **WHEN** loading an animated sheet for entity E and action A
- **THEN** the file path is constructed from the animated-sheet root and does not use the static-sheet root

#### Scenario: Static sheet path under static root

- **WHEN** loading a static sheet by identifier
- **THEN** the file path is constructed from the static-sheet root and does not use the animated-sheet root
