## MODIFIED Requirements

### Requirement: Animated lookup returns texture region

The animated lookup SHALL resolve `(entity, action, direction, frame)` and a **pass** selector (`diffuse`, `normal`, `specular`, or `occlusion`) to a texture that can be assigned to a `Sprite2D` (e.g. `AtlasTexture` with the correct region), **or** SHALL indicate no texture when that pass file does not exist. Direction MAY be given as a canonical name (**S**, **SE**, **E**, **NE**, **N**, **NW**, **W**, **SW**) or as row index 0–7 per `sprite-sheet-facing`. The system SHALL return a texture view (region) so the caller does not manage `Rect2` manually when the pass exists.

#### Scenario: Get diffuse frame for animated sprite

- **WHEN** caller requests diffuse for `(entity, action, direction, frame)` and `diffuse.png` exists
- **THEN** the system returns a texture that displays only the correct cell for that action, direction, and frame

#### Scenario: Get normal frame when normal pass exists

- **WHEN** caller requests normal for the same indices and `normal.png` exists
- **THEN** the system returns a texture for the same logical cell from the normal pass file

#### Scenario: Missing optional pass

- **WHEN** caller requests a pass whose file does not exist (e.g. `specular.png` absent)
- **THEN** the system SHALL NOT load that file and SHALL return a documented null/empty result without error

#### Scenario: Direction name resolves to row

- **WHEN** caller passes direction as string (e.g. "SE")
- **THEN** the system maps it to the canonical row index per `sprite-sheet-facing` and uses that row for region lookup

### Requirement: Frame count available for animated sheets

The system SHALL provide the frame count per action for a given entity so that animation logic can use it instead of hardcoded values. Frame count SHALL be derived from **`diffuse.png`** dimensions and layout (columns = width / cell width) or from optional metadata. If `diffuse.png` is missing, frame count SHALL be zero or a documented sentinel and that action SHALL not animate.

#### Scenario: Query frame count for action

- **WHEN** caller requests the number of frames for `(entity, action)` and `diffuse.png` exists
- **THEN** the system returns the column count implied by the diffuse grid

#### Scenario: No diffuse file

- **WHEN** `diffuse.png` is absent for `(entity, action)`
- **THEN** frame count is zero (or documented equivalent) and lookup does not invent frames from other passes alone

### Requirement: Animated and static use separate directories

When resolving paths to sheet files, the lookup SHALL use the configured animated-sheet root for animated passes and the configured static-sheet root for static sheets, in accordance with the layout spec. Animated resolution SHALL use `{root}/{entity}/{action}/{pass}.png`.

#### Scenario: Animated pass path under animated root

- **WHEN** loading diffuse for entity E and action A
- **THEN** the file path is under the animated-sheet root as `E/A/diffuse.png` and does not use the static-sheet root

#### Scenario: Static sheet path under static root

- **WHEN** loading a static sheet by identifier
- **THEN** the file path is constructed from the static-sheet root and does not use the animated entity/action pass pattern

### Requirement: Base class owns lookup and caching

A base class SHALL own the logic for loading sheet textures, resolving regions from layout rules, and caching loaded sheets. It SHALL be the single place where layout conventions (animated vs static) are applied to produce texture regions. Subclasses SHALL represent animated vs static behaviour and expose only the API appropriate to each layout type. Cache keys SHALL distinguish **per-pass file paths** so diffuse, normal, and other passes do not collide.

#### Scenario: Base class loads and caches sheet

- **WHEN** a pass file is requested by path for the first time
- **THEN** the base class loads the texture, caches it by a key that includes that path, and subsequent requests reuse the cached texture

#### Scenario: Subclasses delegate region resolution to base

- **WHEN** an animated subclass requests a region for (action, direction, frame) for a given pass
- **THEN** the base class (or shared logic) computes the correct `Rect2` / region from the cached sheet for that pass and layout rules
