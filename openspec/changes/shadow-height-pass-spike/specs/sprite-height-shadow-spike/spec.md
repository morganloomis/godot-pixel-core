# Spec Delta: sprite-height-shadow-spike

Experimental, default-off ground shadows from an optional `shadow.png` height/contact pass and a directional smear shader on a separate child `Sprite2D`. Provisional — may be removed or merged into `sprite-shadows`.

## ADDED Requirements

### Requirement: Shadow pass file layout

For each animated action folder at `{animated_sheet_root}/{entity}/{action}/`, an **optional** shadow height map MAY exist at `{animated_sheet_root}/{entity}/{action}/shadow.png`. When present, the image SHALL share the **same pixel width, height, cell width, cell height, and 8 × frame_count grid** as `diffuse.png` for that action, per `sprite-sheet-layout`.

#### Scenario: Shadow path resolves under per-pass folder

- **WHEN** the lookup resolves action `"walk"` for entity `"player"` and `res://.../player/walk/shadow.png` exists
- **THEN** the shadow resolver SHALL load that path as the source for shadow regions for that action

#### Scenario: Missing shadow file disables shadow for that action

- **WHEN** `shadow.png` does not exist for a given `(entity, action)`
- **THEN** the shadow resolver SHALL report no shadow atlas for that action AND the addon SHALL NOT treat this as an error

#### Scenario: Shadow size mismatch is a debug-only warning

- **WHEN** `shadow.png` exists but its pixel dimensions do not match `diffuse.png`
- **THEN** in debug builds the addon SHALL emit `push_warning` (mirroring existing optional-pass size mismatch behavior) AND SHALL still compute regions against `diffuse.png` dimensions

---

### Requirement: Shadow sample semantics

The shadow pass SHALL encode **ground contact / height-from-ground** in character sprite space: **higher** luminance SHALL mean **stronger** ground contact (e.g. planted feet), and **lower** luminance SHALL mean **weaker** contact or greater height above the ground (e.g. lifted foot, torso, head). The shader SHALL derive a scalar **contact strength** from luminance (documented channel or RGB luminance weights).

#### Scenario: Feet encode as high contact

- **WHEN** a texel represents a planted foot in artist-authored `shadow.png`
- **THEN** its sampled contact strength SHALL be near 1.0 relative to the pass encoding documented in the addon README

#### Scenario: Lifted limb encodes as low contact

- **WHEN** a texel represents a body part with no ground contact
- **THEN** its sampled contact strength SHALL be near 0.0 relative to the documented encoding

---

### Requirement: Shadow pass lookup via SpriteSheetPass

`SpriteSheetLookupBase.SpriteSheetPass` SHALL include a value `SHADOW` mapped to filename `shadow.png` in `animated_pass_texture_path`, following the same `{root}/{entity}/{action}/{pass}.png` rule as other passes. `AnimatedSpriteSheetLookup.get_texture(entity, action, direction, frame, SpriteSheetLookupBase.SpriteSheetPass.SHADOW)` SHALL return an `AtlasTexture` for the same logical cell as the diffuse pass when `shadow.png` exists.

#### Scenario: Atlas region matches diffuse grid math

- **WHEN** `shadow.png` for `(entity, action)` matches diffuse dimensions and grid
- **THEN** cell `(direction_index, frame_index)` SHALL map to the identical logical cell as the diffuse pass, computed by `compute_rect_animated` exactly as for normals

#### Scenario: Missing pass returns empty result

- **WHEN** caller requests `SpriteSheetPass.SHADOW` and `shadow.png` is absent
- **THEN** the lookup SHALL return a documented null/empty `AtlasTexture` without error, consistent with other optional passes

---

### Requirement: Frame and direction synchronization

Whenever `AnimatedEntity.update_sprite()` refreshes the diffuse region for `(entity, action, direction, frame)`, the shadow region for the **same** indices SHALL be resolved in the **same** call when `use_ground_shadow` is enabled, so diffuse and shadow cannot desynchronize.

#### Scenario: Walk frame advance keeps shadow aligned

- **WHEN** the `AnimatedEntity` advances from frame `n` to frame `n+1` for the current action and direction with `use_ground_shadow = true`
- **THEN** the shadow child's bound atlas region SHALL update to cell `(direction, n+1)` matching the diffuse cell

#### Scenario: Lit mode is not a prerequisite

- **WHEN** the presenter has `use_2d_normal_lighting = false` but `use_ground_shadow = true`
- **THEN** shadow lookup and refresh SHALL still run on each `update_sprite()` call; ground shadow is orthogonal to lit mode

---

### Requirement: Ground shadow is opt-in and default-off

`AnimatedEntity` SHALL expose `@export var use_ground_shadow: bool` defaulting to **`false`**. When `false`, the addon SHALL NOT create visible shadow output, SHALL NOT require `shadow.png`, and SHALL NOT alter lit or unlit body sprite behavior.

#### Scenario: Default presenter unchanged

- **WHEN** an `AnimatedEntity` is instantiated without overriding `use_ground_shadow`
- **THEN** `use_ground_shadow` SHALL be `false` AND the scene tree SHALL behave as before this change (no visible ground shadow)

#### Scenario: Enabling shadow requires explicit opt-in

- **WHEN** a project sets `use_ground_shadow = true` on an `AnimatedEntity`
- **THEN** the addon SHALL activate the shadow child and shadow shader path for that instance only

---

### Requirement: Shadow renders on a separate unshaded child Sprite2D

The ground-shadow visual SHALL be drawn by a **dedicated child** `Sprite2D` on `AnimatedEntity`, placed **before** the body `Sprite2D` in draw order with `z_index` lower than the body sprite. The shadow child SHALL bind the shadow-pass `AtlasTexture` to a `ShaderMaterial` using `addons/godot-pixel-core/lighting/shadow_height_project.gdshader` (or the path documented in tasks). The body `Sprite2D` material and `CanvasTexture` lit path SHALL remain unchanged.

#### Scenario: Body sprite material untouched

- **WHEN** `use_ground_shadow = true` and `use_2d_normal_lighting = true` on the same presenter
- **THEN** the body `Sprite2D` SHALL still use its `CanvasTexture` / `CanvasItemMaterial` lit setup AND the shadow child SHALL use the separate shadow `ShaderMaterial`

#### Scenario: Shadow hidden when pass missing

- **WHEN** `use_ground_shadow = true` but `shadow.png` is absent for the current action
- **THEN** the shadow child SHALL be hidden or draw fully transparent AND the body sprite SHALL still render normally

---

### Requirement: Directional smear along light axis

The shadow shader SHALL receive normalized 2D uniforms `smear_dir` and `shadow_length_scale` in sprite UV space. The default implementation SHALL sample the shadow pass along `UV + k * smear_dir * step` for a fixed tap count (documented in design, e.g. 8), combining samples with documented falloff weights. Sample contribution SHALL scale so high-contact (foot) regions smear less than low-contact (elevated body) regions. Out-of-region UV taps SHALL contribute zero.

#### Scenario: Bounded per-fragment cost

- **WHEN** the shadow shader runs for a fragment
- **THEN** texture sample count SHALL be the fixed tap budget plus a constant number of helper samples, with no dependency on scene light count

#### Scenario: UV clamp at atlas cell edges

- **WHEN** a tap UV exits the current `AtlasTexture` region
- **THEN** the shader SHALL treat that sample as zero contact so shadow does not bleed into neighbouring atlas cells

---

### Requirement: Light direction from DirectionalLight2D or override

`AnimatedEntity` SHALL expose `@export var shadow_light: NodePath` (optional) and `@export var shadow_direction_override: Vector2`. When `shadow_direction_override` is non-zero, it SHALL drive `smear_dir`. Otherwise, when `shadow_light` resolves to a `DirectionalLight2D`, the addon SHALL derive `smear_dir` from that light's rotation on the canvas plane (shadow extends opposite incoming light). The implementation SHALL NOT require the legacy `SpriteLighting` autoload.

#### Scenario: Manual override takes precedence

- **WHEN** `shadow_direction_override` is set to a non-zero vector
- **THEN** that vector SHALL be normalized and used as `smear_dir` regardless of any scene light

#### Scenario: Scene directional drives smear when override unset

- **WHEN** `shadow_light` points to a `DirectionalLight2D` and `shadow_direction_override` is zero
- **THEN** rotating that light SHALL change the shadow child's `smear_dir` uniform so shadow direction updates without code changes

---

### Requirement: Spike code is removable

Shadow spike logic SHALL be bounded to: `SpriteSheetPass.SHADOW`, `shadow.png` path mapping, shadow child wiring in `AnimatedEntity`, `shadow_height_project.gdshader`, and documented README notes. No consumer preset (`player_entity.tscn`, `entity/characters/player.tscn`) SHALL enable `use_ground_shadow` by default in this change.

#### Scenario: Consumer presets stay shadow-neutral

- **WHEN** `addons/godot-pixel-core/entity/player_entity.tscn` or `entity/characters/player.tscn` is inspected after this change
- **THEN** inherited `AnimatedEntity` SHALL NOT have `use_ground_shadow = true` unless explicitly changed in a future change
