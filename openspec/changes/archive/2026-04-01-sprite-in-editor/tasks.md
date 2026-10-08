## 1. Preview action resolution

- [x] 1.1 Implement discovery of action folder names under `{animated_sheet_root}/{entity}/` (e.g. `DirAccess`), sorted **A→Z**, reusable from the presenter or lookup layer per `design.md`.
- [x] 1.2 Implement **preview action** selection: validate **`idle`** first via existing `get_frame_count` / diffuse rules; if invalid, use the **first** name in the sorted list with a valid grid.

## 2. `AnimatedEntity` (`animated_entity.gd`)

- [x] 2.1 Add `@tool` and guard all editor-only branches with `Engine.is_editor_hint()`.
- [x] 2.2 Implement `_apply_editor_sprite_placeholder()` (or agreed name): resolve preview action (§1), `get_texture(eid, action, "S", 0, DIFFUSE)`, assign **diffuse-only** `AtlasTexture` to `$Sprite2D.texture`; do **not** use the lit `CanvasTexture` path for this preview.
- [x] 2.3 In `_ready()`, when editor hint: **do not** start the animation timer for stepping frames; apply the editor placeholder (use `call_deferred` if `$Sprite2D` / lookup timing requires it).
- [x] 2.4 Replace the plain `entity_name` export with a backed property + setter (keep `_get_entity_name()` behavior: export vs node `name` fallback) so inspector edits re-run the editor placeholder.
- [x] 2.5 Add a **public** `refresh_editor_sprite_preview()` (or agreed name) that re-runs the placeholder helper so other nodes (e.g. character forward) can trigger a refresh without duplicating logic.

## 3. `CharacterEntity` (`character_entity.gd`)

- [x] 3.1 Add `@tool` so root **`entity_name`** export runs in the editor.
- [x] 3.2 After `_push_entity_name_to_presenter()` succeeds, when editor hint, call the presenter’s `refresh_editor_sprite_preview()` so the viewport updates even if edge cases bypass a redundant `entity_name` assign (keep behavior aligned with `design.md`).

## 4. Verification

- [ ] 4.1 Manual: in the editor, set **`entity_name`** on `AnimatedEntity` and on `CharacterEntity` (forwarding); confirm **S / frame 0** placeholder for **`idle`** and for alphabetical fallback when `idle` is missing.
- [ ] 4.2 Manual: run the scene in play mode and confirm runtime animation, direction, and lit/unlit behavior are unchanged.
- [x] 4.3 Optional: note in `addons/godot-pixel-core/README.md` that editor preview may not refresh until **`entity_name`** or scene reload after on-disk sheet edits.
