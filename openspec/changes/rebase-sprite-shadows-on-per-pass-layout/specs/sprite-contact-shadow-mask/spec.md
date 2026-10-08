# Spec Delta: sprite-contact-shadow-mask

## MODIFIED Requirements

### Requirement: Contact texture path and layout

For each animated action folder at `{animated_sheet_root}/{entity}/{action}/`, an **optional** contact mask MAY exist at `{animated_sheet_root}/{entity}/{action}/contact.png`. When present, the image SHALL share the **same pixel width, height, cell width, cell height, and 8 × frame_count grid** as `diffuse.png` for that action, exactly as required for `normal.png` by `sprite-sheet-layout` and `sprite-sheet-normal-pass`. There SHALL NOT be a sidecar `{action}_contact.png` next to a combined diffuse/normal PNG; that layout no longer exists.

#### Scenario: Contact path resolves under per-pass folder

- **WHEN** the lookup resolves action `"walk"` for entity `"player"` and `res://.../player/walk/contact.png` exists
- **THEN** the contact resolver SHALL load that path as the source for contact-mask regions for that action

#### Scenario: Missing contact file disables mask for that action

- **WHEN** `contact.png` does not exist for a given `(entity, action)`
- **THEN** the contact resolver SHALL report **no** contact atlas for that action **AND** the addon SHALL NOT treat this as an error (consistent with `sprite-sheet-layout` → "Optional pass files")

#### Scenario: Contact size mismatch is a debug-only warning

- **WHEN** `contact.png` exists but its pixel dimensions or grid do not match `diffuse.png`
- **THEN** in debug builds the addon SHALL emit `push_warning` (mirroring `_warn_pass_size_mismatch` in `AnimatedSpriteSheetLookup`), and SHALL still return an `AtlasTexture` whose region is computed against `diffuse.png` dimensions

---

### Requirement: Contact sample semantics

The contact mask SHALL encode **ground contact / height-from-ground** in **character sprite space**: **higher** sample values SHALL mean **stronger** foot-ground contact (e.g. planted feet), and **lower** values SHALL mean **weaker** contact (e.g. lifted foot). The **channel** used (e.g. red or luminance) SHALL be documented in the addon README's animated pass table; unused channels SHALL be ignored unless documented otherwise.

#### Scenario: Single meaningful channel

- **WHEN** a texel on the contact atlas is sampled for shading
- **THEN** the implementation SHALL derive a scalar **contact strength** from the documented channel(s) only

---

### Requirement: Frame and direction synchronization

Whenever `AnimatedEntity.update_sprite()` refreshes the **diffuse** region for a given `(entity, action, direction, frame)`, the **contact** region for the **same** indices SHALL be resolved in the **same** call (consistent with the existing normal-pass refresh on the lit `CanvasTexture` path) so diffuse and contact cannot desynchronize.

#### Scenario: Walk frame advance keeps contact aligned

- **WHEN** the `AnimatedEntity` advances from frame `n` to frame `n+1` for the current action and direction
- **THEN** the contact atlas region SHALL update to the cell `(direction, n+1)` matching the diffuse cell

#### Scenario: Action switch keeps contact aligned

- **WHEN** the entity switches from action `"idle"` to `"walk"`
- **THEN** the contact resolver SHALL use the new action's `contact.png` (under `{entity}/{new_action}/`) if present **AND** the region SHALL match the current direction and frame for that action

#### Scenario: Lit mode is not a prerequisite

- **WHEN** the presenter has `use_2d_normal_lighting = false` but a foot-shadow consumer is attached
- **THEN** the contact lookup SHALL still resolve cells on each frame update; contact behavior is **orthogonal** to lit mode and does not require swapping presenter class

---

### Requirement: Contact atlas output via SpriteSheetPass

`SpriteSheetLookupBase.SpriteSheetPass` SHALL include a value (`CONTACT` or an equivalent documented name) so the existing animated lookup API resolves contact regions uniformly with diffuse/normal/specular/occlusion:

- `AnimatedSpriteSheetLookup.get_texture(entity, action, direction, frame, SpriteSheetLookupBase.SpriteSheetPass.CONTACT)` SHALL return an `AtlasTexture` for the same logical cell as the diffuse pass when `contact.png` exists.
- The base class's `animated_pass_texture_path` SHALL map the new enum value to filename `contact.png`, following the same `{root}/{entity}/{action}/{pass}.png` rule as other passes.
- Cache keys SHALL include the contact path so the contact texture is loaded at most once per scene run, consistent with `sprite-sheet-lookup` → "Base class owns lookup and caching".

#### Scenario: Atlas region matches diffuse grid math

- **WHEN** `contact.png` for `(entity, action)` matches diffuse dimensions and grid
- **THEN** cell `(direction_index, frame_index)` SHALL map to the identical logical cell as the diffuse pass for the same indices, computed by `compute_rect_animated` exactly as for normals

#### Scenario: Pass enum reachable from game code

- **WHEN** game code on a foot-shadow consumer queries `AnimatedSpriteSheetLookup.get_texture(..., SpriteSheetLookupBase.SpriteSheetPass.CONTACT)`
- **THEN** the call SHALL compile and resolve without requiring access to private helpers; the addon API surface SHALL expose the new pass alongside the existing four

## REMOVED Requirements

### Requirement: Two-block sheet contact sidecar (`{action}_contact.png`)

**Reason**: superseded by the per-pass file layout introduced by `sprite-sheet-layout`. The combined-PNG layout (top diffuse / bottom normal) no longer exists, so a sidecar named with an `_contact` suffix next to a single-file action sheet is no longer applicable.

**Migration**: existing contact masks (if any) SHOULD be moved from `{animated_root}/{entity}/{action}_contact.png` to `{animated_root}/{entity}/{action}/contact.png`. The mask itself does not need re-authoring; only its location and filename change.
