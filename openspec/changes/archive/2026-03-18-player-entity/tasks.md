## 1. Script

- [x] 1.1 Add player_entity.gd under addons/entity/ extending CharacterEntity with class_name PlayerEntity
- [x] 1.2 In _physics_process, read input with Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"), set velocity = input_direction * speed, call move_and_slide()
- [x] 1.3 Update child animated_entity action: "idle" when input ~zero, "walk" when moving; use set_action() when action changes
- [x] 1.4 Update child animated_entity direction from input (8-direction: N, NE, E, SE, S, SW, W, NW); keep last direction when idle

## 2. Scene

- [x] 2.1 Create player_entity.tscn in addons/entity/ with CharacterBody2D root and player_entity.gd script, same structure as character_entity (child AnimatedEntity, child CollisionShape2D)

## 3. Verification

- [x] 3.1 Confirm player moves with input and sprite follows; action is idle/walk and direction matches movement
