## 1. Move addon content under `addons/godot-pixel-core/`

- [x] 1.1 Create `addons/godot-pixel-core/` directory
- [x] 1.2 Move `addons/entity/` → `addons/godot-pixel-core/entity/` (preserve all files and subfolder structure including `characters/`)
- [x] 1.3 Move `addons/sprite_sheet/` → `addons/godot-pixel-core/sprite_sheet/` (preserve all files)
- [x] 1.4 Remove now-empty `addons/entity/` and `addons/sprite_sheet/` directories

## 2. Update `res://` path references

- [x] 2.1 Update all `res://addons/entity/` references to `res://addons/godot-pixel-core/entity/` in `.tscn` files (`animated_entity.tscn`, `character_entity.tscn`, `player_entity.tscn`, `characters/character.tscn`, `characters/player.tscn`)
- [x] 2.2 Update all `res://addons/entity/` references to `res://addons/godot-pixel-core/entity/` in `.gd` files (check for `preload`/`load` calls)
- [x] 2.3 Update all `res://addons/sprite_sheet/` references to `res://addons/godot-pixel-core/sprite_sheet/` in `.tscn` and `.gd` files
- [x] 2.4 Update `main.tscn` if it references any addon paths
- [x] 2.5 Grep the entire repo for remaining `res://addons/entity/` and `res://addons/sprite_sheet/` references and fix any that were missed

## 3. Add LICENSE and README to addon folder

- [x] 3.1 Copy root `LICENSE` to `addons/godot-pixel-core/LICENSE`
- [x] 3.2 Create `addons/godot-pixel-core/README.md` with addon overview, features, and usage instructions

## 4. Document submodule consumption

- [x] 4.1 Add submodule usage section to `addons/godot-pixel-core/README.md` with instructions for staging + symlink pattern (Linux/Mac `ln -s` and Windows `mklink /D`) and direct copy alternative

## 5. Update project documentation

- [x] 5.1 Update `openspec/project.md` to reflect the final addon structure
- [x] 5.2 Update `docs/ASSET_LIBRARY.md` checklist to reflect that addon content is now at `addons/godot-pixel-core/` and `plugin.cfg` is not needed for script-only addons

## 6. Verify

- [ ] 6.1 Open project in Godot and confirm all addon scripts and scenes load without errors
- [ ] 6.2 Run main scene and verify functionality works
- [x] 6.3 Confirm no remaining references to old `addons/entity/` or `addons/sprite_sheet/` paths
