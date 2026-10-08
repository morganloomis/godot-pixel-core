## Context

`AnimatedEntity` resolves frames through `sprite_lookup` (`AnimatedSpriteSheetLookup` by default), assigning an `AtlasTexture` or lit `CanvasTexture` to the child `Sprite2D` in `update_sprite()`. That path depends on `_get_entity_name()`, `action`, `direction`, and `frame`. In the editor, authors set **`entity_name`** on the presenter or on **`CharacterEntity`** (forwarded to the child), but without running the game the drawable often stays empty or stale because the same refresh path is not reliably driven for export changes, and the animation timer is geared toward runtime.

Constraints: keep **runtime behavior** unchanged; reuse **existing lookup and layout** (`compute_rect_animated`, diffuse pass paths); avoid new mandatory exports unless clearly valuable.

## Goals / Non-Goals

**Goals:**

- In the **editor only**, show a **static placeholder** on the presenter’s `Sprite2D`—**no animation** and **no direction stepping**; runtime `action` / `direction` / `frame` are irrelevant to the preview.
- **Action selection:** **always try `idle` first** (valid diffuse + grid). If **`idle`** is not valid, **first available** = the **first action name in alphabetical order (A→Z)** among subfolders of `{animated_sheet_root}/{entity}/` that has a valid diffuse grid (stable, deterministic).
- **Cell:** **top-left** of the chosen sheet—the same as **row S / frame 0** in the animated layout (`SpriteSheetLookupBase.DIRECTIONS[0]` × column `0`) via existing `get_texture` / `compute_rect_animated` rules.
- Refresh when **`entity_name`** changes on `AnimatedEntity`, and when **`CharacterEntity.entity_name`** updates and forwards to the presenter (so root-level authoring works).
- **Diffuse-only** preview in the editor (plain `AtlasTexture` on `Sprite2D.texture`) to avoid `CanvasTexture` baking, static caches, and light setup in the viewport unless we later decide otherwise.

**Non-Goals:**

- Playing clips, stepping frames, or cycling direction in the editor (preview is one fixed cell only).
- Matching lit-mode `CanvasTexture` / normal baking in the editor for this change.
- New sprite layout rules, new pass files, or changing default sheet roots beyond what lookup already does.
- Automated headless tests that drive the Godot editor (optional manual checklist only).

## Decisions

1. **`@tool` on presenter (and character when needed)**  
   **Choice:** Add `@tool` to `animated_entity.gd` and `character_entity.gd` so export setters and lifecycle run in the editor.  
   **Rationale:** Property changes on `entity_name` must trigger a refresh without a plugin. Alternatives (only `NOTIFICATION_EDITOR_PRELOAD`, or a custom `EditorPlugin`) are heavier or miss live inspector edits.  
   **Mitigation:** Branch every editor-specific side effect on `Engine.is_editor_hint()` so gameplay paths stay identical.

2. **Single refresh function for editor placeholder**  
   **Choice:** Implement something like `_apply_editor_sprite_placeholder()` that: ensures `sprite_lookup` is non-null (same default as `_ready()`), resolves `eid` via `_get_entity_name()`, picks **preview action** by **trying `idle` first**; if not valid, list action subfolders under `{animated_root}/{eid}/`, sort names **A→Z**, take the **first** where `get_frame_count(eid, action) > 0` (or equivalent valid diffuse). Then `get_texture(eid, preview_action, "S", 0, DIFFUSE)` (top-left cell), assign **`sprite.texture`** to that `AtlasTexture` when valid; **diffuse-only**; skip lit `CanvasTexture` path.  
   **Rationale:** **`idle` first** matches default authoring; **alphabetical** fallback is predictable when `idle` is absent or broken. Does **not** follow runtime `action` / `direction` / `frame`.  
   **Alternative considered:** Use runtime `action` property — rejected per product decision; preview is authoring-only and should not depend on game state.

3. **Editor: do not run the frame timer**  
   **Choice:** In `AnimatedEntity._ready()`, if `Engine.is_editor_hint()`, skip `animation_timer.start()` (and optionally disconnect or never connect timeout for editor), and call the editor placeholder helper instead of full `update_sprite()` for the initial editor draw.  
   **Rationale:** Avoids ticking in every open scene and avoids fighting static placeholder with timer-driven `update_sprite()`. On run, existing `_ready()` behavior applies (`is_editor_hint()` false).

4. **Runtime `update_sprite()` unchanged**  
   **Choice:** Do not replace `update_sprite()` logic for play mode; editor placeholder runs only under `is_editor_hint()` from `_ready`, `NOTIFICATION_ENTER_TREE` / `NOTIFICATION_TRANSFORM_CHANGED` if needed, and when `entity_name` (and forwarded name) updates.  
   **Rationale:** Minimizes regression risk.

5. **`CharacterEntity` forwarding**  
   **Choice:** With `@tool` on `CharacterEntity`, keep `_push_entity_name_to_presenter()`; after setting `animated_entity.entity_name`, call a **public** method on the child such as `refresh_editor_sprite_preview()` or rely on the child’s `entity_name` setter to call the same helper if we centralize there.  
   **Rationale:** Root export edits must update the child presenter in the inspector. Prefer one public entry point on `AnimatedEntity` to avoid duplicating lookup logic.

6. **Missing assets**  
   **Choice:** **`idle` first**, then **alphabetical first valid** as above. If **no** action yields a valid diffuse, **no-op** (leave prior texture or empty); no new blocking errors.  
   **Rationale:** Matches proposal; avoids noisy editor failures for work-in-progress entities.

7. **Editor refresh scope (keep v1 simple)**  
   **Choice:** Rely on **`_ready`** plus refresh when **`entity_name`** changes (presenter and character forward). Use **`call_deferred`** on the placeholder helper only if `@onready` / child order requires it. **Do not** add `NOTIFICATION_EDITOR_PRE_SAVE`, extra scene-load notifications, or **EditorFileSystem** / resource-reload listeners for this slice.  
   **Rationale:** Smallest surface area; predictable behavior.  
   **Accepted limitation:** If **`diffuse.png`** (or other sheet files) change **on disk** but **`entity_name`** is unchanged, the viewport preview **may not** update until the author changes a relevant export, reloads the scene, or otherwise retriggers the helper. That is **acceptable** for v1.

## Risks / Trade-offs

- **`@tool` script cost** → Slightly more editor load; keep work to property changes and enter-tree, no per-frame work.  
- **Double maintenance** → Editor path duplicates “which cell” knowledge; kept to one helper calling existing lookup.  
- **Directory scan in editor** → Small cost when `entity_name` changes; cache last `(eid → preview_action)` if needed later.  
- **Timer still created** → Low risk; not started in editor per decision above.

## Migration Plan

- Ship as **additive** behavior: no scene or resource migration.  
- **Rollback:** Remove `@tool` and editor helper calls; revert to prior scripts.

## Open Questions

- None for v1; **first available** and **editor refresh scope** are decided above. Optional later: auto-refresh when sheet files change on disk (EditorFileSystem / resource reload).
