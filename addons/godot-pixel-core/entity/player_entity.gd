@tool
class_name PlayerEntity
extends CharacterEntity

## Player-controlled character: extends CharacterEntity and drives movement from input.
## Reads movement axes, sets velocity and move_and_slide(), updates action and direction on child AnimatedEntity.
## Root exports include inherited [member CharacterEntity.movement_speed] and [member CharacterEntity.frame_rate] (forwarded to the child presenter).
## [code]@tool[/code] matches [CharacterEntity] so root [member CharacterEntity.entity_name] forwards in the editor (sprite preview on child [AnimatedEntity]).

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir := remap_input_to_screen(input_direction)
	velocity = move_dir * speed
	move_and_slide()

	var new_action: String = "walk" if move_dir.length_squared() > 0.001 else "idle"
	if animated_entity.action != new_action:
		animated_entity.set_action(new_action)

	if move_dir.length_squared() > 0.001:
		animated_entity.set_direction(_vector_to_direction(move_dir))
