## Context

- **Engine**: Godot **4.x** (project targets **4.6**, **GL Compatibility**). Foot shadows must stay within **few texture samples** per pixel and avoid reliance on 3D shadow maps or heavy post chains.
- **Sheets today**: `AnimatedSpriteSheetLookup` loads `{animated_sheet_root}/{entity}/{action}.png` as a **two-block vertical atlas**: **diffuse** (top half) and **normal** (bottom half), with `compute_rect_animated(..., use_normal)` selecting the block. `get_texture(..., type)` returns an `AtlasTexture` region for the current direction row and frame column.
- **Proposal**: Add an **optional artist-authored contact / height-from-ground mask** that stays **frame-locked** with diffuse, then **smear along directional light** projected onto the isometric floor for a **soft, foot-anchored** shadow—not a full-body crisp cast silhouette.
- **Consumers**: Games use **billboard / quad sprites** (e.g. `Sprite2D`), not full 3D characters; **node rotation** for presentation is not a primary case (consistent with the existing pseudo-lighting design).

## Goals / Non-Goals

**Goals:**

- **Data**: Define an **optional** mask source with the **same cell grid as the diffuse block** (8 direction rows × `frame_count` columns, same cell size and frame indexing as diffuse). Artists author once per action; values mean **contact strength / proximity to ground** (high at planted feet, low when lifted).
- **Sync**: Whenever the animated entity updates diffuse (and optional normal), the **mask region for the same `(entity, action, direction, frame)`** SHALL resolve from lookup so it cannot drift from the visible sprite.
- **Runtime**: Build a **shadow intensity** from the mask, then apply a **directional smear** along the **light direction projected onto the ground plane**, so elongation and falloff read as **directional** and **soft**.
- **Mapping**: Document a **single clear convention** for how **world or scene light direction** becomes (1) **horizontal direction on the floor** and (2) **2D / UV sampling offsets** on the shadow quad, appropriate for **isometric** projects.
- **Composite**: Darken or multiply **ground (or a dedicated ground layer)** with the result; strength exposed for tuning.
- **Performance**: Prefer **one extra atlas sample + fixed tap count** in a **CanvasItem** shader, or **one small render target** (e.g. half-res) for a separable directional blur if needed—still **lighter than** per-character shadow maps, voxels, or full mesh casters.

**Non-Goals:**

- **Crisp full-body** cast shadows, silhouette extrusion, or **voxel / 3D** shadow volumes.
- **Automatic** mask generation from meshes or depth buffers at runtime.
- **Guaranteed** correct self-shadowing on the character sprite itself (contact shadow is a **ground** effect).
- **Per-pixel** shadow interaction with arbitrary 3D terrain heightfields (floor is treated as a **plane** for light projection unless a future change adds height).

## Decisions

### 1. Mask storage: sidecar PNG (diffuse-block layout)

- **Choice**: Resolve the mask from an **optional** file alongside the action sheet: `{animated_sheet_root}/{entity}/{action}_contact.png` (exact suffix locked in specs/tasks). Image layout **matches the diffuse block only**: width equals combined sheet width, height equals **half** of combined sheet height (one block), same **8 × frame_count** grid and cell size as the top block of `{action}.png`.
- **Rationale**: Avoids changing the **two-block** combined diffuse/normal PNG contract; artists who skip shadows ship **no** `_contact` file; lookup can mirror `compute_rect_animated(..., use_normal=false)` for region math without a third vertical strip in every sheet.
- **Alternatives considered**:
  - **Third vertical block** in the same PNG — rejected for this change: breaks existing dimension assumptions and `sheet_size.y / 2` frame math everywhere.
  - **Mask embedded in a spare channel of diffuse** — rejected: complicates art pipeline and diffuse color integrity.

### 2. Lookup and API surface

- **Choice**: Extend `AnimatedSpriteSheetLookup` (or parallel helper) with a **contact atlas resolver** that returns an `AtlasTexture` (or null region if file missing) using the **same** `entity`, `action`, `direction`, `frame` as diffuse. `AnimatedEntity` (or a thin **shadow-enabled** subclass/scene) assigns this to a **shader parameter** whenever `update_sprite()` runs.
- **Rationale**: Same synchronization strategy as the normal pass: **one code path** per frame update prevents desync.
- **Alternatives**: Manual per-scene texture assignment — rejected: error-prone and duplicates layout rules.

### 3. Where the shadow is drawn: separate CanvasItem behind the character

- **Choice**: Implement the visible shadow as a **dedicated child** `Sprite2D` / `MeshInstance2D` / `ColorRect` (final node type in tasks) that uses the **contact atlas** on a **shader material**, placed **under** the character in draw order (or on a **lower z-index** / dedicated **CanvasLayer** for ground). The quad is **axis-aligned in screen/canvas space** (billboard game style), positioned at the character’s **foot pivot** with artist-tunable **offset** so the smear sits on the “floor.”
- **Rationale**: Keeps the **diffuse sprite shader** free of ground compositing; matches common 2D isometric practice (blob/decal under feet); easy to toggle off.
- **Alternatives**:
  - **Only full-screen ground shader** — rejected: needs world-position or decal data per foot; harder to generalize in an addon.
  - **Single-pass on character sprite** — rejected: does not darken the ground beneath feet unless using complex destination-out stencils.

### 4. Light direction: project to floor, then map to UV smear axis

- **Choice**: Treat the isometric **floor** as a plane with a **known world normal** (e.g. up axis). **Incoming light direction** `L` (from surface toward light, or the engine’s convention—fixed in spec) is **projected** onto the plane: `L_h = L - N_floor * dot(L, N_floor)`, then normalized. Game or addon code maps `L_h` to a **2D unit vector in canvas / sprite space** used as **`smear_dir`** for UV offsets (e.g. via a **Basis** built from camera forward/right projected onto the floor, or a single **pre-authored** 2D vector per level if the camera is fixed).
- **Rationale**: Spec stays honest about **isometric**: 3D light direction must become **ground-plane motion** before it becomes **texture sampling direction**; different projects may supply either **pre-projected 2D** or **3D + plane normal** depending on their scene setup.
- **Alternatives**:
  - **Smear only in +X canvas** — rejected: not directional with respect to sun.
  - **Require full 3D math in shader** — rejected: GL Compatibility CanvasItem shaders are simpler with **uniforms** already in 2D.

### 5. Smear implementation: fixed taps in the fragment shader (default path)

- **Choice**: Sample the contact texture at **UV + k * smear_dir * step** for `k` in a small fixed range (e.g. 5–9 taps) with **weights** (Gaussian or exponential falloff). Combine: `shadow = base_mask_weight * sum(w_k * sample_k)` with tunable **max length** in **UV space** (derived from texel scale and desired world extent).
- **Rationale**: **No extra render target** by default; predictable cost **O(taps)** per shadow pixel; easy to cap taps for mobile.
- **Alternatives**:
  - **Separable blur in a small Viewport** — optional later path if artifacts require it; heavier (extra pass, clear, composite).
  - **Physics-style ray-march in UV** — rejected: unnecessary for soft fake shadows.

### 6. Multiple lights

- **Choice**: **Default policy**: use **one primary directional** (same conceptual source as the global scene light if present) for foot-shadow direction and intensity. If multiple directionals matter, **spec SHALL define** either **max of contributions** or **sum with clamp**—implementation follows spec; no per-pixel shadow map fusion.
- **Rationale**: Keeps shader uniforms small and behavior predictable; foot shadows are **stylized**, not physically correct.

### 7. Integration with lit entities

- **Choice**: Foot shadow is **orthogonal** to pseudo-lighting: it may attach to **`LitAnimatedEntity`** or a sibling scene that shares the same lookup and frame updates. Shared autoload may expose **shadow direction** alongside **light direction** when both should match; they can also differ if design calls for “fill” vs “key” separation.
- **Rationale**: Avoids circular dependency between lighting and shadow features; both remain optional.

## Risks / Trade-offs

- **[Risk] `_contact` sheet missing or wrong size** → Mitigation: treat as **no shadow**; optional debug log; document dimensions relative to `{action}.png`.
- **[Risk] UV smear crosses atlas cell boundaries** → Mitigation: use **clamp-to-border** or **clamp UV** with zero contact outside region; keep **smear length** a fraction of cell size; tune in test scene.
- **[Risk] Fixed 2D `smear_dir` vs varying camera** → Mitigation: document that **camera-locked isometric** games should update `smear_dir` when the rig changes; optional helper that reads camera basis each frame.
- **[Risk] Two feet / gait** → Mitigation: mask already encodes **per-texel** contact; smear **blends** both feet naturally; no special case required if art is good.
- **[Trade-off] Soft vs accurate** → Accepted: this system **prioritizes** readable **contact + streak** over geometric correctness.

## Migration Plan

- **Consumers**: Projects without `_contact` textures see **no new draw cost** and no visual change if shadow nodes are absent or disabled.
- **Adoption**: Opt in per entity or scene by instancing the shadow child / enabling the export; test scene demonstrates one configured character.
- **Rollback**: Disable shadow node or remove `_contact` assets; no migration of existing PNGs required.

## Open Questions

- Final **filename suffix** (`_contact` vs `_shadow_mask`) and whether **static** sheets ever need the same treatment.
- Whether contact textures should be imported as **sRGB vs linear** (recommend **linear** or **raw** if values are weights, not color).
- **Exact foot offset** defaults (export on shadow node vs derived from sprite metadata).
- Whether to add a **half-res blur pass** path in v1 or only if shader taps prove insufficient.
