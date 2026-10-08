# Spec: Sprite presentation

## Purpose

Define how the animated sprite presenter is structured (node shape, exports, engine 2D lighting vs unlit, reuse under different body types) and how it relates to tiles versus scene props.

## Requirements

### Requirement: Presenter node shape

The animated sprite presenter SHALL be implemented as a **`Node2D` root** with a **child `Sprite2D`** used as the drawable (and MAY include a `Timer` or equivalent for frame stepping). The presenter script SHALL NOT be required to `extend Sprite2D` for conformance with this spec.

#### Scenario: Drawable is child Sprite2D

- **WHEN** the presenter updates the visible texture for the current action, direction, and frame
- **THEN** it SHALL assign the resolved texture to the child `Sprite2D` (or equivalent documented child path), not assume the script is attached to `Sprite2D`

---

### Requirement: Shared presentation properties

The presenter SHALL expose **animation framerate** and **movement speed** (when used by character motion) in a single place consistent with `animated-entity-speed`. It SHALL expose an exported **lit mode** flag (or equivalent export name) so consumers enable **engine 2D normal-mapped lighting** vs unlit without changing presenter class.

#### Scenario: Inspector exposes framerate and lit mode

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include exported properties for animation framerate and for enabling lit mode (names MAY match implementation but behavior SHALL match this spec)

---

### Requirement: Presenter exports sprite set identifier

The presenter (`AnimatedEntity` or successor) SHALL expose an exported string **entity_name** that selects the **entity folder name** under the configured animated sheet root for texture paths (e.g. `res://…/sprite/…/<entity_name>/<action>/diffuse.png`). If empty, the presenter SHALL fall back to a documented rule (e.g. the presenter node’s name).

#### Scenario: Presenter inspector shows entity name

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include an exported **entity_name** property documented as the sprite set / folder id for lookup

---

### Requirement: Presenter exposes target direction API

The animated sprite presenter (`AnimatedEntity` or documented successor) SHALL expose `set_direction(new_direction: String)` for gameplay and body scripts to request a **target** facing. Assigning the `direction` property SHALL delegate to the same transition logic as `set_direction` at runtime. The `direction` property getter SHALL return the **displayed** facing used for texture lookup and rendering, which MAY lag behind the latest target during multi-step transitions.

#### Scenario: Body requests target via set_direction

- **WHEN** a parent body calls `set_direction("NW")` on the presenter at runtime
- **THEN** the presenter SHALL treat **NW** as the target facing and SHALL update the displayed facing according to `animated-direction-transition` rules

#### Scenario: direction getter reflects on-screen facing

- **WHEN** a multi-step transition is in progress and the displayed facing is **S** while the target facing is **E**
- **THEN** reading `direction` SHALL return **S** until the transition advances the displayed facing

#### Scenario: Editor assigns facing without multi-frame transition

- **WHEN** `set_direction` or the `direction` setter is used in the editor (`Engine.is_editor_hint()`)
- **THEN** the presenter MAY snap displayed and target facings immediately so inspector preview stays responsive

---

### Requirement: Sprite lookup uses displayed facing during transitions

`update_sprite()` and lit-mode normal alignment SHALL use the **displayed** facing (not the in-flight target) when resolving `get_texture` for the current action and frame. Each transition step SHALL trigger a sprite refresh so diffuse and normal data match the displayed row.

#### Scenario: Texture follows displayed row mid-transition

- **WHEN** a transition is active, lit mode is enabled, and the displayed facing advances from **W** to **SW** on a timer tick
- **THEN** the child `Sprite2D` SHALL show the **SW** row for the current action and frame and normals SHALL stay aligned with that diffuse row when `normal.png` exists

---

### Requirement: Engine-lit presenter behavior

When lit mode is enabled, the presenter SHALL configure the child **`Sprite2D`** for **Godot 2D lighting** using the addon's **`ShaderMaterial`** (`iso_lit.gdshader`) per `sprite-engine-2d-lighting`. Diffuse for the current entity, action, **displayed** direction, and frame SHALL remain on **`Sprite2D.texture`**; the remaining passes SHALL be bound as **whole sheets** with the active cell selected by a **region uniform**, so no per-cell texture is baked at runtime. Absent passes SHALL bind documented fallbacks. The presenter SHALL **not** register materials with a legacy autoload for uniform fan-out; project-wide values SHALL be **global shader parameters**.

Optional **`specular.png`**, **`emissive.png`**, **`occlusion.png`** and **`height.png`** SHALL be bound when present. **`height.png`** SHALL supply per-pixel height so the drawable can report each fragment's ground position to the engine's light math.

#### Scenario: Per-frame cost is a region write

- **WHEN** lit mode is enabled and only the frame advances within one action
- **THEN** the presenter SHALL update the cell region **AND** SHALL NOT rebind pass sheets or construct per-cell textures

#### Scenario: Normal follows diffuse under engine lighting

- **WHEN** the presenter advances frame or changes action or **displayed** direction while lit mode is enabled
- **THEN** the normal map data configured for the child `Sprite2D` SHALL stay aligned with the diffuse for that frame when `normal.png` exists, or SHALL use the documented fallback when it does not

#### Scenario: Lit mode during direction transition

- **WHEN** lit mode is enabled and the presenter steps the displayed facing along a multi-step transition
- **THEN** each step SHALL update diffuse and normal data for the new displayed row before the next timer tick

---

### Requirement: Non-character reuse

The same presenter scene or script type SHALL be usable as a child of `CharacterBody2D`, `StaticBody2D`, `Area2D`, `RigidBody2D`, or plain `Node2D` without requiring a character-specific subclass of the presenter for basic display.

#### Scenario: Static prop uses presenter

- **WHEN** a game author instances a `StaticBody2D` with a presenter child for a static lit prop
- **THEN** they SHALL use the same presenter type as for a character’s visual child without forking the presenter script

---

### Requirement: Tile map integration is non-hierarchical

`TileMapLayer` authoring SHALL remain independent of the presenter scene tree: games are NOT required to attach the presenter script to individual tile cells to use the same **sprite sheet layout and lookup types** for tiles. Addon documentation SHALL describe recommended patterns for per-instance **engine-lit** animated props (body + presenter) versus bulk tiled map content.

#### Scenario: Tile versus scene prop guidance exists

- **WHEN** a consumer reads addon documentation for map content
- **THEN** it SHALL describe that per-instance lit animated props are typically scene instances (body + presenter), while bulk grid content uses `TileMapLayer`, and that both MAY share lookup conventions

---

### Requirement: Preset scenes do not re-instance the inherited presenter

When the addon ships a preset scene that **inherits from** or **instances** `character_entity.tscn` or `player_entity.tscn`, the preset SHALL configure the inherited child `AnimatedEntity` via **property overrides only** (e.g. `entity_name`, `use_2d_normal_lighting`, `movement_speed`, `frame_rate`). The preset SHALL NOT add a second `[node ... instance=ExtResource("animated_entity.tscn")]` block, whether under the same name (`AnimatedEntity`), a scoped name (e.g. `player#AnimatedEntity`), or another name with `parent="."` and `index="0"`. This rule keeps the canonical presenter child the single source of truth for sprite lookup, lit mode, and tuning on preset scenes.

#### Scenario: Preset edits inherited child via overrides

- **WHEN** an addon preset (such as `entity/characters/player.tscn`) is opened in Godot 4.6
- **THEN** the scene tree SHALL show exactly **one** `AnimatedEntity` child under the inherited body, and any custom values (e.g. tuned `entity_name`, `use_2d_normal_lighting`, framerate, movement speed) SHALL be set as overrides on that inherited node rather than on a fresh re-instance

#### Scenario: Preset CollisionShape is also an override

- **WHEN** a preset wants to tune the inherited `CollisionShape2D` (different shape, rotation, or offset)
- **THEN** the preset SHALL override properties on the inherited collision child or add a clearly distinct named collider, but SHALL NOT re-instance `animated_entity.tscn` to satisfy collision tuning

#### Scenario: Removing the preset is not required

- **WHEN** the addon decides not to ship a tuned preset
- **THEN** consumers SHALL be able to use `player_entity.tscn` directly and set overrides on their own instance; this requirement does not mandate that a preset must exist, only that any preset that does exist obeys the rule above
