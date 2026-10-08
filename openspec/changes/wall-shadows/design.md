# Design

## Context

See proposal.md for motivation. Ground shadows already march `shadow_map.png` as a vertical slab: for each ground texel, occupancy is `[R, G]` in pixels. `iso_lit` already reconstructs a receiver as `LIGHT_VERTEX = (ground_xy, height)` from `height.png`. The missing piece is a receive path, not more authored channels.

Constraints that shape the approach:

- `IsoGroundShadow` is a `blend_sub` quad on the floor. It cannot darken other drawables.
- Binding every caster to every receiver as an autoload fan-out was rejected for look knobs; caster poses still have to move every frame.
- Global `sampler2D` uniforms are less reliable on GL Compatibility than vec/float globals.
- A full-screen receive march on every floor tile would duplicate the cheap ground quad and cost fill rate.

## Goals / Non-Goals

**Goals:**

- Same occupancy query for walls and vertical props as the floor already uses, with start height = receiver height.
- Publish whatever `IsoGroundShadow` nodes are already in the scene; no second authoring pass.
- Keep floor cost on the existing quad.
- Measure the wall case with an analytic cylinder, the same way `iso_shadow_probe` measures the floor.

**Non-Goals:**

- New `shadow_map.png` channels (screen-space height, facing colour).
- Self-shadowing from `height.png` (contact shadows on the same sprite).
- A shared occupancy render target / unlimited casters.
- Replacing `IsoGroundShadow` on the floor.

## Decisions

### 1. Reuse the R/G slab; start the ray at receiver height

The floor march is `ray_height = light_height * s` because the fragment is at height 0. Raised receive is `ray_height = mix(receiver_height, light_height, s)` and `ground_xy = mix(receiver_ground, light_ground, s)`. Screen-space height of the caster top is `G * iso_cos_elevation`; receiver height is already `height.png`. A facing channel would mix lighting (already in `normal.png`) with occupancy.

Alternative considered: B-channel screen height or a colour-coded facing. Rejected — both are reconstructible or already authored on the receiver.

### 2. Receive inside `iso_lit.light()`, not a second wall quad

Walls and props are already `iso_lit` drawables. Multiplying the light contribution by `(1 - occlusion * iso_shadow_strength)` subtracts exactly the blocked light, matching the floor's `blend_sub` intent and keeping culling/masks/energy on the light node.

Alternative considered: extruded shadow volumes or climbing the ground blob up the wall. Rejected — isometric z-sort and corner wrapping fail, and the math is already a 3D slab test.

### 3. Height-0 fragments skip the receive march

Floors stay on `IsoGroundShadow`. Raised fragments (`height >= 1` px after the 0–255 decode) pay the march. This avoids double-darkening and keeps large tile floors cheap.

### 4. Caster publish via a small material registry, four slots

`IsoGroundShadow` registers itself. `IsoLightingConfig` snapshots up to four visible fields (atlas, region, sheet size, ground origin, cell size in px) and writes them onto live `iso_lit` materials created by `IsoLitMaterialFactory`. Unused slots bind a 1×1 empty field.

Why not shader globals for the textures: look knobs stay global; samplers stay per-material so Compatibility does not have to own global textures. The factory already creates every lit material, so the list is the natural place.

Why four: one player plus a few nearby NPCs/props is the expected scene. Distant casters are a later RT problem, not this change.

### 5. Self-skip by ground origin

Each lit presenter writes `shadow_self_origin` (sprite global position + offset). A slot whose origin is within 2 px is ignored. Tiles keep the default far-away origin and receive every slot.

### 6. Cheap reject before the ray march

If the closest point on the receiver→light segment is outside the caster cell (plus softness pad), skip that slot. Worst case remains 8 rays × 24 steps, but only for fragments that could actually hit.

## Risks / Trade-offs

- **[Fill rate on large raised atlases]** → Height-0 skip, AABB reject, four-slot cap. Wall tile layers still cost more than floors; keep `iso_shadow_max_length` tight.
- **[More than four casters]** → Later slots are dropped. Mitigation: publish nearest-to-camera first if we outgrow the cap.
- **[Seam at the wall base]** → Floor uses the quad (height 0), first wall pixel uses receive (height ≥ 1). Same slab math, but different shaders. The analytic probe pins the raised case; do not change the floor probe's accepted bands.
- **[Self-shadow if origin is stale]** → Write `shadow_self_origin` every frame from the presenter, not only when the action sheet rebinds.

## Migration Plan

- Existing scenes with `IsoGroundShadow` start publishing automatically.
- Lit walls/props with `height.png` start receiving with no art change.
- Floor-only tile layers (no height pass) stay unchanged.
- Rollback: revert the receive multiply in `iso_lit` and the publish hooks; ground shadows remain.

## Open Questions

None that block implementation. Slot count can rise later without changing the occupancy contract.
