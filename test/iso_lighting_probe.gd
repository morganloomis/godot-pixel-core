extends Node2D

## Verification probe for [code]iso_lit.gdshader[/code]: orbits a [PointLight2D] around one lit sprite
## on the ground plane. This is the single test that separates working from broken.
##
## [b]Working[/b]: the terminator sweeps horizontally around the figure and the silhouette heats up as
## the light passes behind it.
## [b]Broken[/b]: the light appears to slide vertically up and down the figure — that is the artifact
## per-pixel height exists to remove, and it means height or [code]LIGHT_VERTEX[/code] is not landing.
##
## Space pauses, left/right arrows step the orbit by hand.

## Radius of the orbit on the ground plane, in pixels.
@export var orbit_radius_px: float = 90.0
## How far above the ground the light floats. Roughly mid-body reads best.
@export var orbit_light_height_px: float = 28.0
@export var orbit_seconds: float = 6.0

@onready var _presenter: AnimatedEntity = $AnimatedEntity
@onready var _light: PointLight2D = $OrbitLight
@onready var _readout: Label = $ProbeUI/Readout

var _angle: float = 0.0
var _paused: bool = false


func _ready() -> void:
	IsoLightingConfig.ensure_globals()
	# A dark room is the point: the terminator only reads when ambient is well below the key light.
	IsoLightingConfig.set_ambient(Color(0.10, 0.11, 0.16), 1.0)
	_presenter.sprite_lookup.animated_sheet_root = "res://test/art/sprite/"
	_presenter.use_2d_normal_lighting = true
	_presenter.set_direction("S")
	_update_light()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_paused = not _paused
	elif event.is_action_pressed("ui_left"):
		_paused = true
		_step(-TAU / 32.0)
	elif event.is_action_pressed("ui_right"):
		_paused = true
		_step(TAU / 32.0)


func _process(delta: float) -> void:
	if _paused or orbit_seconds <= 0.0:
		return
	_step(TAU * delta / orbit_seconds)


func _step(amount: float) -> void:
	_angle = fposmod(_angle + amount, TAU)
	_update_light()


## Places the light per the addon convention: the node sits at the screen position of the point
## directly BELOW the light on the ground, and [member Light2D.height] is its height above that point.
## A circle on the ground projects to an ellipse squashed by the camera elevation.
func _update_light() -> void:
	var elevation := deg_to_rad(IsoLightingConfig.get_elevation_degrees())
	var ground_offset := Vector2(
		cos(_angle) * orbit_radius_px,
		sin(_angle) * orbit_radius_px * sin(elevation)
	)
	_light.global_position = _presenter.global_position + ground_offset
	_light.height = orbit_light_height_px
	# Negative screen-Y offset means further from the viewer, i.e. the light is behind the figure.
	var side := "BEHIND" if ground_offset.y < 0.0 else "in front"
	_readout.text = (
		"orbit %3d°  light is %s   ground offset %s, height %.0f px\n"
		+ "expect: terminator sweeps sideways, rim hottest when BEHIND.  space = pause, arrows = step"
	) % [int(rad_to_deg(_angle)), side, str(ground_offset.round()), orbit_light_height_px]
