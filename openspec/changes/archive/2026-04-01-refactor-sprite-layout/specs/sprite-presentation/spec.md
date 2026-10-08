## MODIFIED Requirements

### Requirement: Presenter exports sprite set identifier

The presenter (`AnimatedEntity` or successor) SHALL expose an exported string **entity_name** that selects the **entity folder name** under the configured animated sheet root for texture paths (e.g. `res://…/sprite/…/<entity_name>/<action>/diffuse.png`). If empty, the presenter SHALL fall back to a documented rule (e.g. the presenter node’s name).

#### Scenario: Presenter inspector shows entity name

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include an exported **entity_name** property documented as the sprite set / folder id for lookup

---

### Requirement: Engine-lit presenter behavior

When lit mode is enabled, the presenter SHALL configure the child **`Sprite2D`** for **Godot 2D lighting**: diffuse data for the current entity, action, direction, and frame SHALL come from **`diffuse.png`** via lookup; normal data SHALL come from **`normal.png`** when that file exists, otherwise the documented flat-normal fallback SHALL be used. Diffuse and normal MAY be sampled from **different** underlying texture resources. The drawable SHALL use the **material and filter** rules from `sprite-engine-2d-lighting` (e.g. **`CanvasTexture`** on **`Sprite2D.texture`** with diffuse and normal slots, or an equivalent approach compatible with the project renderer). The presenter SHALL **not** register materials with a legacy autoload for uniform fan-out on the default path. Optional **`specular.png`** and **`occlusion.png`** SHALL be loaded when present per lookup rules; wiring them into rendering beyond lookup is out of scope for the stock engine-lit `CanvasTexture` path unless documented otherwise.

#### Scenario: Normal follows diffuse under engine lighting

- **WHEN** the presenter advances frame or changes action or direction while lit mode is enabled
- **THEN** the normal map data configured for the child `Sprite2D` SHALL stay aligned with the diffuse for that frame when `normal.png` exists, or SHALL use the documented fallback when it does not
