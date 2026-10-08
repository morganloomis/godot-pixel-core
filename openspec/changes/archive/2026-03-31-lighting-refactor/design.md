## Context

**Current state:** Lit `AnimatedEntity` uses a duplicated **`sprite_lit_material.tres`** (`sprite_lit.gdshader`) in **`unshaded`** mode with a hand-rolled lighting model (ambient + directional + up to four point lights). The autoload **`SpriteLighting`** (`sprite_lighting.gd`) registers each lit material and pushes uniforms every frame because **GL Compatibility** does not reliably apply **global shader parameters** to canvas items. Diffuse and normal come from **`AnimatedSpriteSheetLookup`** as separate **`AtlasTexture`** regions; the normal is bound via shader parameter `normal_map`.

**Constraints:** **Godot 4.6**, **GL Compatibility**, **pixel-perfect** (nearest filtering, pre-rendered art). Project convention: **native Godot first**; eight facings from sheets, not node rotation, for lighting correctness.

**Stakeholders:** Future addon consumers and maintainers. The addon is still **boilerplating**—API and scene wiring may change without preserving prior names or behavior, aside from keeping a **legacy** copy of the old lighting code for reference.

## Goals / Non-Goals

**Goals:**

- Drive **lit** sprites through Godot’s **built-in 2D lighting pipeline** where possible: child **`Sprite2D`** with **diffuse + normal** textures that update each frame from the same lookup as today, and **scene-level 2D lights** (**`DirectionalLight2D`**, **`PointLight2D`**, etc.—Godot 4’s 2D light nodes; older docs may say “Light2D”).
- Remove the need for **`SpriteLighting`**’s per-frame uniform fan-out for the **default** lit path (lights become normal nodes / engine uniforms).
- Preserve **normal–diffuse sync** on every `update_sprite` (frame / action / direction change).
- **Archive** the current shader + autoload implementation under a **clear `legacy/` (or equivalent) subtree** so it can be restored, diffed, or compared—not because external games need a stable API, but as a safety net while the new path is proven out.
- Document setup for the **test scene** (which lights, which canvas/layer settings) so behavior is reproducible.

**Non-Goals:**

- Matching the old shader **pixel-for-pixel** (half-Lambert, fixed sun Z hack, four-light cap) if engine lighting looks different; goal is **understandable** engine behavior, not numerical parity.
- Full **3D** or **forward+** rendering paths.
- Solving every upstream **GL Compatibility / pixel-art** engine quirk in this change (document and mitigate; link issues if needed).

## Decisions

### 1. Primary lit path: engine 2D lighting on `Sprite2D`

**Choice:** For the lit presenter mode (export name TBD in implementation—**no need to keep `use_pseudo_lighting`**), use the child **`Sprite2D`**’s standard **textured + normal-mapped** canvas item path: assign **`texture`** to the diffuse atlas and **`normal_map`** (Godot 4 property name per docs) to the normal atlas from lookup; use a **default `CanvasItemMaterial`** (or equivalent) in a mode that **receives** 2D lights—not the current custom **`unshaded`** full-scene shader.

**Rationale:** Matches official “2D lights and shadows” workflows, editor inspection, and debugging tools; removes bespoke uniform plumbing for sun/points.

**Alternatives considered:**

- **Keep custom shader, only refactor structure** — Fails the goal of aligning with standard workflows and keeps GL global-uniform pain for any shared parameters.
- **Single `CanvasTexture` on `Sprite2D`** — Godot’s **`CanvasTexture`** can bundle channels for some use cases (e.g. tile sources); for animated entities, separate **`AtlasTexture`** updates for diffuse and normal are already available and map cleanly to **`Sprite2D.texture`** and **`Sprite2D.normal_map`**. **Decision:** Prefer **dual assignment from lookup** unless implementation finds a concrete benefit to `CanvasTexture` (e.g. one resource slot for tooling); if `CanvasTexture` is used, document it in the new spec.

### 2. Scene lights instead of `SpriteLighting` API for the new default

**Choice:** **Directional / point / spot** behavior is authored with **`DirectionalLight2D`**, **`PointLight2D`**, and related nodes under the appropriate **`CanvasLayer`** / **`World2D`**, with **`CanvasModulate`** (and project/environment settings as needed) for overall ambient tone—instead of **`SpriteLighting.ambient_color`**, **`directional_*`**, and **`set_point_light`**.

**Rationale:** Standard Godot scenes; no registration list; easier for users to reason about “why is this dark” (visible light nodes).

**Alternatives considered:**

- **Thin wrapper autoload** that spawns or tweens engine lights from code — Optional later; not required for the first refactor if scenes use light nodes directly.

### 3. Legacy bundle location and policy

**Choice:** Move (copy-then-replace or git mv) **`sprite_lighting.gd`**, **`sprite_lit.gdshader`**, **`sprite_lit_material.tres`**, and any solely-pseudo-lit helpers into e.g. **`addons/godot-pixel-core/lighting/legacy/`** with a short **`README.md`** stating: not used by default, reference for rollback, no guarantee of registration in `project.godot` unless user opts in.

**Rationale:** Satisfies rollback without deleting knowledge; keeps “current” lighting folder small.

**Alternatives:** Only git history — Weaker for quick side-by-side comparison; user explicitly asked to **save what we have** in-tree.

### 4. Exports and autoloads

**Choice:** **Rename or replace** exports and remove the **`SpriteLighting`** autoload from the default addon wiring as part of this refactor. Use names that match engine-lit behavior (e.g. `use_normal_mapped_lighting`, `receive_2d_lights`, or similar—final choice in tasks/specs). **No compatibility shims** for the old pseudo-lighting API.

**Rationale:** The project is still boilerplating; clarity and honest naming beat preserving temporary APIs.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| **Visual mismatch** vs old pseudo shader | Expect differences; use test scene comparisons; legacy folder for A/B. |
| **GL Compatibility + normal maps** (e.g. filtering / sampling quirks with **`PointLight2D`**) | Document known engine issues; nearest filter on sprites; test at intended zoom; link upstream issues if hit. |
| **More scene setup** (authors must add light nodes) | Document minimal template in addon README + test scene; optional presets later. |
| **Performance** (many lit sprites × lights) | Engine path is the standard trade-off; profile if needed; non-goals include micro-optimizations unless spec demands. |

## Migration Plan

1. **Land legacy subtree** (copy current shader + material + `sprite_lighting.gd` + README) so the old implementation stays available for comparison or manual rollback.
2. **Implement engine-lit path** on `AnimatedEntity` (diffuse + `normal_map` from lookup; material and filters per spec); **drop** default `SpriteLighting` registration and old lit material path from active code.
3. **Update test scene** with 2D lights and `CanvasModulate` as needed; verify unlit and lit entities.
4. **Rollback (optional):** Re-enable behavior by copying from `legacy/` or reverting in git—not a supported dual-path runtime.

## Open Questions

- **Exact Godot 4.6 + GL Compatibility** behavior for **`Sprite2D.normal_map`** + **`DirectionalLight2D` / `PointLight2D`** at project render settings—validate in-editor before locking spec scenarios (including blend modes and **`CanvasItem.light_mask`** if layers are used).
- Whether **`CanvasTexture`** buys anything for **runtime atlases** vs dual **`AtlasTexture`** assignment; resolve during implementation and reflect in **`sprite-engine-2d-lighting`** spec.
