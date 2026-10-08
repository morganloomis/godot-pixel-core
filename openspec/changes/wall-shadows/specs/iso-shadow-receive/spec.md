# Spec Delta

## Purpose

Lets raised lit surfaces darken under the same occupancy-field shadows that already land on the floor, without new shadow-map channels.

## ADDED Requirements

### Requirement: Raised surfaces receive occupancy shadows
A lit fragment whose height above the ground is at least one pixel SHALL lose the contribution of a light when that light's ray intersects a published caster occupancy field.

#### Scenario: Wall behind a known caster
- **WHEN** a vertical wall sits beyond a cylinder caster of known height and a point light shines from the opposite side
- **THEN** wall pixels whose analytic ray through the cylinder intersects `[bottom, top]` are darker than wall pixels whose ray clears the cylinder

#### Scenario: Vertical prop receives the same field
- **WHEN** a raised prop (height ≥ 1 px) sits on the far side of the same published caster
- **THEN** the prop loses that light on pixels the occupancy slab blocks, using the existing R/G/A channels only

### Requirement: Ground fragments stay on the floor path
A lit fragment at height 0 SHALL NOT apply the raised-receive march. Floor darkening remains the existing ground-shadow quad.

#### Scenario: Flat floor ignores receive march
- **WHEN** a height-0 surface is lit and a caster field is published, but no ground-shadow quad is drawn
- **THEN** the floor is not darkened by the receive path

### Requirement: A caster does not flatten itself
A lit presenter SHALL ignore a published occupancy field whose origin is its own ground origin.

#### Scenario: Self field is skipped
- **WHEN** a lit presenter's self origin matches a published caster origin
- **THEN** that presenter's pixels are not darkened by that field

### Requirement: Existing occupancy encoding is unchanged
`shadow_map.png` SHALL remain R = bottom, G = top (1 step = 1 px), A = coverage. No facing-angle or screen-height channel is required for receive.

#### Scenario: Missing extra channels still shadows a wall
- **WHEN** a caster field provides only R, G, and A
- **THEN** a raised receiver still occludes lights against that field
