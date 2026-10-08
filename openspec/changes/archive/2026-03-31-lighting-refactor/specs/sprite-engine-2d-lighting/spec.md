# Spec Delta: Sprite engine 2D lighting

## ADDED Requirements

### Requirement: Lit sprites use Godot 2D lighting nodes

The addon SHALL document and support a **default lit path** where shaded sprites are driven by Godot’s **built-in 2D lighting** (e.g. **`DirectionalLight2D`**, **`PointLight2D`**, **`SpotLight2D`** as applicable to Godot 4.x) together with **`CanvasModulate`** and project render settings. The addon SHALL **not** require a project autoload that pushes custom per-material sun or point-light uniforms for this default path.

#### Scenario: Authors add visible lights in the scene

- **WHEN** a consumer builds a scene with a lit presenter and follows addon documentation
- **THEN** they SHALL add and tune 2D light nodes (and ambient via `CanvasModulate` or documented defaults) rather than call a bespoke global lighting API on an autoload

---

### Requirement: Runtime diffuse and normal textures for lit presenters

For each frame update, a lit presenter SHALL supply the child **`Sprite2D`** with a **diffuse** texture and a **normal map** texture derived from the same **sprite sheet lookup** rules as unlit mode (same entity, action, direction, frame). The normal map SHALL be a **`Texture2D`** compatible with the engine’s sprite normal input (e.g. **`AtlasTexture`** regions from the lookup’s normal pass).

#### Scenario: Normal map matches diffuse frame

- **WHEN** the presenter changes action, direction, or frame while lit mode is enabled
- **THEN** both **`Sprite2D.texture`** (diffuse) and the sprite’s configured normal map SHALL refer to lookup results for that same pose

---

### Requirement: Canvas item receives 2D lights

When lit mode is enabled, the child **`Sprite2D`** SHALL use a **`CanvasItemMaterial`** (or equivalent documented material) configured so the item **receives** 2D lighting (not an **`unshaded`** custom replacement for the full lighting model). **`texture_filter`** on the drawable SHALL be set to **nearest** (or equivalent) for pixel art unless a spec elsewhere overrides it.

#### Scenario: Lit drawable is not unshaded engine replacement

- **WHEN** lit mode is enabled on the presenter
- **THEN** the child `Sprite2D` material SHALL be in a mode that participates in Godot’s 2D light rendering pipeline as documented for the project’s renderer

---

### Requirement: Legacy pseudo-lighting bundle

The previous **custom shader + autoload** implementation SHALL remain available under a documented **`legacy/`** (or equivalent) directory inside the addon for comparison or manual rollback. That bundle SHALL NOT be required for the default lit path.

#### Scenario: Legacy path is optional

- **WHEN** a consumer uses only the default engine-lit integration
- **THEN** they SHALL NOT need to register autoloads or materials from the legacy bundle
