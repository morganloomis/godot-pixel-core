@tool
class_name CharacterEntity
extends CharacterBody2D

## Character in the game: moving, collidable, with attributes (health, etc.).
## Uses a child AnimatedEntity for display; does not implement sprite or frame logic.
## [member movement_speed] and [member frame_rate] are forwarded to the child presenter (same as editing the child).
## [member speed] is a read-only alias of presenter movement speed for gameplay code.
## Subclasses or external code set velocity and call move_and_slide().

@export var health: float = 100.0
@export var max_health: float = 100.0
## Sprite set id: same as [member AnimatedEntity.entity_name]; forwarded to the child presenter so it appears with other character exports.
@export var entity_name: String = "":
	get:
		return _entity_name
	set(value):
		if _entity_name == value:
			return
		_entity_name = value
		_push_entity_name_to_presenter()

var _entity_name: String = ""

var _movement_speed: float = 200.0
var _frame_rate: float = 12.0

@export var movement_speed: float = 200.0:
	get:
		if is_instance_valid(animated_entity):
			return animated_entity.movement_speed
		return _movement_speed
	set(value):
		_movement_speed = value
		if is_instance_valid(animated_entity):
			animated_entity.movement_speed = value

@export_range(0.001, 120.0, 0.001, "or_greater", "suffix:FPS") var frame_rate: float = 12.0:
	get:
		if is_instance_valid(animated_entity):
			return animated_entity.frame_rate
		return _frame_rate
	set(value):
		_frame_rate = value
		if is_instance_valid(animated_entity):
			animated_entity.frame_rate = value

@onready var animated_entity: AnimatedEntity = $AnimatedEntity

var speed: float:
	get:
		if is_instance_valid(animated_entity):
			return animated_entity.movement_speed
		return _movement_speed

const _ISO_DIAG_Y_RATIO := 0.5


func remap_input_to_screen(input: Vector2) -> Vector2:
	if input.length_squared() <= 0.001:
		return Vector2.ZERO
	if absf(input.y) <= 0.001:
		return Vector2(signf(input.x), 0.0)
	if absf(input.x) <= 0.001:
		return Vector2(0.0, signf(input.y))
	return Vector2(signf(input.x), signf(input.y) * _ISO_DIAG_Y_RATIO).normalized()


func _vector_to_direction(v: Vector2) -> String:
	var rot := fposmod(PI / 2.0 - v.angle(), TAU)
	var idx := int(round(rot / (PI / 4.0))) % 8
	return SpriteSheetLookupBase.DIRECTIONS[idx]


func _ready() -> void:
	# Avoid overwriting a child-authored entity_name when the root export was left empty.
	if _entity_name != "":
		_push_entity_name_to_presenter()
	if is_instance_valid(animated_entity):
		animated_entity.movement_speed = _movement_speed
		animated_entity.frame_rate = _frame_rate


func _push_entity_name_to_presenter() -> void:
	if animated_entity == null:
		return
	animated_entity.entity_name = _entity_name
	if Engine.is_editor_hint():
		animated_entity.refresh_editor_sprite_preview()
