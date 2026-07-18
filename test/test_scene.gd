@tool
extends Node2D

## Test harness: wires bundled sprite root and enables engine 2D lit mode on the player presenter.
## Expects animated art at [code]{animated_sheet_root}/{entity}/{action}/diffuse.png[/code] (optional [code]normal.png[/code], etc.).
## [code]@tool[/code] so this wiring runs in the editor and the child [AnimatedEntity] can refresh its diffuse placeholder (see [member AnimatedEntity.refresh_editor_sprite_preview]).

@onready var _movement_debug_label: Label = $DirectionHintUI/DirectionHintLabel
@onready var _player: PlayerEntity = $PlayerEntity


func _ready() -> void:
	var presenter: AnimatedEntity = $PlayerEntity/AnimatedEntity
	presenter.sprite_lookup.animated_sheet_root = "res://test/art/sprite/"
	presenter.use_2d_normal_lighting = true
	if Engine.is_editor_hint():
		presenter.refresh_editor_sprite_preview()
	else:
		set_process(true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var velocity := _player.velocity
	if velocity.length_squared() <= 0.001:
		_movement_debug_label.text = "Iso movement: idle (hold Right+Down — expect ~27° travel, not 45°)"
		return
	var travel_angle := snappedf(rad_to_deg(velocity.angle()), 0.1)
	var facing := _player.animated_entity.direction
	_movement_debug_label.text = (
		"Iso movement debug: travel angle=%s° facing=%s (2:1 iso target ~27° for SE, old raw input was ~45°)"
		% [travel_angle, facing]
	)
