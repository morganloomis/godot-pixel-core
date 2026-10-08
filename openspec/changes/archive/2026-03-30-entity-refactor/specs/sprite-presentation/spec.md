# Spec delta: sprite-presentation (change: entity-refactor)

## ADDED Requirements

### Requirement: Presenter node shape

The animated sprite presenter SHALL be implemented as a **`Node2D` root** with a **child `Sprite2D`** used as the drawable (and MAY include a `Timer` or equivalent for frame stepping). The presenter script SHALL NOT be required to `extend Sprite2D` for conformance with this spec.

#### Scenario: Drawable is child Sprite2D

- **WHEN** the presenter updates the visible texture for the current action, direction, and frame
- **THEN** it SHALL assign the resolved texture to the child `Sprite2D` (or equivalent documented child path), not assume the script is attached to `Sprite2D`

---

### Requirement: Shared presentation properties

The presenter SHALL expose **animation framerate** and **movement speed** (when used by character motion) in a single place consistent with `animated-entity-speed`. It SHALL expose a **pseudo-lighting** enable flag (or equivalent export) so consumers configure lit vs unlit without changing presenter class.

#### Scenario: Inspector exposes framerate and lighting mode

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include exported properties for animation framerate and for enabling pseudo-lighting (names MAY match implementation but behavior SHALL match this spec)

---

### Requirement: Presenter exports sprite set identifier

The presenter (`AnimatedEntity` or successor) SHALL expose an exported string **entity_name** that selects the folder name under the configured animated sheet root for texture paths (e.g. `res://sprite/animated/<entity_name>/<action>.png`). If empty, the presenter SHALL fall back to a documented rule (e.g. the presenter node’s name).

#### Scenario: Presenter inspector shows entity name

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include an exported **entity_name** property documented as the sprite set / folder id for lookup

---

### Requirement: Pseudo-lit material behavior

When pseudo-lighting is enabled, the presenter SHALL duplicate the preset lit material resource, assign it to the child `Sprite2D`, set texture filter appropriate for pixel art (nearest), and each time the diffuse texture is updated the presenter SHALL set the shader **normal_map** parameter from the lookup’s normal atlas for the same entity, action, direction, and frame.

#### Scenario: Normal follows diffuse

- **WHEN** the presenter advances frame or changes action or direction while pseudo-lighting is enabled
- **THEN** the normal map parameter SHALL stay aligned with the diffuse `Sprite2D.texture` for that frame

---

### Requirement: Non-character reuse

The same presenter scene or script type SHALL be usable as a child of `CharacterBody2D`, `StaticBody2D`, `Area2D`, `RigidBody2D`, or plain `Node2D` without requiring a character-specific subclass of the presenter for basic display.

#### Scenario: Static prop uses presenter

- **WHEN** a game author instances a `StaticBody2D` with a presenter child for a static lit prop
- **THEN** they SHALL use the same presenter type as for a character’s visual child without forking the presenter script

---

### Requirement: Tile map integration is non-hierarchical

`TileMapLayer` authoring SHALL remain independent of the presenter scene tree: games are NOT required to attach the presenter script to individual tile cells to use the same **sprite sheet layout and lookup types** for tiles. Addon documentation SHALL describe recommended patterns for per-instance lit props (body + presenter) versus bulk tiled map content.

#### Scenario: Tile versus scene prop guidance exists

- **WHEN** a consumer reads addon documentation for map content
- **THEN** it SHALL describe that per-instance pseudo-lit animated props are typically scene instances (body + presenter), while bulk grid content uses `TileMapLayer`, and that both MAY share lookup conventions
