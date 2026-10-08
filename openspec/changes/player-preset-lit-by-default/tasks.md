## 1. Update preset

- [ ] 1.1 In `addons/godot-pixel-core/entity/characters/player.tscn`, add an override block on the inherited `AnimatedEntity` child that sets `use_2d_normal_lighting = true`. The block SHALL use the inherited node name `AnimatedEntity` with `parent="."`, no `type=`, no `instance=`, no `unique_id=` — only the changed property — consistent with the "Preset scenes do not re-instance the inherited presenter" rule.
- [ ] 1.2 Confirm the resulting `.tscn` still has exactly **one** `AnimatedEntity` reference (the inherited child from `player_entity.tscn`) and that the existing `CollisionShape2D` override and root overrides (`entity_name`, `movement_speed`, `frame_rate`) are unchanged.

## 2. Verify body scenes remain lighting-neutral

- [ ] 2.1 Re-read `addons/godot-pixel-core/entity/player_entity.tscn` and confirm its inherited `AnimatedEntity` block sets only `entity_name = "player"` (no `use_2d_normal_lighting` override).
- [ ] 2.2 Re-read `addons/godot-pixel-core/entity/character_entity.tscn` and confirm its inherited `AnimatedEntity` block adds no `use_2d_normal_lighting` override.
- [ ] 2.3 Confirm `addons/godot-pixel-core/entity/animated_entity.tscn` still declares `use_2d_normal_lighting = false` as the root default.

## 3. Verify in dev harness (Godot 4.6 editor)

- [ ] 3.1 Open `addons/godot-pixel-core/entity/characters/player.tscn` in Godot 4.6 and confirm: one `AnimatedEntity` child under the inherited body, with `use_2d_normal_lighting = true` shown in the inspector as an override; one `CollisionShape2D` child with the tuned capsule and rotation; root `PlayerEntity` with the tuned `entity_name`, `movement_speed`, `frame_rate`.
- [ ] 3.2 Open `main.tscn` and confirm the `Player` instance's child `Sprite2D` shows a `CanvasItemMaterial(LIGHT_MODE_NORMAL)` and a `CanvasTexture` once the scene runs (use Remote tree at runtime if needed); the player sprite SHALL render shaded by `DirectionalLight2D` rather than uniformly tinted by `CanvasModulate`.
- [ ] 3.3 Play `main.tscn` (`F5` after setting it as the run scene, or run directly without changing project's main scene); move the player and confirm walk/idle animations advance and that the sprite responds to the directional light's angle (rotation `0.7853982`).

## 4. Spec sync

- [ ] 4.1 Run `openspec validate player-preset-lit-by-default --strict`; expect pass.
- [ ] 4.2 Cross-read the new "Tuned character presets opt in to engine 2D normal lighting" requirement against the existing `sprite-presentation` requirements ("Presenter node shape", "Shared presentation properties", "Engine-lit presenter behavior", "Non-character reuse", "Tile map integration is non-hierarchical", and the freshly-added "Preset scenes do not re-instance the inherited presenter" from `fix-main-tscn-player-preset`); confirm no contradictions.
