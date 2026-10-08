## 1. Lookup and layout math

- [x] 1.1 Add a pass enum or named constants (`diffuse`, `normal`, `specular`, `occlusion`) and path helper: `{animated_root}/{entity}/{action}/{pass}.png`
- [x] 1.2 Replace stacked-block `compute_rect_animated` with single-grid math: `cell_h = H/8`, `cell_w = W/frame_count` (no `y/2` block split)
- [x] 1.3 Update `AnimatedSpriteSheetLookup`: `get_frame_count` reads only `diffuse.png`; returns 0 if missing
- [x] 1.4 Update `get_texture` (or equivalent) to accept pass selector; return null/empty `AtlasTexture` when file absent; cache by full path per pass
- [x] 1.5 Document or warn when an optional pass exists but dimensions disagree with `diffuse.png` (debug-only acceptable)

## 2. Presenter and lit path

- [x] 2.1 Update `AnimatedEntity.update_sprite` / `_lit_cell_diffuse_and_normal` to sample diffuse from `diffuse.png` and normal from `normal.png` when present; keep flat-normal fallback
- [x] 2.2 Ensure substitute `sprite_lookup` contract (if any) matches new `get_texture` signature
- [x] 2.3 If specs require exposing specular/occlusion to callers, add accessors or extend lookup usage without breaking unlit diffuse-only actions

## 3. Test harness and art (owner-owned)

**Sprite sheet PNGs and folder layout under `test/art/sprite/` (and any other game art) are out of scope for implementation** — you migrate those when ready. It is expected that the playtest demo cannot be fully exercised until new art exists at `{entity}/{action}/<pass>.png`.

When your art migration is done (optional follow-up, not blocking code merge):

- [x] 3.1 Update `test/test_scene.gd` and any test scenes (`static_lit_prop.tscn`, etc.) so `animated_sheet_root` / paths match the new tree
- [x] 3.2 Run the project in Godot: walk, idle, lit shading, missing-pass behavior

## 4. Documentation and specs sync

- [x] 4.1 Rewrite `addons/godot-pixel-core/README.md` animated sheet section for per-pass files and optional maps
- [x] 4.2 Update `openspec/project.md` domain table if it still describes stacked diffuse/normal blocks
- [x] 4.3 After implementation, run `/opsx:verify` (or manual checklist) against delta specs; archive or sync main specs per project workflow
