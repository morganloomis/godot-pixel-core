## 1. Script

- [x] 1.1 Add character_entity.gd under addons/entity/ extending CharacterBody2D with class_name CharacterEntity
- [x] 1.2 Add @onready reference to child AnimatedEntity (e.g. $AnimatedEntity; match child node name in scene)
- [x] 1.3 Add @export vars for health, max_health, and speed with defaults (e.g. health: 100.0, max_health: 100.0, speed: 200.0)

## 2. Scene

- [x] 2.1 Create character_entity.tscn in addons/entity/ with CharacterBody2D root and character_entity.gd script attached
- [x] 2.2 Add child instance of animated_entity.tscn named AnimatedEntity (or Sprite) at local position (0, 0)
- [x] 2.3 Add child CollisionShape2D with a placeholder shape (e.g. RectangleShape2D or CapsuleShape2D); collision layer/mask left for game to configure

## 3. Verification

- [x] 3.1 Confirm character entity script does not implement sprite lookup or frame advance (all display logic in child AnimatedEntity)
- [x] 3.2 Confirm velocity can be set on the root body and move_and_slide() can be called (e.g. by a subclass or test) so the character moves and sprite follows
