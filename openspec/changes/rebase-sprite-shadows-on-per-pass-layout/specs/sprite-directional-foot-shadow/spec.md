# Spec Delta: sprite-directional-foot-shadow

## MODIFIED Requirements

### Requirement: Foot shadow renders from contact pass on a separate CanvasItem

The foot-shadow visual SHALL be drawn by a **dedicated child** `CanvasItem` (e.g. a `Sprite2D` or `MeshInstance2D`) placed under the character body and **behind** the presenter sprite in draw order (lower `z_index` or a dedicated `CanvasLayer` for ground decals). The shadow CanvasItem SHALL bind the `AtlasTexture` returned by `AnimatedSpriteSheetLookup.get_texture(..., SpriteSheetLookupBase.SpriteSheetPass.CONTACT)` to a `ShaderMaterial` parameter and refresh it whenever the parent `AnimatedEntity` calls `update_sprite()`. The shadow material SHALL NOT be applied to the character `Sprite2D` itself, so engine-2D-lit rendering of the body is unaffected.

#### Scenario: Shadow node is a sibling, not a material on the sprite

- **WHEN** a character entity opts into foot shadows
- **THEN** the addon SHALL ship (or document) a small scene composing a foot-shadow `CanvasItem` parented next to the inherited `AnimatedEntity` such that the body `Sprite2D` keeps its `CanvasTexture` (lit) or `AtlasTexture` (unlit) material unchanged

#### Scenario: Refresh follows update_sprite

- **WHEN** `AnimatedEntity.update_sprite()` runs for a given `(entity, action, direction, frame)`
- **THEN** the foot-shadow child's bound contact `AtlasTexture` SHALL be the result of the lookup call for the same indices on the same frame, with no intervening visible draw between the diffuse and contact updates

---

### Requirement: Light direction projects to ground-plane smear axis

The foot-shadow shader SHALL receive a normalized 2D `smear_dir` uniform expressed in **canvas / sprite UV space**. The recommended source for that vector is the project's primary `DirectionalLight2D` rotation projected onto the ground plane and converted to canvas space; the implementation MAY also expose a manual override export on the foot-shadow node (e.g. `shadow_direction: Vector2`) so projects with multiple lights or a stylized art direction can author it directly. The shader SHALL NOT require the legacy `SpriteLighting` autoload; the default lit path is `sprite-engine-2d-lighting`.

#### Scenario: Default smear from scene directional light

- **WHEN** a project uses a single `DirectionalLight2D` and enables foot shadows on a character
- **THEN** the addon SHALL provide (or document) how that light's rotation becomes the foot-shadow `smear_dir` so authors do not need to handcraft the vector

#### Scenario: Manual override is available

- **WHEN** a project sets an explicit `shadow_direction` on the foot-shadow node (or equivalent API)
- **THEN** that vector SHALL drive the shader uniform instead of any scene-light-derived value, without requiring code changes to the addon

#### Scenario: No dependency on SpriteLighting autoload

- **WHEN** a project runs the default lit path (`AnimatedEntity.use_2d_normal_lighting = true`) without any `[autoload]` entry for legacy pseudo-lighting
- **THEN** foot shadows SHALL still work; the addon SHALL NOT require enabling `lighting/legacy/sprite_lighting.gd` to obtain a `smear_dir`

---

### Requirement: Smear implementation taps fixed in the fragment shader

The default foot-shadow shader SHALL sample the bound contact `AtlasTexture` at `UV + k * smear_dir * step` for `k` in a small fixed range (e.g. 5–9 taps), combined with a documented falloff (Gaussian or exponential weights). The shader SHALL NOT depend on a separate `Viewport` or render target for the default path. Implementations MAY add an opt-in higher-quality path (e.g. a half-res `SubViewport` for a separable blur) in a later change without breaking this baseline contract.

#### Scenario: Bounded cost per pixel

- **WHEN** the shader runs for a given fragment
- **THEN** texture sample count SHALL be the fixed tap budget plus a constant number of helper samples; cost SHALL be **O(taps)** with no dependency on scene light count

#### Scenario: UV clamp at cell edges

- **WHEN** a tap `UV + k * smear_dir * step` exits the current `AtlasTexture` region
- **THEN** the shader SHALL clamp or treat out-of-region samples as zero contact so the shadow does not bleed into neighbouring cells of the atlas

---

### Requirement: Multiple lights default policy

When more than one `DirectionalLight2D` is present, the default foot-shadow path SHALL use the **primary** light (documented selection rule: highest energy, then first in tree order) for `smear_dir` and intensity. The shader SHALL NOT fuse per-pixel shadows from multiple directional lights in the default path; projects requiring that SHALL author additional foot-shadow nodes per light or extend the addon in a later change.

#### Scenario: One contact, one primary direction

- **WHEN** two `DirectionalLight2D` nodes share the scene
- **THEN** the foot shadow SHALL use the primary light per the documented rule; the second light SHALL not contribute to `smear_dir` in the default path
