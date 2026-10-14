# Tasks

## 1. Caster publish

- [x] 1.1 Add a four-slot caster snapshot on `IsoLightingConfig` (atlas, region, sheet size, origin, cell size) plus register/unregister hooks, and verify a manual snapshot can be written and read back from a material
- [x] 1.2 Register `IsoGroundShadow` on enter/exit and publish its current field when visible, and verify a node with no `shadow_map.png` does not occupy a slot

## 2. Receive march

- [x] 2.1 March published fields from `LIGHT_VERTEX` in `iso_lit.light()` for height ≥ 1 px, skip matching `shadow_self_origin`, and verify a synthetic wall behind a cylinder darkens only where the slab test predicts
- [x] 2.2 Skip the receive march at height 0 and verify a flat quad stays undarkened when only the receive path is active
- [x] 2.3 Write `shadow_self_origin` from the lit presenter each frame and verify a presenter whose origin matches the caster is not flattened by its own field

## 3. Probe and docs

- [x] 3.1 Add `test/iso_wall_shadow_probe` (analytic cylinder + wall/prop column) and verify it prints in-range tip height, height-0 skip, and self-skip
- [x] 3.2 Document raised receive in the addon README (existing R/G/A, height-0 stays on the ground quad) and verify the Ground shadows section still describes the floor path
