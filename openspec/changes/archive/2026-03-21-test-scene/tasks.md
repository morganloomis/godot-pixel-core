## 1. Test Assets

- [x] 1.1 Rename `test/art/sprite/girl/girl_walk.png` to `test/art/sprite/girl/walk.png`
- [x] 1.2 Delete the old `girl_walk.png.import` file (Godot will regenerate for the new name)
- [x] 1.3 Add idle sprite sheet at `test/art/sprite/girl/idle.png` (diffuse/normal blocks, 8 directions)

## 2. Test Scene Script

- [x] 2.1 Create `test/test_scene.gd` — extends Node2D, in `_ready()` set `$PlayerEntity/AnimatedEntity.sprite_lookup.animated_sheet_root` to `"res://test/art/sprite/"`

## 3. Test Scene

- [x] 3.1 Create `test/test_scene.tscn` with root Node2D using `test_scene.gd`
- [x] 3.2 Add a `ColorRect` child as ground plane (sized to fill viewport, neutral color)
- [x] 3.3 Instance `res://addons/godot-pixel-core/entity/player_entity.tscn` as a child node
- [x] 3.4 Set `entity_id = "girl"` on the PlayerEntity's AnimatedEntity child via the scene file
- [x] 3.5 Add a `Camera2D` child, centered on the player start position

## 4. Project Configuration

- [x] 4.1 Update `project.godot` to set `run/main_scene` to `"res://test/test_scene.tscn"`

## 5. Verification

- [ ] 5.1 Launch the project — confirm the girl entity is visible on a colored ground
- [ ] 5.2 Press arrow keys — confirm walk animation plays in the correct 8-directional facing
- [ ] 5.3 Release keys — confirm idle animation plays, facing the last movement direction
- [ ] 5.4 Verify no files under `addons/godot-pixel-core/` were modified
