## Context

Today, `AnimatedSpriteSheetLookup` loads one PNG per `(entity, action)` and splits it vertically: top half diffuse, bottom half normal. `compute_rect_animated` uses `sheet_size.y / 2` and a row offset for the normal block. `AnimatedEntity` builds a `CanvasTexture` from diffuse + optional normal regions, falling back to a flat normal when the normal region is empty.

Consumers and tests use paths like `res://test/art/sprite/girl/walk.png`. The OpenSpec `sprite-sheet-layout` text currently conflicts with `sprite-sheet-facing` on row order; implementation and `sprite-sheet-facing` use **S → SW** top to bottom.

## Goals / Non-Goals

**Goals:**

- Adopt **one PNG per pass** under `{animated_root}/{entity}/{action}/` with fixed filenames: `diffuse.png`, `normal.png`, `specular.png`, `occlusion.png`.
- **Optional files**: if a pass file is absent, do not load it and do not treat it as an error.
- **Frame count and grid** derived from **`diffuse.png`** when that action is used for animation (diffuse required for a valid animated action).
- When **`normal.png`** is missing, keep current behavior: engine-lit path uses a **flat normal** so `CanvasTexture` still receives valid normal data.
- **Specular** and **occlusion**: load and cache when present; expose via lookup API for future shaders or materials. **Non-goal for stock lit path**: Godot’s `CanvasTexture` (as used today) only binds diffuse + normal—specular/occlusion are not assigned there until a custom material/shader path exists.

**Non-Goals:**

- Implementing a new shader that consumes specular or occlusion in this change (specs may require plumbing through lookup only).
- Changing static sheet layout or static lookup (unless a trivial path default is updated).
- Automatic migration tool for old stacked PNGs (manual split or external script).

## Decisions

1. **Pass filenames** — Lowercase `diffuse.png`, `normal.png`, `specular.png`, `occlusion.png` under each action directory. Matches user request and keeps `ResourceLoader.exists` checks simple.

2. **Configurable root** — Keep `animated_sheet_root` (e.g. `res://test/art/sprite/` in tests, `res://sprite/animated/` default in code). Full path: `animated_sheet_root.path_join(entity).path_join(action).path_join("<pass>.png")`.

3. **Grid layout per pass file** — Each present pass file is a **single** 8-row × N-column grid (no vertical stacking). `compute_rect_animated` (or a renamed helper) drops the `/2` block height: `cell_h = sheet_size.y / 8`, `cell_w = sheet_size.x / frame_count`.

4. **Consistency across passes** — When `normal`, `specular`, or `occlusion` exists, it **SHALL** match diffuse **frame count** and cell size (same width/height and same 8-row semantics). Implementation MAY assert or log if dimensions mismatch; spec will require matching dimensions when multiple passes load.

5. **`get_texture` API** — Replace integer `type` 0/1 with a clear pass selector: e.g. `SpriteSheetPass` enum or named constants (`DIFFUSE`, `NORMAL`, …) to avoid magic numbers and support four passes.

6. **Caching** — Cache key includes full `res://` path per pass file (not only entity/action), so different passes do not collide.

7. **Lit cell baking** — `_lit_cell_diffuse_and_normal` continues to produce `ImageTexture` pairs for diffuse + normal; diffuse atlas comes from `diffuse.png`; normal from `normal.png` if present, else flat normal.

8. **Row order** — Unchanged: **S** row 0 through **SW** row 7 per `sprite-sheet-facing`.

## Risks / Trade-offs

- **[Risk] Breaking all existing stacked-sheet assets** → Document migration: split each `action.png` into `action/diffuse.png` and optional `action/normal.png`; update repo test art.
- **[Risk] Authors ship mismatched pass dimensions** → Mitigation: validate in debug or log warning; spec requires match when optional passes exist.
- **[Risk] Specular/occlusion unused at runtime** → Acceptable: files are optional and ready for future work; README states current engine-lit wiring.
- **[Trade-off] More files per action** → Clearer optional semantics and smaller individual diffs in VCS for artists changing only normals.

## Migration Plan

1. Add new path resolution and region math; keep behavior equivalent when only diffuse+normal exist as separate files.
2. Restructure `test/art/sprite/girl/` to `walk/diffuse.png`, `walk/normal.png`, `idle/…`, etc.
3. Update `addons/godot-pixel-core/README.md` and OpenSpec archive after implementation (`/opsx:apply` phase).

**Rollback:** Revert commit(s); restore previous PNG layout in test assets.

## Open Questions

- Whether `get_frame_count` should return 0 when `diffuse.png` is missing (yes) and whether to support “normal-only” actions (proposal: no; diffuse required).
