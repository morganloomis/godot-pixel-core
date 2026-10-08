## 1. Apply this rebase to the sprite-shadows change folder

- [ ] 1.1 Replace `openspec/changes/sprite-shadows/proposal.md` so its "Why" / "What Changes" reference per-pass `contact.png`, the `SpriteSheetPass.CONTACT` enum addition, and the unified `AnimatedEntity` + `use_2d_normal_lighting` model; remove references to the combined two-block sheet and to `LitAnimatedEntity`.
- [ ] 1.2 Replace `openspec/changes/sprite-shadows/design.md` to describe:
  - per-pass contact lookup via `AnimatedSpriteSheetLookup.get_texture(..., SpriteSheetPass.CONTACT)`,
  - frame sync from `AnimatedEntity.update_sprite()` (no parallel subclass),
  - a separate child `CanvasItem` carrying the shadow `ShaderMaterial`,
  - smear-direction derivation from a primary `DirectionalLight2D` with an optional manual override export,
  - fixed-tap fragment shader as the default with an opt-in `SubViewport` higher-quality path deferred.
- [ ] 1.3 Replace `openspec/changes/sprite-shadows/specs/sprite-contact-shadow-mask/spec.md` with the rebased text from this change.
- [ ] 1.4 Replace `openspec/changes/sprite-shadows/specs/sprite-directional-foot-shadow/spec.md` with the rebased text from this change.
- [ ] 1.5 Replace `openspec/changes/sprite-shadows/specs/test-scene/spec.md` with the rebased text from this change (uses `entity_name = "player"`).
- [ ] 1.6 Create `openspec/changes/sprite-shadows/tasks.md` with the implementation breakdown (lookup pass enum addition, lookup path resolver, `AnimatedEntity` update, foot-shadow node + shader, test wiring, README updates, verification).

## 2. Sequencing

- [ ] 2.1 Confirm `align-test-scene-with-player-art` has been applied (or is being applied in the same batch) so `sprite-shadows/specs/test-scene/spec.md` does not conflict with main `test-scene` spec.
- [ ] 2.2 Confirm `remove-stale-entity-bundles` has been applied so the rebased `sprite-shadows` proposal does not assume `LitAnimatedEntity` exists.

## 3. Spec sync

- [ ] 3.1 Run `openspec validate sprite-shadows --strict` after the file replacements; expect pass.
- [ ] 3.2 Run `openspec validate rebase-sprite-shadows-on-per-pass-layout --strict`; expect pass.
- [ ] 3.3 Optionally run `openspec status --change sprite-shadows` to confirm artifact dependencies are satisfied (proposal, design, specs, tasks all present).
