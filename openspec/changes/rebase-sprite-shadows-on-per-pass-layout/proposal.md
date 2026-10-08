## Why

The in-flight change `openspec/changes/sprite-shadows/` is built on the **old** sprite-sheet layout where each action was a single PNG split into a top diffuse block and a bottom normal block, with a sidecar `{action}_contact.png` next to it. That layout was replaced by `sprite-sheet-layout` v1's per-pass files under `{animated_root}/{entity}/{action}/{pass}.png`, and the lit path was reworked around `use_2d_normal_lighting` on `AnimatedEntity` (no `LitAnimatedEntity` subclass). As a result:

- `sprite-shadows/design.md` and `specs/sprite-contact-shadow-mask/spec.md` describe filenames (`{action}.png`, `{action}_contact.png`) that no longer exist.
- The proposal attaches the runtime shadow to `LitAnimatedEntity`, which `entity-hierarchy` deprecates and `remove-stale-entity-bundles` removes from disk.
- `sprite-shadows` has no `tasks.md`, so it never reached an applyable state.

This change rebases the shadow proposal onto the current per-pass layout, the unified `AnimatedEntity` + `use_2d_normal_lighting` model, and the `SpriteSheetLookupBase.SpriteSheetPass` enum, then adds the missing `tasks.md`. The conceptual feature (artist-authored contact mask + light-aligned smear under the feet) is preserved; only the substrate changes.

## What Changes

- Replace the `sprite-shadows/design.md` with a redesign that:
  - Reads the contact texture from `{animated_root}/{entity}/{action}/contact.png` via a new `SpriteSheetPass.CONTACT` enum value (or equivalent named pass), reusing all existing layout, caching, and "missing pass is not an error" rules.
  - Drives shadow updates from `AnimatedEntity.update_sprite()`, not from a parallel `LitAnimatedEntity` subclass.
  - Keeps the directional smear, ground-plane projection, and tap-based blur from the original design but expressed against `AtlasTexture` outputs of the unified lookup.
- Rewrite `sprite-shadows/specs/sprite-contact-shadow-mask/spec.md` so the **ADDED** requirements describe per-pass files and consistent `SpriteSheetPass.CONTACT` lookup semantics.
- Rewrite `sprite-shadows/specs/sprite-directional-foot-shadow/spec.md` so it integrates with the engine-2D-lit presenter (composing with `DirectionalLight2D` direction or a documented `shadow_direction` export) rather than with the legacy `SpriteLighting` autoload.
- Update `sprite-shadows/specs/test-scene/spec.md` so its new scenarios reference `entity_name = "player"` (aligned with `align-test-scene-with-player-art`).
- Add `sprite-shadows/tasks.md` so the change can move from spec to implementation.
- Optionally extend `sprite-sheet-layout` (separately) to formally enumerate `contact.png` as an optional pass; if the existing wording is broad enough, no `sprite-sheet-layout` delta is needed here.

This change does NOT itself implement foot shadows. It rebases the proposal artifacts and the spec deltas of `sprite-shadows` so a future apply step can implement against the current layout.

## Capabilities

### New Capabilities

(none — all touched capabilities are deltas of an existing in-flight change)

### Modified Capabilities

- `sprite-contact-shadow-mask`: rewritten as a per-pass `contact.png` convention with `SpriteSheetPass.CONTACT` lookup, replacing the previous two-block + sidecar convention.
- `sprite-directional-foot-shadow`: rewritten to integrate with engine-2D-lit `AnimatedEntity` (no `LitAnimatedEntity`, no `SpriteLighting` dependency by default).
- `test-scene`: scenarios that demonstrate foot shadows use `entity_name = "player"` and read test art from `res://test/art/sprite/player/...`.

## Impact

- **OpenSpec**: edits inside `openspec/changes/sprite-shadows/` only; `openspec/specs/` is untouched until `sprite-shadows` is eventually archived.
- **Code**: no code changes from this proposal alone. Once `sprite-shadows` is implemented under its rebased plan, `SpriteSheetLookupBase` gains a new `CONTACT` pass and `AnimatedEntity` (or a thin shadow companion) refreshes a contact `AtlasTexture` whenever it refreshes diffuse/normal.
- **Coordination**: depends on `align-test-scene-with-player-art` (test scene reference) and `remove-stale-entity-bundles` (no `LitAnimatedEntity`). Best landed after both.
- **Risk**: low — paperwork-only at this stage. The conceptual feature is unchanged.
