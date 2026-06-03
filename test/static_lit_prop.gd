@tool
extends StaticBody2D

## Demo: static collider + [AnimatedEntity] with engine 2D normal-mapped lighting (same presenter as characters).
## Open this scene or instance it under a level; ensure [member AnimatedEntity.sprite_lookup.animated_sheet_root]
## points at your art root. Animated layout: [code]{root}/{entity}/{action}/diffuse.png[/code] (and optional passes).

@onready var _presenter: AnimatedEntity = $AnimatedEntity


func _ready() -> void:
	_presenter.sprite_lookup.animated_sheet_root = "res://test/art/sprite/"
	_presenter.action = "idle"
	_presenter.direction = "SE"
	_presenter.frame = 0
	if Engine.is_editor_hint():
		_presenter.refresh_editor_sprite_preview()
