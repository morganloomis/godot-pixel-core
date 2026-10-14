# Proposal

## Why

Floor shadows already fall out of `shadow_map.png` (R/G occupancy, A coverage). Vertical receivers — walls, crates, other characters — do not sample that field, so a torch-lit scene goes dark on the floor and stays fully lit on everything that stands up. The occupancy slab plus receiver `height.png` is already enough; we should use it now rather than invent a third channel.

## What Changes

- Publish each active `IsoGroundShadow` occupancy field (existing R/G/A, no new art) so lit materials can see nearby casters.
- `iso_lit.gdshader` marches those fields from `LIGHT_VERTEX` (raised start height) and attenuates the light that is blocked.
- Skip the receiver's own field so a caster does not flatten itself.
- Leave height-0 fragments on the existing ground quad so floors are not marched twice.
- Add an analytic probe for a vertical wall / prop against a known cylinder caster.
- Document the receive path in the addon README.
- Track `openspec/` in git (it was gitignored).

## Capabilities

### New Capabilities

- `iso-shadow-receive`: raised lit surfaces receive occupancy-field shadows from published casters using the existing `shadow_map.png` channels.

### Modified Capabilities

- None. This repo has no archived specs yet.

## Impact

- `iso_lit.gdshader` and `IsoLitMaterialFactory` (receive march + caster uniforms).
- `IsoLightingConfig` and `IsoGroundShadow` (caster registry / publish).
- `AnimatedEntity` (self-origin so a caster skips its own field).
- `project.godot` only if a new look-knob global is required; caster textures stay per-material.
- New probe under `test/`; README lighting section.
- `pixel_pipe` / `shadow_map.png` encoding is unchanged. Not **BREAKING**.
