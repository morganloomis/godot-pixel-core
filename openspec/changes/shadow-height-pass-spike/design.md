## Context

- **Engine**: Godot **4.6**, **GL Compatibility**. Foot shadows must stay within a **fixed tap budget** per fragment — no 3D shadow maps, no `LightOccluder2D` polygons, no extra `SubViewport` in the default spike path.
- **Presenter today**: `AnimatedEntity` is a `Node2D` with a child `Sprite2D`. Lit mode (`use_2d_normal_lighting`) bakes diffuse + normal cells into a `CanvasTexture` and uses `CanvasItemMaterial` with `LIGHT_MODE_NORMAL` so `DirectionalLight2D` affects the body. Optional passes (`normal.png`, `specular.png`, `occlusion.png`) resolve via `SpriteSheetLookupBase.SpriteSheetPass` under `{animated_sheet_root}/{entity}/{action}/{pass}.png`.
- **Hypothesis**: An optional **ground-projected height / contact** pass, smeared at runtime along the inverse light direction, produces readable foot-anchored shadows with leg separation and light-dependent length — without touching the lit sprite path.
- **Prior art in-repo**: `sprite-shadows` and `rebase-sprite-shadows-on-per-pass-layout` describe the same technique under `contact.png` with fuller integration specs. This spike is **isolated and provisional**; it may merge into that track or be deleted.
- **Stakeholders**: Addon authors (implementation), artists (encoding convention), consumers like Untombed (no integration required for the spike).

## Goals / Non-Goals

**Goals:**

- Prove the height-field + directional smear approach on the **current** per-pass layout and `AnimatedEntity.update_sprite()` sync path.
- Keep the feature **opt-in** (`use_ground_shadow = false` by default) with **zero behavior change** when disabled.
- Draw shadows on a **separate unshaded** `Sprite2D` child (`z_index` below body) so engine 2D normal lighting on the character is untouched.
- Resolve pass cells through the existing lookup API (`get_texture(..., SpriteSheetPass.SHADOW)`).
- Drive `smear_dir` and shadow length from one scene `DirectionalLight2D`, with a manual `Vector2` override export.
- Validate visually in `test/test_scene.tscn` with a minimal placeholder pass (one action / one direction / one frame is enough).
- Structure code so the spike can be **removed in one pass** (dedicated shader file, clearly bounded edits to `AnimatedEntity` and lookup enum).

**Non-Goals:**

- Consumer game integration, production art across all frames, or final tuning.
- `PointLight2D` / multi-light fusion.
- Floor-tile shader compositing, perfect iso y-sort with multiple characters, or `CanvasModulate`-aware shadow alpha.
- Merging or archiving `sprite-shadows` in this change.
- Half-res `SubViewport` blur (optional follow-up only if fixed taps fail).

## Decisions

### 1. Pass filename and enum: `shadow.png` + `SpriteSheetPass.SHADOW`

- **Choice**: Add `SHADOW` to `SpriteSheetLookupBase.SpriteSheetPass`, mapped to `shadow.png` via `animated_pass_texture_path`. Encoding uses **luminance** (red channel or `dot(rgb, vec3(0.299, 0.587, 0.114))` in shader): **1.0 = ground contact (feet)**, **0.0 = no contact / highest body**.
- **Rationale**: Keeps the spike **namespace-distinct** from in-flight `contact.png` work so both can coexist or this change can be deleted without migration. The “puddle preview” (zero smear) is the raw pass composited under the character.
- **Alternatives considered**:
  - **`contact.png` + `CONTACT`** (per `rebase-sprite-shadows`) — rejected for the spike: couples to unfinished change and harder to rip out.
  - **Reuse `occlusion.png`** — rejected: AO semantics ≠ cast-shadow height; confuses artists.

### 2. Where shadow lives: child `Sprite2D` on `AnimatedEntity`

- **Choice**: Add `ShadowSprite2D` as the **first child** of `AnimatedEntity` (before body `Sprite2D`), `z_index = -1`, `texture_filter = nearest`, `visible` gated by `use_ground_shadow`. Body `Sprite2D` unchanged.
- **Rationale**: Matches body-composes-presenter pattern; one `update_sprite()` refreshes diffuse, normal, and shadow cells together. No new scene type or `LitAnimatedEntity` subclass.
- **Alternatives considered**:
  - **Separate companion scene** — rejected for spike: more wiring for consumers; can extract later if kept.
  - **Shader on body sprite** — rejected: pollutes lit path; cannot darken floor beneath feet cleanly.

### 3. Shadow rendering: unshaded custom shader, not engine lighting

- **Choice**: `ShaderMaterial` on the shadow child using new `addons/godot-pixel-core/lighting/shadow_height_project.gdshader` with `render_mode blend_mul` (or `blend_mix` with `vec4(0,0,0,alpha)` if `blend_mul` interacts badly with `CanvasModulate`). Material `light_mode` is **unshaded** — the shader does not set `NORMAL_MAP` and does not receive `DirectionalLight2D` accumulation.
- **Rationale**: Cast shadow is a **ground darkening decal**, not a lit surface. Engine 2D lights already handle character normals separately ([CanvasItemMaterial](https://docs.godotengine.org/en/stable/classes/class_canvasitemmaterial.html)).
- **Alternatives considered**:
  - **`LightOccluder2D`** — rejected: hard polygon shadows, poor fit for pre-rendered sprites.
  - **Lit shadow receiving floor normals** — rejected: scope explosion; spike darkens via alpha/multiply only.

### 4. Smear algorithm: fixed-tap gather along `smear_dir` (default path)

- **Choice**: Fragment shader samples `shadow.png` at `UV + k * smear_dir * step` for `k` in `0..N-1` (e.g. **8 taps**), with weights that fall off with `k`. Per-tap contribution scales by **contact strength** at the sample and by **height factor** `(1.0 - contact)` so feet (high contact) smear less than torso. Combine: `shadow_alpha = sum(w_k * sample_k * height_factor_k)`.
- **Rationale**: Predictable **O(taps)** cost; no extra render target; aligns with rebased `sprite-directional-foot-shadow` spec. Gather (walk toward light) tends to produce softer, more stable smears than scatter for pixel art.
- **Alternatives considered**:
  - **Separable blur in `SubViewport`** — deferred: heavier; spike only if taps prove insufficient.
  - **Scatter splat** — rejected for v1: harder to clamp at atlas edges.

### 5. Light direction: `DirectionalLight2D` → uniforms, not autoload

- **Choice**: `@export var shadow_light: NodePath` on `AnimatedEntity` (optional). When set and resolved, each frame (or on `NOTIFICATION_TRANSFORM_CHANGED` / `_process`) reads the light's `rotation` and maps it to a normalized 2D `smear_dir` uniform: shadow extends **opposite** the incoming light on the canvas plane. `@export var shadow_direction_override: Vector2` when non-zero replaces the derived vector. `@export var shadow_length_scale: float` scales UV smear step; optionally scale from light `height` (lower sun → longer shadows).
- **Rationale**: Matches how consumers already use `DirectionalLight2D` for normals ([DirectionalLight2D](https://docs.godotengine.org/en/stable/classes/class_directionallight2d.html)). No dependency on legacy `SpriteLighting` autoload.
- **Alternatives considered**:
  - **Hard-coded smear axis** — rejected: fails the spike success criterion (rotate light → shadow moves).
  - **Per-pixel direction from `PointLight2D`** — out of scope.

### 6. Texture binding: `AtlasTexture` directly on shadow sprite

- **Choice**: Shadow child uses `AtlasTexture` from lookup (same as unlit diffuse path), **not** baked `ImageTexture` / `CanvasTexture`.
- **Rationale**: Shadow pass is single-channel weights; no `CanvasTexture` normal slot needed. Avoids duplicating `_lit_cell_image_pair_cache` logic.
- **UV edge safety**: Shader clamps taps outside the atlas region to zero contact (prevents bleed into neighbouring cells).

### 7. API surface (minimal, deletable)

- **Choice**: On `AnimatedEntity`:
  - `@export var use_ground_shadow: bool = false`
  - `@export var shadow_light: NodePath` (default empty; test scene sets to scene light)
  - `@export var shadow_direction_override: Vector2 = Vector2.ZERO`
  - `@export var shadow_length_scale: float = 0.15` (tune in test scene)
  - `@export var shadow_opacity: float = 0.5`
- **Rationale**: Single opt-in flag; no changes to `CharacterEntity` / `PlayerEntity` presets in the spike (test harness wires it explicitly).
- **Alternatives considered**:
  - **Default-on in player preset** — rejected: violates spike isolation.

### 8. Test harness wiring

- **Choice**: `test/test_scene.gd` sets `use_ground_shadow = true` and `shadow_light` to the scene's `DirectionalLight2D`. Placeholder `shadow.png` under `test/art/sprite/player/idle/` only (art can be a minimal hand-painted or generated greyscale stub — implementation tasks stay code-only; placeholder may be a 1×1 or copied diffuse silhouette stub committed separately if needed for CI).
- **Rationale**: Exercises the enabled path without changing addon presets shipped to consumers.

## Risks / Trade-offs

- **[Risk] Spike duplicates `sprite-shadows` / `contact.png` work** → Mitigation: document relationship in README; keep `shadow.png` naming; merge or delete in a follow-up change after evaluation.
- **[Risk] `shadow.png` missing or wrong size** → Mitigation: hide shadow child; debug `push_warning` mirroring `_warn_pass_size_mismatch`; no crash.
- **[Risk] UV smear bleeds across atlas cells** → Mitigation: clamp UV to atlas region; cap `shadow_length_scale` relative to cell size; tune in test scene.
- **[Risk] `blend_mul` + `CanvasModulate` double-darkens** → Mitigation: test in harness; switch to `blend_mix` with explicit alpha if needed.
- **[Risk] y-sort with multiple characters** → Mitigation: accept imperfect ordering for spike; document that shadow sorts with presenter parent; foot-anchored independent sort is a follow-up.
- **[Risk] Gather taps too few for long shadows** → Mitigation: expose tap count / step as shader uniforms; consider `SubViewport` path only if visual fails.
- **[Trade-off] Soft stylized vs physically correct** → Accepted: readable contact + streak over geometric accuracy.
- **[Trade-off] Code in `AnimatedEntity` vs helper** → Accepted: keep shadow refresh inside `update_sprite()` for sync; extract `GroundShadowHelper` only if file grows.

## Migration Plan

- **Deploy**: Merge addon changes; consumers see no change until `use_ground_shadow = true` and `shadow.png` exists.
- **Adoption**: Opt in per `AnimatedEntity` instance; set `shadow_light` NodePath to scene sun.
- **Rollback**: Set `use_ground_shadow = false` or delete `shadow.png`; remove shadow child edits in a single revert. No migration of existing `diffuse.png` / `normal.png` assets.
- **Convergence with `sprite-shadows`**: If the spike is kept, a follow-up may rename `shadow.png` → `contact.png`, archive this change, and merge specs into `sprite-shadows`. If rejected, delete enum value, shader, and shadow child wiring.

## Open Questions

- Does **8-tap gather** produce acceptable leg separation on walk cycles, or do legs merge at typical `shadow_length_scale`?
- **`blend_mul` vs `blend_mix`**: which composites correctly with lit floor tiles in the test scene?
- Should `shadow_length_scale` derive automatically from `DirectionalLight2D.height`, or remain a manual export for the spike?
- Import settings for `shadow.png`: **linear** vs **sRGB** (recommend **linear** / treat as data weights).
- Is one committed placeholder `shadow.png` required for headless load, or is “missing pass = hidden shadow” sufficient for automated tests?
