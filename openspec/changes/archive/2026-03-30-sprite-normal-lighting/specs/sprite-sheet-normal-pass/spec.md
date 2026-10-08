# Spec Delta: sprite-sheet-normal-pass

## ADDED Requirements

### Requirement: Animated sheet stores diffuse and normal blocks

An animated sprite sheet SHALL be treated as two stacked vertical blocks of equal height: the **upper** block SHALL be diffuse albedo; the **lower** block SHALL be tangent-space (or project-defined) **normals** for the same cells. Each block SHALL contain eight direction rows (ordering consistent with existing addon direction indexing) and a fixed column count of animation frames.

#### Scenario: Sheet height splits into two halves

- **WHEN** an animated sheet texture’s pixel height is inspected for layout
- **THEN** the diffuse block SHALL occupy the top half and the normal block SHALL occupy the bottom half, each with eight rows per frame column

---

### Requirement: Lookup resolves matching diffuse and normal regions

The addon’s animated sprite sheet lookup SHALL resolve both diffuse and normal `AtlasTexture` (or equivalent) regions for the same logical cell: same `entity`, `action`, direction index, and frame index. The normal region SHALL reference the same underlying sheet image as the diffuse region for that lookup.

#### Scenario: Same indices yield paired regions

- **WHEN** `get_texture` (or the project’s equivalent API) is called for a given entity, action, direction, and frame with diffuse type and again with normal type
- **THEN** both results SHALL target the same source texture and the same frame column and direction row within their respective blocks

---

### Requirement: Lit sprite path keeps normal in sync with diffuse

Any addon-provided code path that applies pseudo-lighting to an animated entity SHALL refresh the bound normal map whenever it refreshes the diffuse atlas for that entity, using the same `entity`, `action`, direction, and `frame` indices in the same update (e.g. the same `update_sprite` or equivalent call chain).

#### Scenario: Frame advance updates both maps

- **WHEN** an animated lit sprite advances to the next frame or changes action or facing
- **THEN** the material or renderer SHALL receive an updated diffuse sample and an updated normal sample that share the same logical frame indices

---

### Requirement: Static sheets (optional same layout)

If the addon supports static sprite sheets with the same half-diffuse / half-normal layout, the static lookup SHALL resolve diffuse and normal regions with the same pairing rules as animated sheets, subject to the static grid API. If static sheets do not use this layout, the addon documentation SHALL state which static layouts are supported.

#### Scenario: Documented static behavior

- **WHEN** a consumer uses static sheet lookup for lit rendering
- **THEN** the documented API SHALL state whether half-diffuse / half-normal pairing applies or static lit sprites are unsupported until implemented
