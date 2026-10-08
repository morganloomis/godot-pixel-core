# Spec: Animated Entity

## ADDED Requirements

### Requirement: Non-moving, single-row use (direct use)

When used directly (not as a base for a character or other moving entity), the animated-entity base SHALL represent **non-moving** environmental or decorative animations (e.g. door animation, burning torch on a wall). Such entities SHALL NOT move under their own logic and SHALL NOT have a gameplay direction. The sprite sheet SHALL be one sheet per action with **one row only** (a single row of frames for that action). Direction is not applicable for this use; subclasses (e.g. character entity) that move and face a direction SHALL introduce direction and multi-row or directional lookup separately.

#### Scenario: Direct use has no movement

- **WHEN** the animated-entity base is used directly (e.g. for a door or torch)
- **THEN** the base SHALL NOT implement or assume movement; the node SHALL remain at its placed position unless moved by external code or parent

#### Scenario: Single-row sprite sheet per action

- **WHEN** the animated entity is used for a single-row action (e.g. torch flicker, door open)
- **THEN** the lookup SHALL resolve the current frame from a single row for that action (direction ignored or fixed); the base SHALL support lookups that provide textures by entity, action, and frame with one row per action

### Requirement: Sprite-sheet–driven display

The animated-entity base SHALL use a sprite-sheet lookup to resolve the current frame and SHALL display it on a single child sprite (e.g. Sprite2D). The base SHALL apply the lookup result to the sprite’s texture whenever entity id, action, direction (if used), or frame changes. For single-row usage, the lookup may ignore direction or use a fixed row; for subclasses that use directional lookups, direction SHALL affect the resolved texture.

#### Scenario: Texture updates when state changes

- **WHEN** entity id, action, direction (if applicable), or frame is set to a new value and the lookup returns a valid atlas texture for that combination
- **THEN** the displayed sprite’s texture SHALL be the atlas texture returned by the lookup

#### Scenario: Default lookup type

- **WHEN** the base is instantiated without a custom lookup
- **THEN** it SHALL use a lookup capable of resolving textures (e.g. AnimatedSpriteSheetLookup or a single-row equivalent) to resolve textures

### Requirement: Configurable animation state

The base SHALL expose configurable entity id and action (state). Entity id SHALL be configurable (e.g. exported) with an optional default (e.g. node name). Action SHALL be readable and writable. Direction SHALL be optional: when the base is used for single-row animations (direct use), direction is not used by the lookup; when used by a subclass (e.g. character entity) that provides a directional lookup, direction SHALL be readable and writable. The current frame MAY be internal but SHALL be readable for debugging or sync.

#### Scenario: Entity id can be set per instance

- **WHEN** multiple instances of the base (or a subclass) are in the scene with different entity ids
- **THEN** each instance SHALL resolve textures using its own entity id

#### Scenario: Action drives displayed frame

- **WHEN** action is changed
- **THEN** the next texture applied to the sprite SHALL correspond to the new action (and current frame, and direction if applicable)

### Requirement: Configurable frame rate with default

The base SHALL support a configurable frame rate for advancing animation frames. The default frame rate SHALL be 12 fps. The frame rate SHALL be overridable (e.g. via export or setter) so different entity types can use different animation speeds.

#### Scenario: Default frame rate

- **WHEN** the base is instantiated and frame rate is not set
- **THEN** animation SHALL advance at 12 frames per second

#### Scenario: Override frame rate

- **WHEN** frame rate is set to a different value (e.g. 6 fps)
- **THEN** the timer or step interval SHALL be updated so frames advance at the new rate

### Requirement: Timer-based frame advance

The base SHALL advance the current frame using a timer (or equivalent). When the timer fires, the base SHALL increment the frame index according to the current action’s playback mode (see Requirement: Animation clip playback modes). After updating the frame, the base SHALL refresh the sprite texture. For Loop mode, the frame SHALL wrap to 0 when at the last frame; for Play once or Hold last frame, the base SHALL not advance past the last frame.

#### Scenario: Frame wraps at action frame count (Loop mode)

- **WHEN** the timer fires and the current action’s playback mode is Loop and the current frame is the last frame for that action (e.g. frame 5 of 6)
- **THEN** the next frame SHALL be 0 (or the first frame) and the sprite SHALL show the first frame texture

#### Scenario: Single-frame action does not animate

- **WHEN** the lookup reports frame count 1 for the current entity and action
- **THEN** the displayed frame SHALL remain 0 and the timer SHALL not change the visible texture

### Requirement: Animation clip playback modes

The base SHALL support at least three playback modes for animation clips: **Loop**, **Play once**, and **Hold last frame**. The mode SHALL be configurable per action (e.g. by action name); the default SHALL be Loop. **Loop**: the clip SHALL repeat (frame wraps to 0 after the last frame) and SHALL continue until the action is changed. **Play once**: the clip SHALL run from first to last frame exactly once; when the last frame is reached, the base SHALL stop advancing and SHALL emit a signal (e.g. animation_finished) so callers can switch action or state. **Hold last frame**: the clip SHALL run from first to last frame exactly once; when the last frame is reached, the base SHALL stop advancing and SHALL remain on the last frame (e.g. for death poses).

#### Scenario: Looping clip continues until action changes

- **WHEN** the current action has playback mode Loop and the entity remains in that action
- **THEN** the animation SHALL repeatedly cycle through frames (wrapping from last to first) and SHALL be interruptible by changing the action

#### Scenario: Play once runs to end then notifies

- **WHEN** the current action has playback mode Play once and the timer advances to the last frame
- **THEN** the base SHALL stop advancing the frame, SHALL remain on the last frame, and SHALL emit a signal indicating the clip finished (e.g. animation_finished with the action name) so the caller can set a new action

#### Scenario: Hold last frame plays then stays on final frame

- **WHEN** the current action has playback mode Hold last frame and the timer advances to the last frame
- **THEN** the base SHALL stop advancing the frame and SHALL keep displaying the last frame (e.g. death pose) until the action is changed

### Requirement: Placeable in scene; movement only via subclasses

The base SHALL be a node that can be placed in a scene at a position. When used directly (doors, torches, etc.), the base SHALL NOT move—it SHALL remain at its placed position. Position (and velocity, if the node type supports it) SHALL be the responsibility of the node or its parent; the base SHALL NOT implement movement. Subclasses (e.g. character entity) that move SHALL implement movement and input/physics themselves. The base SHALL NOT assume a specific body type (e.g. CharacterBody2D); subclasses MAY use Node2D, CharacterBody2D, RigidBody2D, or other types.

#### Scenario: Base can be added to scene tree

- **WHEN** an instance of the base (or a subclass) is added to the scene tree with a valid position
- **THEN** the node SHALL be visible at that position and SHALL display the current animation frame

#### Scenario: No movement in base

- **WHEN** the spec is implemented
- **THEN** the base class SHALL NOT implement or require input handling, move_and_slide, or physics body behavior; such behavior SHALL be provided by subclasses (e.g. character entity) or composition

### Requirement: Substitute lookup for tests or variants

The base SHALL allow the sprite-sheet lookup to be created in _ready() or supplied (injected/overridden) so that tests or subclasses can substitute a different lookup. For single-row use (direct animated entity), the lookup SHALL provide textures by entity, action, and frame (direction ignored or fixed). For directional use (e.g. character entity subclass), the lookup MAY take direction. The base SHALL NOT mandate a single lookup API beyond what is required for the chosen use.

#### Scenario: Subclass uses different lookup type

- **WHEN** a subclass or user overrides or injects a different lookup implementation (e.g. single-row lookup for doors/torches, or directional lookup for character)
- **THEN** the base SHALL use that lookup to resolve textures for the current entity, action, and frame (and direction when the lookup supports it)
