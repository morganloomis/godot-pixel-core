# Design: Player Entity

## Context

CharacterEntity is implemented as CharacterBody2D with a child AnimatedEntity, exports (health, max_health, speed), and no built-in movement—subclasses or external code set velocity and call move_and_slide(). We need a player entity that extends CharacterEntity and adds input-driven movement and animation state (action/direction) so the player can control the character.

## Goals / Non-Goals

**Goals:**

- Provide a player entity that extends CharacterEntity and is movable via player input, using the inherited speed and child AnimatedEntity.
- In _physics_process, read movement input (e.g. Input.get_vector for ui_left/right/up/down), set velocity = input_direction * speed, call move_and_slide().
- Update the child animated_entity’s action (idle when no input, walk when moving) and direction (8-direction from input; keep last direction when idle).

**Non-Goals:**

- Changing CharacterEntity or AnimatedEntity API. Adding new input actions (use existing movement axes unless the project defines custom ones). Combat, stamina, or other gameplay beyond movement and animation state.

## Decisions

### 1. Extend CharacterEntity

**Choice:** Player entity script extends CharacterEntity. The scene roots from character_entity.tscn (or a new player_entity.tscn that uses CharacterEntity as base / instances character_entity and attaches the player script). Prefer: player_entity.gd extends CharacterEntity; player_entity.tscn has root with player_entity.gd, which in Godot means the root type is still CharacterBody2D (CharacterEntity). So we use a scene that instances character_entity.tscn and overrides the script to player_entity.gd, or we build a scene with CharacterBody2D + script PlayerEntity that extends CharacterEntity—but CharacterEntity is a script, not a node type. So the root node is CharacterBody2D; the script can be CharacterEntity or a subclass. So player_entity.tscn = root CharacterBody2D with script player_entity.gd (extends CharacterEntity). Children same as character_entity: AnimatedEntity instance, CollisionShape2D. So we either duplicate the scene layout or instance character_entity and change script. Cleanest: player_entity.gd extends CharacterEntity. player_entity.tscn = same structure as character_entity.tscn but script = player_entity.gd (so we get AnimatedEntity + CollisionShape2D from character_entity layout). So create player_entity.tscn with root CharacterBody2D, script res://addons/entity/characters/player_entity.gd (or addons/entity/player_entity.gd), children AnimatedEntity (instance of animated_entity.tscn), CollisionShape2D. Place script in addons/entity/ next to character_entity.gd.

**Rationale:** Reuses body, collision, attributes, and animated_entity reference; only adds input and action/direction updates.

### 2. Input and velocity

**Choice:** In _physics_process, use Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") to get input direction. Set velocity = input_direction * speed (speed inherited from CharacterEntity). Call move_and_slide().

**Rationale:** Same as existing player-character design; speed is already on CharacterEntity.

### 3. Action and direction

**Choice:** If input_direction is (approximately) zero, set animated_entity.action to "idle"; else set to "walk" (use set_action() when action changes). Direction: map input_direction to 8-direction string (N, NE, E, SE, S, SW, W, NW). When moving, set animated_entity.direction to that; when idle, leave direction unchanged (last facing).

**Rationale:** Matches sprite-sheet and animated-entity conventions; 8-direction is common.

## Risks / Trade-offs

- Input action names must match project; document or use same as default (ui_*). Action names (idle, walk) must match what the sprite lookup expects for the entity.

## Migration Plan

- Add player_entity.gd under addons/entity/ extending CharacterEntity; implement _physics_process (input, velocity, move_and_slide, action/direction).
- Add player_entity.tscn (root CharacterBody2D + player_entity.gd, children AnimatedEntity + CollisionShape2D) or instance character_entity.tscn and override script to player_entity.gd. Prefer standalone scene for clarity.
- Update main or test scene to use player_entity.tscn for the playable character when ready.
