## Why

Isometric billboard sprites read better when the ground shows **directional contact at the feet** without paying for full cast shadows or 3D shadow casters. Artists can already paint diffuse (and optional normals); a **contact mask** plus a **light-aligned smear** gives foot-accurate, soft shadows that stay cheap and 2D-friendly.

## What Changes

- Introduce an **optional artist-authored mask** per animated sheet: same grid, pivot, and UV layout as diffuse (and optional normal), encoding **contact / height-from-ground** (strong at planted feet, weak when a foot lifts). Produced in art tools—not required to be procedural at runtime.
- At runtime, use that mask as a **source term for shadow intensity** only where contact is strong, then **integrate or smear along the light direction** projected onto the isometric ground plane so shadows elongate and fall off naturally.
- Document how **world light direction** maps to **ground-plane sampling** and **sprite UV offsets** so isometric games get predictable results.
- Prefer **shaders and optional small render targets** over voxels, depth prepasses, or full-body silhouette shadows; scope explicitly excludes crisp, full-body cast shadows.
- Extend the in-repo **test scene** so the behavior stays visible and verifiable once implemented.

## Capabilities

### New Capabilities

- `sprite-contact-shadow-mask`: Mask texture convention (channels, value meaning, alignment with diffuse/normal regions); loading and **frame/animation sync** with the animated sprite pipeline.
- `sprite-directional-foot-shadow`: Runtime shadow term from the mask; **directional smear** along projected light on the floor; **composite** with the ground or scene; **performance expectations** vs heavier approaches; policy for **multiple lights** (e.g. primary directional vs accumulate).

### Modified Capabilities

- `test-scene`: Requirements SHALL be extended so the test scene exercises foot contact shadows (or clearly configures them) in addition to existing PlayerEntity / lookup behavior, without breaking current scenarios.

## Impact

- **Addon**: `addons/godot-pixel-core/` — lookup or entity wiring for an optional mask pass, materials/shaders (and any small API for light direction and shadow strength), documented alongside existing sprite and optional normal passes.
- **Rendering**: GL Compatibility–friendly path (exact approach in `design.md`); may use multi-pass or a compact RT for separable directional blur.
- **Test**: `test/test_scene.tscn` / `test/test_scene.gd` and optional mask art under `test/` when samples are needed (art generation remains out of scope for implementation tasks unless spec requires placeholder assets).
- **Docs**: README or asset docs for mask authoring and naming next to diffuse/normal conventions.
