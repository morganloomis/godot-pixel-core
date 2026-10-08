## Context

`SpriteSheetLookupBase` defines `DIRECTIONS` and uses the index as the row index for animated sheets (diffuse block rows 0–7, then normal block). Today that array is **N, NE, E, SE, S, SW, W, NW** (clockwise from north). `PlayerEntity` uses a **different** array to map `Vector2.angle()` segments to direction strings, which is easy to drift from the sheet layout.

The project standard for art is: **row 0 = S**, then each row below steps **counter-clockwise** around the compass: **SE, E, NE, N, NW, W, SW**.

## Goals / Non-Goals

**Goals:**

- One canonical `DIRECTIONS` order: `S, SE, E, NE, N, NW, W, SW` with index 0 = top row of the diffuse block in `compute_rect_animated`.
- Movement → direction string → row index must be consistent for `PlayerEntity` (and any similar code).
- Comments in lookup code describe the same convention as specs and docs.

**Non-Goals:**

- Editing, re-exporting, or reordering rows in existing sprite sheet textures (art is already correct for this project).
- Changing column/frame layout, cell size rules, or static sheet behavior.
- Adding editor import tools or automatic sheet remapping.
- Moving `DIRECTIONS` to a shared autoload (optional follow-up).

## Decisions

1. **Single source in `SpriteSheetLookupBase`**  
   **Rationale:** `direction_name_to_index` and `compute_rect_animated` already depend on this array; sheet rows are defined here.  
   **Alternatives:** Duplicate constants in `PlayerEntity` — rejected (drift risk).

2. **Update `PlayerEntity._vector_to_direction` to match the new index order**  
   **Rationale:** Input vectors must produce the same direction names the lookup expects. Replace the current W-first `DIRECTIONS` + `round((angle + PI) * 4 / PI)` scheme with a segmentation that assigns each octant to `S` … `SW` in sheet order.  
   **Alternatives:** Remap indices inside `get_texture` only — rejected (would desync string labels used elsewhere).

## Risks / Trade-offs

- **[Risk] Wrong octant boundaries** → **Mitigation:** Manually verify in test scene with known movement directions (cardinals + diagonals) against expected row.
- **[Risk] Other projects relied on old code row semantics** → **Mitigation:** Document canonical row order in addon README or asset docs so consumers can compare their art.

## Migration Plan

1. Ship addon code that maps direction names/indices to rows **S, SE, E, NE, N, NW, W, SW** top to bottom, matching in-repo art without changing textures.
2. Rollback: revert code only.

## Open Questions

- None for core behavior; optional doc updates (`docs/ASSET_LIBRARY.md`) can be a separate polish task if desired.
