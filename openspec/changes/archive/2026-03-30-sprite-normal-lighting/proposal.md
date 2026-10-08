## Why

Sprite sheets in this project combine diffuse and normal data (each half of the texture). The addon already drives diffuse frames from animation, but there is no way to use the normal half for shading or to keep it aligned with the diffuse over time. Adding a small pseudo-lighting model (ambient + directional “sun” + screen-space point lights) lets pixel art read better in scenes without a full 3D lighting pipeline.

## What Changes

- Treat combined sheets as having a **diffuse region** and a **normal map region** (layout convention documented and enforced in lookup/entity pipeline).
- When an animated entity advances or switches frames, **the normal sample SHALL stay in sync** with the diffuse frame (same frame index / same UV region logic).
- Introduce a **pseudo-lighting** path for lit sprites: combine **ambient** (uniform boost to diffuse, independent of normals), a **global directional / scene light** (direction and strength in a defined space—specified in design), and **zero or more point lights** with **screen-space positions** (and radius, color, per-pass intensity as needed).
- Lighting parameters SHALL be **runtime-driven**: **point light positions** may move during gameplay; **intensities** of ambient, directional, and point contributions SHALL be changeable over time (e.g. tweens, time-of-day, spells). The **global scene light** direction and/or strength SHALL likewise be updatable at runtime—not bake-time only.
- Shading SHALL use the normal pass to modulate diffuse for directional and point contributions; ambient SHALL NOT use the normal map for its term.
- **Aesthetic**: The model stays appropriate for a **pixel-perfect 2D** game (readable, simple terms—not a 3D PBR look).
- **Constraint**: Pseudo-lighting **does not** need to support **`Sprite2D` (or parent) rotation** for correct shading; sprites are treated as having **fixed orientation** relative to the lighting basis (eight facing directions remain sheet-driven, not node rotation).
- Extend the in-repo **test scene** to demonstrate lighting so the feature stays verifiable.

## Capabilities

### New Capabilities

- `sprite-sheet-normal-pass`: Combined diffuse/normal sheet layout; resolving and updating the normal region alongside diffuse for static and animated sprites.
- `sprite-pseudo-lighting`: Configurable, **dynamically updatable** ambient, global directional/scene light, and screen-space point lights; how terms combine with normals and diffuse while staying **2D / pixel-art appropriate**.

### Modified Capabilities

- `test-scene`: Requirements SHALL be extended so the test scene exercises pseudo-lighting (or clearly configures it) in addition to the existing PlayerEntity / lookup behavior, without breaking current scenarios.

## Impact

- **Addon**: `addons/godot-pixel-core/` — sprite sheet lookup types, `AnimatedEntity` / related entity or material wiring, and any new small API (resources, nodes, or shaders) for lighting parameters.
- **Rendering**: Likely custom shader or canvas item path (exact approach in `design.md`); Godot version and CanvasItem vs Sprite2D constraints apply.
- **Test**: `test/test_scene.tscn` and possibly `test/test_scene.gd`, plus test art if normals need sample assets.
- **Docs**: Addon README or asset docs may note the half-diffuse / half-normal convention and lighting setup.
