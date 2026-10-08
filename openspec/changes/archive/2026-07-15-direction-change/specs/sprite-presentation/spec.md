## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Engine-lit presenter behavior

When lit mode is enabled, the presenter SHALL configure the child **`Sprite2D`** for **Godot 2D lighting**: diffuse data for the current entity, action, **displayed** direction, and frame SHALL come from **`diffuse.png`** via lookup; normal data SHALL come from **`normal.png`** when that file exists, otherwise the documented flat-normal fallback SHALL be used. Diffuse and normal MAY be sampled from **different** underlying texture resources. The drawable SHALL use the **material and filter** rules from `sprite-engine-2d-lighting` (e.g. **`CanvasTexture`** on **`Sprite2D.texture`** with diffuse and normal slots, or an equivalent approach compatible with the project renderer). The presenter SHALL **not** register materials with a legacy autoload for uniform fan-out on the default path. Optional **`specular.png`** and **`occlusion.png`** SHALL be loaded when present per lookup rules; wiring them into rendering beyond lookup is out of scope for the stock engine-lit `CanvasTexture` path unless documented otherwise.

#### Scenario: Normal follows diffuse under engine lighting

- **WHEN** the presenter advances frame or changes action or **displayed** direction while lit mode is enabled
- **THEN** the normal map data configured for the child `Sprite2D` SHALL stay aligned with the diffuse for that frame when `normal.png` exists, or SHALL use the documented fallback when it does not

#### Scenario: Lit mode during direction transition

- **WHEN** lit mode is enabled and the presenter steps the displayed facing along a multi-step transition
- **THEN** each step SHALL update diffuse and normal data for the new displayed row before the next timer tick
