@tool
extends Node2D

## Test harness: wires bundled sprite root and enables engine 2D lit mode on the player presenter.
## Expects animated art at [code]{animated_sheet_root}/{entity}/{action}/diffuse.png[/code] (optional [code]normal.png[/code], etc.).
## [code]@tool[/code] so this wiring runs in the editor and the child [AnimatedEntity] can refresh its diffuse placeholder (see [member AnimatedEntity.refresh_editor_sprite_preview]).

func _ready() -> void:
	var presenter: AnimatedEntity = $PlayerEntity/AnimatedEntity
	presenter.sprite_lookup.animated_sheet_root = "res://test/art/sprite/"
	presenter.use_2d_normal_lighting = true
	if Engine.is_editor_hint():
		presenter.refresh_editor_sprite_preview()
