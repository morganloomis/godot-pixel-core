## Why

Sprite frames are resolved and applied at runtime, so scenes that use `AnimatedEntity` (and characters that forward `entity_name`) often show an empty or generic sprite in the editor. Authors need a cheap, accurate placeholder in the viewport when they set the sprite set id so layout, collision, and parenting stay readable without pressing Play.

## What Changes

- **Editor-only placeholder** on the animated sprite presenter path: **no animation** and **no direction changes**—a single static image. **Try `idle` first:** if its diffuse sheet is valid, use the **top-left cell** of that sheet (first row × first column of the animated grid, i.e. **S**, frame **0**). If **`idle`** is missing or invalid, **first available** means the **first action folder name in alphabetical order (A→Z)** under that entity that has a valid diffuse grid.
- Placeholder updates when **`entity_name`** changes on `AnimatedEntity`, and when **`entity_name`** on **`CharacterEntity`** is forwarded to the child presenter (same net effect as editing the presenter directly).
- **Runtime behavior** in play mode stays governed by existing action, direction, and frame logic; the placeholder does not replace gameplay-driven updates once the scene runs (exact interaction with first-frame vs `update_sprite` will be nailed in design/specs—e.g. apply only while `Engine.is_editor_hint()` or equivalent).
- If the sheet path is missing or invalid, the editor falls back to current behavior (no new hard error required in the proposal phase).
- No **BREAKING** API or scene format changes intended; additive editor UX only.

## Capabilities

### New Capabilities

- `sprite-editor-preview`: Defines when the editor shows a sprite-sheet placeholder, which node(s) it applies to, how **entity_name** selects the entity folder, **try `idle` first** then **alphabetical first-available** fallback, **top-left cell** semantics, static preview (no animation/direction stepping), and how this coexists with lit vs unlit presenter settings in the editor.

### Modified Capabilities

- _(none)_ — Existing presenter and character specs stay as-is unless implementation review shows a MUST-level change; editor preview is specified under `sprite-editor-preview` and can reference `sprite-presentation` and `character-entity` as related behavior.

## Impact

- **`addons/godot-pixel-core/entity/animated_entity.gd`** — Editor notifications or tool script hooks to set `Sprite2D` texture/region from lookup (diffuse pass) without duplicating full runtime animation.
- **`addons/godot-pixel-core/entity/character_entity.gd`** — Already forwards `entity_name`; may need to trigger the same editor refresh path when the root export changes.
- **`addons/godot-pixel-core/sprite_sheet/`** — Reuse `AnimatedSpriteSheetLookup` (or base) for path/rect resolution consistent with runtime.
- **Scenes / exports** — No new required exports; preview uses **`idle` when valid**, else **first valid action in A→Z order**, not the runtime `action` property.
- **Tests** — Optional: regression test or manual checklist for editor preview when paths exist (Godot headless limits may constrain automation).
