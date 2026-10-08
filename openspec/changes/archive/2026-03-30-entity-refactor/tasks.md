## 1. Presenter: unified lit flag

- [x] 1.1 Add `@export` pseudo-lighting toggle on `AnimatedEntity` (name per design, e.g. `use_pseudo_lighting` or `pseudo_lit`).
- [x] 1.2 When enabled: duplicate `sprite_lit_material.tres`, assign to child `Sprite2D`, set `TEXTURE_FILTER_NEAREST`, bind `normal_map` in `update_sprite()` (same behavior as `LitAnimatedEntity`).
- [x] 1.3 When disabled: clear lit-specific material/normal behavior so display matches current unlit `AnimatedEntity` (no spurious shader on sprite).
- [x] 1.4 Move any `LitAnimatedEntity`-only logic into private helpers on `AnimatedEntity` to keep `update_sprite()` readable.

## 2. Remove lit-only types and scenes

- [x] 2.1 Replace internal references to `lit_animated_entity.tscn` / `LitAnimatedEntity` with `animated_entity.tscn` + pseudo-lighting enabled where needed.
- [x] 2.2 Delete `lit_animated_entity.gd` and `lit_animated_entity.tscn` after grep shows no remaining references.
- [x] 2.3 Remove `class_name LitAnimatedEntity` from public API; document migration in README (subclass → use export on `AnimatedEntity`).

## 3. Player and character scenes

- [x] 3.1 Consolidate to a single `player_entity.tscn` using unified presenter; remove `player_entity_lit.tscn` or replace with a thin preset that instances the same scene with pseudo-lighting on.
- [x] 3.2 Ensure `character_entity.tscn` instances only the unified presenter scene.
- [x] 3.3 Confirm `CharacterEntity` `entity_name` forwarding still runs correctly with the unified presenter (including empty-root / child-only authoring).

## 4. Legacy character removal

- [x] 4.1 Remove `entity/characters/character.gd` and `entity/characters/character.tscn` from the addon.
- [x] 4.2 Search repo for references to those paths or scripts; update `test/`, `main.tscn`, and docs to use `CharacterEntity` + presenter.

## 5. Documentation and specs

- [x] 5.1 Update `addons/godot-pixel-core/README.md`: single presenter, pseudo-lighting export, removed scenes/classes, migration from `LitAnimatedEntity` / `player_entity_lit.tscn`.
- [x] 5.2 Refresh `openspec/project.md` if any terminology or paths change during implementation.
- [x] 5.3 After implementation, run `/opsx:verify` (or manual check) against delta specs under `openspec/changes/entity-refactor/specs/` and main specs in `openspec/specs/` as needed.

## 6. Verification

- [x] 6.1 Run the project in Godot: unlit player/character and lit demo (pseudo-lighting on) both render and animate correctly. *(Lit path: `test/test_scene.tscn` with pseudo-lighting on the player and `StaticLitProp`; unlit path: `main.tscn` + `addons/.../player.tscn`. No Godot binary on agent PATH—spot-check in editor.)*
- [x] 6.2 Confirm shader globals / `SpriteLighting` still work with the unified presenter path.

## 7. Optional follow-ups (from design open questions)

- [x] 7.1 Decide whether to rename `AnimatedEntity` → e.g. `SpriteSheetPresenter` (`class_name` **BREAKING**); if yes, schedule and document.
- [x] 7.2 Optionally add `test/` example: `StaticBody2D` + presenter for a static lit prop. (`test/static_lit_prop.tscn`, instanced in `test/test_scene.tscn`.)
- [ ] 7.3 Optionally add a small documented helper or pattern for tile-adjacent lookup reuse (no `TileMapLayer` subclass of character).
