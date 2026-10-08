## 1. Shader and material

- [x] 1.1 Add a `canvas_item` shader under `addons/godot-pixel-core/` that samples **diffuse** and **normal** maps, applies **ambient** (no normals), **global directional** (`N·L` with runtime direction + intensity/color), and up to **N** **point lights** (position, radius, color, intensity) with distance attenuation; document the fixed 2D normal basis and optional **Y-flip** uniform.
- [x] 1.2 Choose and implement **N** (max point lights) for **GL Compatibility**, document the cap and overflow behavior in code comments or addon README.
- [x] 1.3 Provide a **ShaderMaterial** preset (`.tres` or code-instantiated) with **nearest** filtering defaults appropriate for pixel art; document any sprite `texture_filter` / material settings consumers must use.

## 2. Runtime lighting API

- [x] 2.1 Implement a **documented** runtime surface (e.g. **autoload** or small API class under the addon) exposing **ambient**, **global directional** (direction + intensity, color if used), and a **bounded** list of point lights with fields required by the spec.
- [x] 2.2 Push lighting uniforms to the lit material(s) **each frame** (or on change) so direction, intensities, and point positions can animate during gameplay; prefer **one shared material** or equivalent so updates are not duplicated per sprite instance unnecessarily.

## 3. Lit sprite integration

- [x] 3.1 Add a **lit** code path (e.g. **`LitAnimatedEntity`** subclass or documented composition) that, on every `update_sprite()` / frame change, sets **both** `get_texture(..., type=0)` and `get_texture(..., type=1)` on the material and keeps **diffuse** on `Sprite2D` consistent with the shader’s expectations.
- [x] 3.2 Export or document that **pseudo-lighting is validated for non-rotated** `Sprite2D` presentation; eight facings remain sheet-driven.

## 4. Documentation and asset notes

- [x] 4.1 Update **`addons/godot-pixel-core/README.md`** and/or **`docs/ASSET_LIBRARY.md`** with the **half-diffuse / half-normal** sheet layout, normal encoding convention used by the shader, and how to drive the lighting API from game code.
- [x] 4.2 If static sheets are deferred, state explicitly in docs that **static lit** support follows the same pairing rules only when implemented (per `sprite-sheet-normal-pass` spec).

## 5. Test scene

- [x] 5.1 Update **`test/test_scene.tscn`** / **`test/test_scene.gd`** to use the lit path and the lighting API while preserving **PlayerEntity**, **lookup root** (`res://test/art/sprite/`), **`entity_id` `girl`**, and existing movement/idle/walk behavior.
- [x] 5.2 Demonstrate **runtime-updated** lighting (e.g. **moving point light** and/or **varying global or ambient intensity**) so the effect is visible without reloading the scene.
- [x] 5.3 Confirm test assets under `test/art/sprite/girl/` remain valid **diffuse/normal** sheets or adjust art only if required for the chosen normal encoding.

## 6. Verification

- [ ] 6.1 Run the project main scene; verify **control**, **walk/idle**, and **visible pseudo-lighting** with **dynamic** parameter changes.
- [ ] 6.2 Quick pass on **GL Compatibility** target (project feature flag): no shader compile errors, frame stable with max lights active.
