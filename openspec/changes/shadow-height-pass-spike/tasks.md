## 1. Lookup pass (`addons/godot-pixel-core/sprite_sheet/`)

- [ ] 1.1 Add `SHADOW` to `SpriteSheetLookupBase.SpriteSheetPass` and map it to `shadow.png` in `animated_pass_texture_path` and `tile_pass_texture_path` (tile pass mapping for consistency; tile shadow out of scope for spike).
- [ ] 1.2 Confirm `AnimatedSpriteSheetLookup.get_texture(..., SpriteSheetPass.SHADOW)` returns an `AtlasTexture` with the same cell math as diffuse when `shadow.png` exists, and an empty/unassigned atlas when absent (no error).
- [ ] 1.3 Confirm debug `push_warning` on shadow pass size mismatch mirrors existing optional-pass behavior.

## 2. Shadow shader (`addons/godot-pixel-core/lighting/`)

- [ ] 2.1 Add `shadow_height_project.gdshader`: `canvas_item`, unshaded, fixed-tap gather along `smear_dir`, luminance-based contact strength, height-dependent smear scaling, UV clamp at atlas edges, `blend_mul` or documented `blend_mix` fallback.
- [ ] 2.2 Expose shader uniforms: `smear_dir`, `shadow_length_scale`, `shadow_opacity` (and tap count / step if tunable).
- [ ] 2.3 Add `shadow_height_material.tres` preset (or factory helper) duplicating the shader preset pattern used by `TileLitMaterialFactory`.

## 3. AnimatedEntity shadow child (`addons/godot-pixel-core/entity/`)

- [ ] 3.1 Add `ShadowSprite2D` child to `animated_entity.tscn` (first child, `z_index = -1`, `texture_filter = nearest`, hidden by default).
- [ ] 3.2 Add exports to `animated_entity.gd`: `use_ground_shadow` (default `false`), `shadow_light`, `shadow_direction_override`, `shadow_length_scale`, `shadow_opacity`.
- [ ] 3.3 In `_ready` / setup: apply shadow `ShaderMaterial` when `use_ground_shadow` is true; hide shadow child when false.
- [ ] 3.4 In `update_sprite()`: when `use_ground_shadow` is true, resolve `SpriteSheetPass.SHADOW` for current indices and assign to shadow child; hide child when pass missing.
- [ ] 3.5 In `_process` (or equivalent): when `use_ground_shadow` is true, push `smear_dir` from `shadow_direction_override` or resolved `DirectionalLight2D` rotation; push `shadow_length_scale` / `shadow_opacity`.
- [ ] 3.6 Confirm `use_ground_shadow = false` (default) leaves lit and unlit body paths identical to pre-change behavior.

## 4. Test harness (`test/`)

- [ ] 4.1 In `test/test_scene.gd`, set `use_ground_shadow = true` and `shadow_light` to the scene `DirectionalLight2D` on the player `AnimatedEntity`.
- [ ] 4.2 Confirm test scene loads without script errors when `shadow.png` is absent under `test/art/sprite/player/`.
- [ ] 4.3 Document in task notes (or README) that committing a minimal `test/art/sprite/player/idle/shadow.png` placeholder is optional for automated load but required for manual visual validation.

## 5. Documentation

- [ ] 5.1 Add `shadow.png` to the animated pass table in `addons/godot-pixel-core/README.md` with encoding convention (bright = ground contact), experimental / provisional label, and relationship to in-flight `sprite-shadows` / `contact.png` work.
- [ ] 5.2 Document `use_ground_shadow` exports and `shadow_light` NodePath setup for manual spike adoption.

## 6. Verification

- [ ] 6.1 Run `openspec validate shadow-height-pass-spike --strict`; expect pass.
- [ ] 6.2 Open `test/test_scene.tscn` in Godot 4.6; play (F5) with `use_ground_shadow = false` on a scratch override — confirm no regression vs default-off exports.
- [ ] 6.3 Play `test/test_scene.tscn` with spike enabled (default harness wiring): confirm body sprite still lit under `DirectionalLight2D`; with `shadow.png` present, rotating the light visibly changes shadow orientation (manual check).
- [ ] 6.4 Confirm `player_entity.tscn` and `entity/characters/player.tscn` do **not** enable `use_ground_shadow` by default.
