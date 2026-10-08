# Spec Delta: sprite-contact-shadow-mask

## ADDED Requirements

### Requirement: Contact texture path and layout

For each animated action sheet at `{animated_sheet_root}/{entity}/{action}.png`, an **optional** contact mask MAY exist at `{animated_sheet_root}/{entity}/{action}_contact.png`. When present, the image SHALL have the **same width** as the combined diffuse/normal sheet and a **height equal to one block** of that sheet (half of the combined sheet’s total height). The grid SHALL match the **diffuse block**: **8** direction rows and the same **frame_count** columns as `{action}.png`, with **identical** cell width and height as computed for the diffuse block.

#### Scenario: Contact path resolves next to action sheet

- **WHEN** the lookup resolves action `"walk"` for entity `"player"` and `res://.../player/walk_contact.png` exists
- **THEN** the contact resolver SHALL load that path as the source for contact-mask regions for that action

#### Scenario: Missing contact file disables mask for that action

- **WHEN** `{action}_contact.png` does not exist for a given `(entity, action)`
- **THEN** the contact resolver SHALL report **no** contact atlas for that action **AND** the addon SHALL NOT treat this as an error

---

### Requirement: Contact sample semantics

The contact mask SHALL encode **ground contact / height-from-ground** in **character sprite space**: **higher** sample values SHALL mean **stronger** foot-ground contact (e.g. planted feet), and **lower** values SHALL mean **weaker** contact (e.g. lifted foot). The **channel** used (e.g. red or luminance) SHALL be documented in addon usage notes; unused channels, if any, SHALL be ignored unless documented otherwise.

#### Scenario: Single meaningful channel

- **WHEN** a texel on the contact atlas is sampled for shading
- **THEN** the implementation SHALL derive a scalar **contact strength** from the documented channel(s) only

---

### Requirement: Frame and direction synchronization

Whenever the animated entity updates the **diffuse** frame region for a given `(entity, action, direction, frame)`, the **contact** region for the **same** indices SHALL be resolved in the **same** update pass (or immediately adjacent logic with no intervening state change) so diffuse and contact cannot desynchronize.

#### Scenario: Walk frame advance keeps contact aligned

- **WHEN** the `AnimatedEntity` advances from frame `n` to frame `n+1` for the current action and direction
- **THEN** the contact atlas region SHALL update to the cell `(direction, n+1)` matching the diffuse cell

#### Scenario: Action switch keeps contact aligned

- **WHEN** the entity switches from action `"idle"` to `"walk"`
- **THEN** the contact resolver SHALL use `{new_action}_contact.png` if present **AND** the region SHALL match the current direction and frame for that action

---

### Requirement: Contact atlas output

The contact resolver SHALL expose an `AtlasTexture` (or equivalent Godot sub-region texture) suitable for binding to a `ShaderMaterial`, using the same caching and path rules as other sprite-sheet lookups in the addon. The region rectangle SHALL be computed with the **same** row/column rules as the **diffuse** block of `{action}.png`.

#### Scenario: Atlas region matches diffuse block math

- **WHEN** contact texture dimensions equal half the height of `{action}.png` and the same width
- **THEN** cell `(direction_index, frame_index)` SHALL map to the identical logical cell as the diffuse block of `{action}.png` for the same indices
