## MODIFIED Requirements

### Requirement: Runtime diffuse and normal textures for lit presenters

For each frame update, a lit presenter SHALL supply the child **`Sprite2D`** with **diffuse** and **normal map** data for the same **entity**, **action**, **direction**, and **frame**. Diffuse SHALL be resolved from **`diffuse.png`**; normal SHALL be resolved from **`normal.png`** when present, otherwise a **flat** (or project-default) normal texture SHALL be used so Godot’s 2D lighting still receives valid normal inputs. Diffuse and normal MAY be backed by **different** `Texture2D` resources (separate files). The implementation MAY use a **`CanvasTexture`** on **`Sprite2D.texture`** with separate diffuse and normal slots, baking atlas regions to **`ImageTexture`** (or equivalent) when required for renderer compatibility.

#### Scenario: Normal map matches diffuse frame

- **WHEN** the presenter changes action, direction, or frame while lit mode is enabled and `normal.png` exists for that action
- **THEN** both diffuse and normal data shown on the lit drawable SHALL refer to lookup results for that same pose

#### Scenario: Lit mode without normal file

- **WHEN** lit mode is enabled and `normal.png` is absent for the current action
- **THEN** the drawable SHALL still receive diffuse from lookup and a documented fallback normal, without requiring `normal.png`
