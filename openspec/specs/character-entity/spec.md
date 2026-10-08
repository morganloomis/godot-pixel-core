# Spec: Character Entity

## Purpose

Define the requirements for a game character entity: a moving, collidable entity with gameplay attributes that delegates sprite-sheet display and animation to `AnimatedEntity`.

## Requirements

### Requirement: Moving and collidable

The character entity SHALL move about the scene and SHALL provide or require collision so it can interact with the world and other colliders. It SHALL use a physics body (e.g. CharacterBody2D) as the root or owner of movement. It SHALL have a collision shape (e.g. CollisionShape2D) so the physics engine can resolve collisions. Movement logic (who sets velocity, when) MAY be implemented in the character-entity script, in a subclass (e.g. player-character, NPC), or in external code; the character entity SHALL at minimum provide the body and collision so that movement can be applied.

#### Scenario: Character has a physics body

- **WHEN** a character entity is instantiated in the scene
- **THEN** it SHALL be backed by a physics body node (e.g. CharacterBody2D) so that velocity and move_and_slide (or equivalent) can be used to move it

#### Scenario: Character participates in collision

- **WHEN** a character entity is placed in the scene with collision layers and masks configured
- **THEN** it SHALL have a collision shape so it can collide with the world and other colliders; the shape SHALL be attached to or owned by the character entity’s physics body

#### Scenario: Character can move when velocity is set

- **WHEN** velocity is set on the character entity’s body (by the entity, a subclass, or external code) and the physics step runs
- **THEN** the character entity SHALL move according to the physics engine (e.g. move_and_slide); the displayed sprite (via animated-entity child) SHALL follow the body position

### Requirement: Display via animated-entity

The character entity SHALL use the addon’s **animated sprite presenter** (`AnimatedEntity` or renamed successor with the same responsibility) for sprite-sheet display, action, and direction. It SHALL NOT reimplement sprite-sheet resolution or frame-advance logic; that SHALL remain in the presenter. The character entity SHALL hold a reference to a presenter instance (e.g. as a child node) and SHALL drive or allow driving of that instance’s action and direction so the correct frames are displayed. **Pseudo-lighting** SHALL be configured on that presenter (e.g. via export) rather than by requiring a separate lit-only presenter subclass in packaged default scenes.

#### Scenario: Display is delegated to presenter

- **WHEN** the character entity is composed with a child (or referenced) presenter instance (`AnimatedEntity` or documented successor)
- **THEN** the visible sprite and frame advance SHALL be determined by that presenter; the character entity SHALL NOT duplicate texture lookup, timer-based frame advance, or playback mode logic

#### Scenario: Action and direction can be driven for the character

- **WHEN** the character entity or a caller sets the presenter child’s action or direction (e.g. idle vs walk, facing direction)
- **THEN** the displayed texture SHALL update according to the presenter’s lookup and current frame; the character entity SHALL expose or forward a way to set action and direction (e.g. by exposing the child reference or providing set_action/set_direction helpers)

#### Scenario: Lit mode without alternate presenter class

- **WHEN** a game author enables pseudo-lighting on the child presenter
- **THEN** the character entity SHALL NOT require swapping to a different presenter script class solely to obtain lit behavior in the addon’s standard packaged layout

### Requirement: Character attributes

The character entity SHALL expose and track character-specific attributes such as health and speed. It SHALL be structured so additional attributes can be added over the course of development without breaking existing character types. Attributes SHALL be readable and, where appropriate, writable (e.g. for gameplay systems to read or modify health). Initial attribute set SHALL include at least health (or equivalent) and speed (or equivalent) so that subclasses and game logic can use them.

#### Scenario: Core attributes are exposed

- **WHEN** a character entity is instantiated
- **THEN** it SHALL expose at least health (or current/max health) and speed (or movement speed) so that movement logic and game systems can read or set them (e.g. via exports or properties)

#### Scenario: New attributes can be added without breaking existing types

- **WHEN** a new character attribute is added to the character-entity implementation (e.g. stamina, armor)
- **THEN** existing character types (e.g. scenes or scripts that use or extend character entity) SHALL continue to work without requiring mandatory changes; new attributes MAY have defaults so existing scenes do not need to set them

### Requirement: Entity name on character root

The character entity SHALL expose an **editor-visible** export **entity_name** on the **character body root** that identifies the sprite set folder used with `AnimatedSpriteSheetLookup` (same semantics as the child presenter’s `entity_name`). The character entity SHALL forward that value to the child presenter so authors configure sprite pathing alongside health and speed without selecting the child node. The presenter SHALL continue to perform lookup; the character entity SHALL NOT reimplement path resolution.

#### Scenario: Inspector shows entity name on character

- **WHEN** a character entity (or subclass such as player entity) with the standard child presenter layout is selected in the editor
- **THEN** the inspector on the character root SHALL include an exported **entity_name** property alongside other character attributes

#### Scenario: Forwarded entity name drives lookup

- **WHEN** `entity_name` is set on the character entity root and the scene runs
- **THEN** the child presenter SHALL use that string as the lookup entity key when non-empty; when empty, the presenter’s documented fallback (e.g. node name) SHALL apply

### Requirement: Forwarded movement speed and animation framerate on character root

The character entity SHALL expose editor-visible forwarded exports for **movement speed** and **animation framerate** on the **character body root** that map to the child presenter’s `movement_speed` and `frame_rate`. Units and default semantics SHALL match the presenter (`AnimatedEntity`).

#### Scenario: Root tuning updates presenter

- **WHEN** a game author changes movement speed or animation framerate on the character root in the inspector
- **THEN** the child presenter’s corresponding properties SHALL update and runtime motion and animation timing SHALL behave as if those presenter exports were edited directly

#### Scenario: Single underlying state

- **WHEN** movement speed or framerate is read from the character root export after editing the child presenter directly
- **THEN** the read value SHALL match the presenter’s current value (no independent duplicate state on the character body)

### Requirement: Distinction from animated prop

The character entity SHALL represent a character in the game (moving, collidable entity with attributes) as distinct from an animated-entity used directly for environmental or prop animations (non-moving, no collision, no character attributes). Code or scenes that need “a character” (e.g. player, NPC) SHALL use the character-entity type (or a subclass); code or scenes that need only a decorative or environmental animation SHALL use the animated-entity base directly.

#### Scenario: Character entity is the type for in-world characters

- **WHEN** a game entity is intended to be a character (e.g. player, NPC) that moves and has attributes
- **THEN** that entity SHALL be implemented as or composed from the character-entity type (or a subclass of it), not as a bare animated-entity

#### Scenario: Animated-entity alone is for non-character animations

- **WHEN** a game entity is intended to be a non-moving environmental or prop animation (e.g. torch, door)
- **THEN** that entity SHALL use the animated-entity base directly and SHALL NOT be required to use the character-entity type

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

