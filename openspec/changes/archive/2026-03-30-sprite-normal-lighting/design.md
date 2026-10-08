## Context

- **Engine**: Godot **4.x** (project targets **4.6**, **GL Compatibility**). CanvasItem shaders must stay within limits reasonable for mobile/integrated GPUs.
- **Sheets**: `SpriteSheetLookupBase.compute_rect_animated` already models **two vertical blocks**: **diffuse** (top half) and **normal** (bottom half), 8 direction rows per block, `frame_count` columns. `AnimatedSpriteSheetLookup.get_texture(..., type)` returns an `AtlasTexture` with `type == 0` diffuse and `type == 1` normal over the **same** underlying sheet.
- **Runtime today**: `AnimatedEntity.update_sprite()` only assigns **diffuse** (`type 0`) to `Sprite2D.texture`. Normals are available from lookup but never bound or shaded.
- **Goal alignment**: Pseudo-lighting (not full 3D GI): ambient floor, one **global scene / directional** term, optional point lights in **screen-oriented** space. All of these are **expected to change during gameplay** (moving point lights, fading or shifting intensities, animated sun direction or strength) while staying visually **2D and pixel-friendly**.
- **Product constraint**: Lit sprites are **not** expected to use **node rotation** for presentation; lighting math may assume a **fixed 2D basis** (no transforming the sun into “sprite space” via `global_rotation`).

## Goals / Non-Goals

**Goals:**

- Keep **diffuse and normal regions locked** to the same logical frame: same `entity`, `action`, `direction`, and `frame` indices whenever the sprite updates (animation, direction change, action change).
- Implement shading in a **CanvasItem shader** that combines:
  - **Ambient**: scales diffuse by a configurable color/intensity **without** sampling normals for that term; **intensity/color updatable every frame** if desired.
  - **Directional / scene**: `max(0, N·L)` (or agreed equivalent) using the normal map and a **global light direction** shared across lit sprites, scaled by a **directional intensity**; **both direction and intensity may change at runtime** (e.g. time of day, cues).
  - **Point lights**: for each active light, direction from **pixel position → light position** in a defined 2D space, attenuated by distance, combined with `N·L`; **positions and per-light intensities (and colors/radii as exposed) update freely** during play.
- Provide a **small, documented API** (autoload and/or resources) so gameplay code drives those values **every frame or on demand** without editing the shader.
- Keep the math and presentation **pixel-perfect 2D**: align with integer viewport / **nearest** sampling where the project already does; avoid effects that read as **3D PBR** (specular/roughness stacks, etc.).
- **Verify** via the existing `test/` scene pattern (see delta `test-scene` spec): player still moves/animates; lighting is visibly configurable.

**Non-Goals:**

- Full **normal-mapped 3D** or **Light2D** integration with normal maps (no requirement to match Godot’s built-in 2D light system).
- **Shadows**, **normal blending** between layers, or **HDR** pipeline.
- **Physically based** multi-lobe lighting; the look should remain **stylized 2D** even when parameters animate.
- Automatic **asset pipeline** generation of normal halves (artists supply combined sheets as today).
- **Unbounded** point light counts (must cap for shader arrays / GL compat).

## Decisions

### 1. Where shading runs: `Sprite2D` + `ShaderMaterial`

- **Choice**: Use the existing `Sprite2D` quad; assign a `ShaderMaterial` whose fragment shader reads **two** textures: diffuse atlas and normal atlas (both `AtlasTexture` sharing the same `atlas` image is fine; UVs are per-atlas region).
- **Rationale**: Single draw call per sprite; matches current entity structure; easy to toggle lit vs unlit by material.
- **Alternatives considered**:
  - **Second `Sprite2D` for normals** — rejected: harder to keep identical transforms and doubles overdraw.
  - **Viewport compositing** — rejected: heavier and worse for many characters.

### 2. Keeping normals in sync with diffuse

- **Choice**: On every `update_sprite()` (and any path that sets `frame` / action / direction), resolve **both** `get_texture(..., type=0)` and `get_texture(..., type=1)` and push them to the material (e.g. `shader_parameter` `diffuse_map` / `normal_map`, or reuse `texture` for diffuse and param for normal only — exact names in implementation).
- **Rationale**: Reuses existing rect math; impossible for diffuse and normal to drift if both come from the same indices in the same call.
- **Alternatives**: Single-texture shader with UV math to jump between halves — rejected: duplicates layout knowledge already centralized in lookup; easier to break if layout changes.

### 3. Normal map encoding and tangent basis

- **Choice**: Document and implement a **single convention** in the shader (e.g. sample normal map, map channels from `[0,1]` to `[-1,1]`, build `N` in a **fixed 2D tangent basis** aligned with the quad: **right** = +X, **up** = +Y in the chosen lighting space, with **no** additional transform for node rotation). Optionally allow a **Y-flip** uniform if art was authored inverted.
- **Rationale**: Characters do **not** rely on rotating the `Sprite2D` node; facing is already encoded in the sheet’s eight direction rows, so lighting can stay in one stable basis.
- **Alternatives**: Per-sprite rotation of light direction — **out of scope** for this change (would be needed if nodes rotated).

### 4. Global scene / directional light: shared state, fully dynamic

- **Choice**: Autoload (or shared service) holds the **current** global directional parameters: at minimum a **normalized direction** **Vector2** and a **scalar (or color) intensity** in the **same fixed space** as normals and point lights (e.g. **canvas / screen-consistent axes**). Values are **ordinary runtime fields** updated from gameplay/animation each frame or whenever needed—not loaded once at level start. **No** per-sprite transform from `global_rotation`.
- **Rationale**: Matches the no-rotation constraint; supports **time-of-day**, weather, and scripted **light sweeps** without special-case APIs.
- **Alternatives**: Transform direction by each node’s rotation — rejected for this project. **Pure screen-space vs world-space** for the vector — still pick one and document in specs; both are compatible without node rotation.

### 5. Point lights: moving positions, animated intensities, capped count

- **Choice**: Expose a **maximum** `N` (e.g. 4 or 8 — final N locked in implementation after checking GL Compatibility). Each light holds **position** (updatable every frame), **radius**, **color**, and **intensity** (or equivalent split so **pass strength** can fade or pulse). Coordinates match the shader’s math (recommended: **canvas/viewport space** in pixels, from screen/UI via the viewport’s canvas transform).
- **Attenuation**: Smooth falloff using distance vs `radius` (e.g. inverse-square with clamp, or smoothstep on `distance/radius`)—kept simple so motion still reads **2D**.
- **Push model**: Each frame (or when the autoload notifies), lit materials read the **latest** global + point parameters (or use **global shader parameters** if we standardize on that for CanvasItem—implementation detail in tasks).
- **Rationale**: Gameplay needs **moving** lights and **animated** strengths; caps keep GL Compatibility predictable.
- **Alternatives**: World-space 2D positions only — simpler for level design but not what was asked; can be a later additive mode.

### 6. How lit entities integrate with `AnimatedEntity`

- **Choice**: Prefer a **subclass** (e.g. `LitAnimatedEntity`) or a **thin wrapper** that extends behavior without breaking existing scenes: default `AnimatedEntity` remains unshaded; test scene swaps to lit variant or enables lit material via export.
- **Rationale**: No **BREAKING** change for consumers already instancing `AnimatedEntity`.
- **Alternatives**: Add lighting directly on `AnimatedEntity` behind exports — acceptable if defaults preserve current visuals; subclass is clearer separation.

### 7. Static sheets

- **Choice**: **Phase with animated path first**. If `StaticSpriteSheetLookup` uses the same half-diffuse / half-normal layout, reuse the same shader and binding pattern; if static layout differs, document static support as follow-up in tasks.
- **Rationale**: Proposal mentions both; implementation can land animated + test scene first.

## Risks / Trade-offs

- **[Risk] Shader array limits / GL Compatibility** → Mitigation: fixed max lights; document cap; fail gracefully (ignore excess lights or clamp).
- **[Risk] Normal map convention mismatch with art** → Mitigation: document channel layout and optional flip; tune in test scene with real assets.
- **[Risk] Per-frame uniform updates for many sprites** → Mitigation: **dynamic lighting assumes frequent uniform updates**—prefer **one shared material** or **global parameters** so sun/points are pushed once per frame; sprites only refresh **atlas textures** when sprite frames change. Profile if many unique materials exist.
- **[Risk] AtlasTexture filtering bleeding between diffuse/normal** → Mitigation: use appropriate filter/repeat modes (typically clip + nearest for pixel art); align with existing sprite settings.

## Migration Plan

- **Consumers**: Existing projects using `AnimatedEntity` without the new material behave unchanged.
- **Adoption**: Opt in by using lit subclass/scene or assigning the lit shader material; test scene updated to demonstrate configuration.
- **Rollback**: Remove material assignment or revert to base entity; no data migration.

## Open Questions

- Exact **normal map channel** layout (RGB tangent vs AG packed) once sample art is available.
- Final **max point lights** and whether lights use **screen pixels** vs **normalized** coords (decision above favors canvas-space from screen via transform; confirm in implementation).
- Whether the fixed sun direction is expressed in **canvas/world** vs **viewport/screen** axes (no node rotation requirement either way; spec should name one).

