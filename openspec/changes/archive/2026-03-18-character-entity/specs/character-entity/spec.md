# Spec: Character Entity

## ADDED Requirements

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

The character entity SHALL use the animated-entity base for sprite-sheet display, action, and direction. It SHALL NOT reimplement sprite-sheet resolution or frame-advance logic; that SHALL remain in the animated-entity. The character entity SHALL hold a reference to an AnimatedEntity instance (e.g. as a child node) and SHALL drive or allow driving of that instance’s action and direction so the correct frames are displayed.

#### Scenario: Display is delegated to animated-entity

- **WHEN** the character entity is composed with a child (or referenced) AnimatedEntity instance
- **THEN** the visible sprite and frame advance SHALL be determined by that AnimatedEntity; the character entity SHALL NOT duplicate texture lookup, timer-based frame advance, or playback mode logic

#### Scenario: Action and direction can be driven for the character

- **WHEN** the character entity or a caller sets the animated-entity child’s action or direction (e.g. idle vs walk, facing direction)
- **THEN** the displayed texture SHALL update according to the animated-entity’s lookup and current frame; the character entity SHALL expose or forward a way to set action and direction (e.g. by exposing the child reference or providing set_action/set_direction helpers)

### Requirement: Character attributes

The character entity SHALL expose and track character-specific attributes such as health and speed. It SHALL be structured so additional attributes can be added over the course of development without breaking existing character types. Attributes SHALL be readable and, where appropriate, writable (e.g. for gameplay systems to read or modify health). Initial attribute set SHALL include at least health (or equivalent) and speed (or equivalent) so that subclasses and game logic can use them.

#### Scenario: Core attributes are exposed

- **WHEN** a character entity is instantiated
- **THEN** it SHALL expose at least health (or current/max health) and speed (or movement speed) so that movement logic and game systems can read or set them (e.g. via exports or properties)

#### Scenario: New attributes can be added without breaking existing types

- **WHEN** a new character attribute is added to the character-entity implementation (e.g. stamina, armor)
- **THEN** existing character types (e.g. scenes or scripts that use or extend character entity) SHALL continue to work without requiring mandatory changes; new attributes MAY have defaults so existing scenes do not need to set them

### Requirement: Distinction from animated prop

The character entity SHALL represent a character in the game (moving, collidable entity with attributes) as distinct from an animated-entity used directly for environmental or prop animations (non-moving, no collision, no character attributes). Code or scenes that need “a character” (e.g. player, NPC) SHALL use the character-entity type (or a subclass); code or scenes that need only a decorative or environmental animation SHALL use the animated-entity base directly.

#### Scenario: Character entity is the type for in-world characters

- **WHEN** a game entity is intended to be a character (e.g. player, NPC) that moves and has attributes
- **THEN** that entity SHALL be implemented as or composed from the character-entity type (or a subclass of it), not as a bare animated-entity

#### Scenario: Animated-entity alone is for non-character animations

- **WHEN** a game entity is intended to be a non-moving environmental or prop animation (e.g. torch, door)
- **THEN** that entity SHALL use the animated-entity base directly and SHALL NOT be required to use the character-entity type
