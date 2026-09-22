@tool
class_name AnimatedEntity
extends Node2D

## Base for sprite-sheet–driven animated sprites. Supports Loop, Play once, and Hold last frame per action.
## Set sprite_lookup before _ready() to substitute a different lookup (e.g. for tests); otherwise uses AnimatedSpriteSheetLookup.
## Animation timing: [member frame_rate] (FPS). Movement magnitude for body scripts: [member movement_speed] (pixels/sec).
## Enable [member use_2d_normal_lighting] for engine 2D lights: the child [code]Sprite2D[/code] gets a
## [ShaderMaterial] from [IsoLitMaterialFactory] ([code]iso_lit.gdshader[/code]). Whole pass sheets are bound
## once per action and the current cell is picked by a region uniform, so nothing is baked per frame.
## Treat as an **authoring-time** flag; unlit instances use a plain diffuse [code]AtlasTexture[/code] only.

enum PlaybackMode {
	LOOP,
	PLAY_ONCE,
	HOLD_LAST_FRAME
}

signal animation_finished(action_name: String)

## Folder name under [member SpriteSheetLookupBase.animated_sheet_root] (e.g. [code]res://sprite/animated/<entity_name>/<action>/diffuse.png[/code]). If empty, the node [member Node.name] is used.
var _entity_name: String = ""
@export var entity_name: String:
	get:
		return _entity_name
	set(value):
		if _entity_name == value:
			return
		_entity_name = value
		if Engine.is_editor_hint():
			refresh_editor_sprite_preview()
## When true: nearest filter plus a [ShaderMaterial] that samples the normal/height/specular/emissive/occlusion
## sheets and feeds per-pixel height to Godot's 2D lights. Intended as a fixed choice per scene/instance, not toggled during gameplay.
var _use_2d_normal_lighting: bool = false
@export var use_2d_normal_lighting: bool:
	get:
		return _use_2d_normal_lighting
	set(value):
		if _use_2d_normal_lighting == value:
			return
		_use_2d_normal_lighting = value
		if is_node_ready():
			_apply_2d_normal_lighting_setup()
			if Engine.is_editor_hint():
				refresh_editor_sprite_preview()
			else:
				update_sprite()
@export var movement_speed: float = 200.0
@export_range(0.001, 120.0, 0.001, "or_greater", "suffix:FPS") var frame_rate: float = 12.0:
	set(value):
		frame_rate = value
		if is_node_ready() and is_instance_valid(animation_timer):
			_apply_frame_rate()

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_timer: Timer = $Timer

var action: String = "idle"
var _displayed_direction: String = "SE"
var _target_direction: String = "SE"
var _transition_step: int = 0
var direction: String:
	get:
		return _displayed_direction
	set(value):
		set_direction(value)
var _frame: int = 0
var frame: int:
	get:
		return _frame
	set(value):
		_frame = value
		if Engine.is_editor_hint():
			refresh_editor_sprite_preview()
		else:
			update_sprite()

## Substitute lookup before _ready() to use a different implementation (must provide [code]get_frame_count(entity, action)[/code] and [code]get_texture(entity, action, direction, frame, sheet_pass)[/code] with [enum SpriteSheetLookupBase.SpriteSheetPass]).
var sprite_lookup: RefCounted = null

## Per-action playback: action name -> PlaybackMode. Missing entries default to LOOP.
var playback_modes: Dictionary = {}

var _clip_finished: bool = false
var _playback_action: String = "idle"
var _in_action_transition: bool = false
var _lit_material: ShaderMaterial
## [code]entity|action[/code] currently bound to [member _lit_material]; sheets rebind only when this changes.
var _lit_bound_key: String = ""

## Passes the lit shader samples. Diffuse is excluded: it stays on [code]Sprite2D.texture[/code].
static var _LIT_PASSES: Array = [
	SpriteSheetLookupBase.SpriteSheetPass.NORMAL,
	SpriteSheetLookupBase.SpriteSheetPass.HEIGHT,
	SpriteSheetLookupBase.SpriteSheetPass.SPECULAR,
	SpriteSheetLookupBase.SpriteSheetPass.EMISSIVE,
	SpriteSheetLookupBase.SpriteSheetPass.OCCLUSION,
]


func _ready() -> void:
	_apply_2d_normal_lighting_setup()
	if sprite_lookup == null:
		sprite_lookup = AnimatedSpriteSheetLookup.new()
	_playback_action = action
	if Engine.is_editor_hint():
		animation_timer.timeout.connect(_on_animation_timeout)
		refresh_editor_sprite_preview()
		return
	_apply_frame_rate()
	animation_timer.timeout.connect(_on_animation_timeout)
	animation_timer.start()
	update_sprite()

func _get_entity_name() -> String:
	return _entity_name if _entity_name != "" else name


func _resolve_editor_preview_action(eid: String) -> String:
	if sprite_lookup == null:
		return ""
	if sprite_lookup is AnimatedSpriteSheetLookup:
		return (sprite_lookup as AnimatedSpriteSheetLookup).resolve_editor_preview_action(eid)
	if sprite_lookup.has_method("get_frame_count"):
		if sprite_lookup.get_frame_count(eid, "idle") > 0:
			return "idle"
		if sprite_lookup is SpriteSheetLookupBase:
			var slb := sprite_lookup as SpriteSheetLookupBase
			for action_name in slb.list_animated_action_folder_names_sorted(eid):
				if sprite_lookup.get_frame_count(eid, action_name) > 0:
					return action_name
	return ""


func _apply_editor_sprite_placeholder() -> void:
	if not Engine.is_editor_hint():
		return
	if sprite == null or sprite_lookup == null:
		return
	var eid := _get_entity_name()
	if eid.is_empty():
		return
	var preview_action := _resolve_editor_preview_action(eid)
	if preview_action.is_empty():
		return
	var diffuse_atlas: AtlasTexture = sprite_lookup.get_texture(
		eid, preview_action, "S", 0, SpriteSheetLookupBase.SpriteSheetPass.DIFFUSE
	)
	if diffuse_atlas == null or diffuse_atlas.atlas == null:
		return
	if diffuse_atlas.region.size.x <= 0.0 or diffuse_atlas.region.size.y <= 0.0:
		return
	sprite.texture = diffuse_atlas


## Re-runs editor-only diffuse placeholder (no-op when not in editor). Safe to call from parents after forwarding [member entity_name].
func refresh_editor_sprite_preview() -> void:
	if not Engine.is_editor_hint():
		return
	call_deferred("_deferred_apply_editor_sprite_placeholder")


func _deferred_apply_editor_sprite_placeholder() -> void:
	if not Engine.is_editor_hint():
		return
	_apply_editor_sprite_placeholder()

func _get_playback_mode(for_action: String) -> PlaybackMode:
	if playback_modes.has(for_action):
		return playback_modes[for_action] as PlaybackMode
	return PlaybackMode.LOOP


func _transition_clip_exists(transition_name: String) -> bool:
	var eid := _get_entity_name()
	if eid.is_empty() or sprite_lookup == null:
		return false
	return sprite_lookup.get_frame_count(eid, transition_name) > 0

func _apply_frame_rate() -> void:
	if frame_rate > 0.0:
		animation_timer.wait_time = 1.0 / frame_rate


func _apply_2d_normal_lighting_setup() -> void:
	if sprite == null:
		return
	if _use_2d_normal_lighting:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# The material needs the action's sheets, so it is bound in update_sprite(); in the editor the
		# preview stays diffuse-only and no material is assigned.
	else:
		sprite.material = null
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
		_lit_material = null
		_lit_bound_key = ""


## Binds whole pass sheets for [param eid] / [param action_name]. No-op while the action is unchanged,
## so the per-frame cost of lit mode is a single [code]cell_region[/code] write.
func _bind_lit_pass_sheets(eid: String, action_name: String, diffuse_sheet: Texture2D) -> void:
	var key := "%s|%s" % [eid, action_name]
	if key == _lit_bound_key and _lit_material != null:
		return
	var sheets: Dictionary = {}
	if sprite_lookup is SpriteSheetLookupBase:
		var lookup := sprite_lookup as SpriteSheetLookupBase
		for sheet_pass in _LIT_PASSES:
			var tex := lookup.get_animated_pass_sheet(eid, action_name, sheet_pass)
			if tex != null:
				sheets[sheet_pass] = tex
	# A sprite with no normal.png is shaded as if it faced the camera, not as if it lay on the ground.
	var fallback_normal := IsoLightingConfig.camera_facing_world_normal()
	if _lit_material == null:
		_lit_material = IsoLitMaterialFactory.create_material(sheets, fallback_normal)
	else:
		IsoLitMaterialFactory.apply_pass_sheets(_lit_material, sheets, fallback_normal)
	IsoLitMaterialFactory.set_sheet_size(_lit_material, Vector2(diffuse_sheet.get_width(), diffuse_sheet.get_height()))
	sprite.material = _lit_material
	_lit_bound_key = key


func update_sprite() -> void:
	if sprite == null or sprite_lookup == null:
		return
	var eid := _get_entity_name()
	if eid.is_empty():
		return
	var diffuse_atlas: AtlasTexture = sprite_lookup.get_texture(eid, _playback_action, direction, frame, SpriteSheetLookupBase.SpriteSheetPass.DIFFUSE)
	if diffuse_atlas == null or diffuse_atlas.atlas == null:
		return
	sprite.texture = diffuse_atlas
	if not _use_2d_normal_lighting:
		return
	_bind_lit_pass_sheets(eid, _playback_action, diffuse_atlas.atlas)
	IsoLitMaterialFactory.set_cell_region(_lit_material, diffuse_atlas.region)


func _on_animation_timeout() -> void:
	var eid := _get_entity_name()
	if eid.is_empty():
		return
	var max_frames: int = sprite_lookup.get_frame_count(eid, _playback_action)
	if max_frames <= 0:
		max_frames = 1
	if _in_action_transition:
		if _frame >= max_frames - 1:
			_in_action_transition = false
			_playback_action = action
			_frame = 0
			update_sprite()
		else:
			_frame += 1
			update_sprite()
		_advance_direction_transition()
		return
	var mode: PlaybackMode = _get_playback_mode(action)
	if _frame >= max_frames - 1:
		match mode:
			PlaybackMode.LOOP:
				_frame = 0
				update_sprite()
			PlaybackMode.PLAY_ONCE:
				_clip_finished = true
				animation_timer.stop()
				animation_finished.emit(action)
			PlaybackMode.HOLD_LAST_FRAME:
				_clip_finished = true
				animation_timer.stop()
	else:
		_frame += 1
		update_sprite()
	_advance_direction_transition()


func _normalize_direction(direction_name: String) -> String:
	var idx := SpriteSheetLookupBase.DIRECTIONS.find(direction_name)
	return SpriteSheetLookupBase.DIRECTIONS[0] if idx < 0 else direction_name


func _direction_to_index(direction_name: String) -> int:
	var idx := SpriteSheetLookupBase.DIRECTIONS.find(direction_name)
	return idx if idx >= 0 else 0


func _index_to_direction(index: int) -> String:
	return SpriteSheetLookupBase.DIRECTIONS[posmod(index, 8)]


func _ring_distance(from_index: int, to_index: int) -> int:
	var cw := (to_index - from_index + 8) % 8
	var ccw := (from_index - to_index + 8) % 8
	return mini(cw, ccw)


func _compute_transition_step(from_index: int, to_index: int) -> int:
	if from_index == to_index:
		return 0
	var dist := _ring_distance(from_index, to_index)
	if dist <= 1:
		return 0
	var cw := (to_index - from_index + 8) % 8
	var ccw := (from_index - to_index + 8) % 8
	if cw < ccw:
		return 1
	if ccw < cw:
		return -1
	return 1 if randi() % 2 == 0 else -1


func set_direction(new_direction: String) -> void:
	var target := _normalize_direction(new_direction)
	if Engine.is_editor_hint():
		_displayed_direction = target
		_target_direction = target
		_transition_step = 0
		refresh_editor_sprite_preview()
		return
	var from_index := _direction_to_index(_displayed_direction)
	var to_index := _direction_to_index(target)
	var dist := _ring_distance(from_index, to_index)
	if dist == 0:
		return
	if target == _target_direction and _transition_step != 0:
		return
	_target_direction = target
	if dist == 1:
		_displayed_direction = target
		_transition_step = 0
		update_sprite()
		return
	_transition_step = _compute_transition_step(from_index, to_index)


func _advance_direction_transition() -> void:
	if _transition_step == 0:
		return
	var from_index := _direction_to_index(_displayed_direction)
	var to_index := _direction_to_index(_target_direction)
	if from_index == to_index:
		_transition_step = 0
		return
	var next_index := (from_index + _transition_step + 8) % 8
	_displayed_direction = _index_to_direction(next_index)
	if next_index == to_index:
		_transition_step = 0
	update_sprite()

## Call when changing action: resets frame to 0 and restarts the timer if it was stopped by a one-shot clip.
## Logical [member action] updates immediately; optional [code]{from}-{to}[/code] bridge folders play once before the target loop.
func set_action(new_action: String) -> void:
	if new_action == action:
		return
	var previous := action
	action = new_action
	_clip_finished = false
	if _in_action_transition:
		_in_action_transition = false
		_playback_action = new_action
	else:
		var transition_name := "%s-%s" % [previous, new_action]
		if _transition_clip_exists(transition_name):
			_playback_action = transition_name
			_in_action_transition = true
		else:
			_playback_action = new_action
	frame = 0
	if not animation_timer.timeout.is_connected(_on_animation_timeout):
		animation_timer.timeout.connect(_on_animation_timeout)
	animation_timer.start()

## Set playback mode for an action (LOOP, PLAY_ONCE, or HOLD_LAST_FRAME).
func set_playback_mode(action_name: String, mode: PlaybackMode) -> void:
	playback_modes[action_name] = mode
