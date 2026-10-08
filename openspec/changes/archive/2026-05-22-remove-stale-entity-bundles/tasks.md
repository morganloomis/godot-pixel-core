## 1. Pre-flight reference check

- [x] 1.1 Grep the entire repository for `LitAnimatedEntity`, `lit_animated_entity`, `player_entity_lit`, `characters/character.gd`, `characters/character.tscn`, `shaders/sprite_lit`, and `lighting/sprite_lighting.gd`; record every match outside `openspec/changes/archive/`.
- [x] 1.2 Confirm `addons/godot-pixel-core/entity/characters/player.tscn` does not depend on `entity/characters/character.gd` (it should instance `player_entity.tscn`, not `character.gd`). If a reference is found, defer that file's cleanup to `fix-main-tscn-player-preset`.

## 2. Remove entity bundles

- [x] 2.1 Delete `addons/godot-pixel-core/entity/lit_animated_entity.gd`, `lit_animated_entity.gd.uid`, and `lit_animated_entity.tscn`.
- [x] 2.2 Delete `addons/godot-pixel-core/entity/player_entity_lit.tscn`.
- [x] 2.3 Delete `addons/godot-pixel-core/entity/characters/character.gd`, `character.gd.uid`, and `character.tscn`.

## 3. Remove duplicate lighting/shader copies

- [x] 3.1 Delete `addons/godot-pixel-core/shaders/sprite_lit.gdshader`, `sprite_lit.gdshader.uid`, and `sprite_lit_material.tres`.
- [x] 3.2 If `addons/godot-pixel-core/shaders/` is now empty, delete the directory so the addon tree stays clean.
- [x] 3.3 Delete `addons/godot-pixel-core/lighting/sprite_lighting.gd` and `sprite_lighting.gd.uid` (the canonical copy stays at `addons/godot-pixel-core/lighting/legacy/sprite_lighting.gd`).

## 4. Verify in Godot

- [x] 4.1 Open the project in Godot 4.6; confirm no missing-resource errors during scene load and that `test/test_scene.tscn` and `main.tscn` still open without parse errors.
- [x] 4.2 Confirm the project's debugger output no longer contains "UID duplicated" warnings for `c3s8sf1c5q75h` (sprite_lighting) or `bysck8xg6w7sg` (sprite_lit shader).
- [x] 4.3 Run the project and confirm `test/test_scene.tscn` plays as before (this change should not affect runtime behavior of the default lit path).

## 5. Spec-conformance verification

- [x] 5.1 Run `openspec validate remove-stale-entity-bundles --strict`; expect pass.
- [x] 5.2 Re-read `openspec/specs/entity-hierarchy/spec.md` "Legacy inline character removed", "Single presenter type for lit and unlit", and "Packaged player uses one scene pattern", and confirm `addons/godot-pixel-core/entity/` now conforms.
