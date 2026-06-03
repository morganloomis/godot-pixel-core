@tool
class_name AnimatedEntity
extends Node2D

## Base for sprite-sheet–driven animated sprites. Supports Loop, Play once, and Hold last frame per action.
## Set sprite_lookup before _ready() to substitute a different lookup (e.g. for tests); otherwise uses AnimatedSpriteSheetLookup.
## Animation timing: [member frame_rate] (FPS). Movement magnitude for body scripts: [member movement_speed] (pixels/sec).
## Enable [member use_2d_normal_lighting] for engine 2D lights: [code]Sprite2D.texture[/code] becomes a [CanvasTexture] whose diffuse + normal slots are filled from the sheet (cells baked to [code]ImageTexture[/code] — [code]Sprite2D.normal_texture[/code] is not assignable with atlas/image textures on some builds, and [CanvasTexture] + [AtlasTexture] regions can be unreliable). Treat as an **authoring-time** flag; unlit instances use a plain diffuse [code]AtlasTexture[/code] on [code]texture[/code] only.

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
## When true: [CanvasTexture] on [code]texture[/code] (diffuse + normal), nearest filter, [CanvasItemMaterial] receiving 2D lights. Intended as a fixed choice per scene/instance, not toggled during gameplay.
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
var direction: String = "SE"
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
var _lit_canvas_material: CanvasItemMaterial
var _lit_canvas_bundle: CanvasTexture

## Shared flat normal when the sheet has no normal cell ([code]CanvasTexture.normal_texture[/code] cannot be cleared with [code]null[/code] on some builds).
static var _flat_normal_map_texture: ImageTexture

## [code][diffuse ImageTexture, normal ImageTexture][/code] per sheet cell; used only for lit [CanvasTexture] path.
static var _lit_cell_image_pair_cache: Dictionary = {}


static func _ensure_flat_normal_map_texture() -> ImageTexture:
	if _flat_normal_map_texture == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGB8)
		img.fill(Color(0.5, 0.5, 1.0))
		_flat_normal_map_texture = ImageTexture.create_from_image(img)
	return _flat_normal_map_texture


static func _lit_cell_diffuse_and_normal(diff_at: AtlasTexture, norm_at: AtlasTexture) -> Array:
	if diff_at == null or diff_at.atlas == null:
		return []
	var ap := diff_at.atlas.resource_path if diff_at.atlas.resource_path != "" else str(diff_at.atlas.get_rid())
	var norm_key: String
	if norm_at != null and norm_at.atlas != null:
		norm_key = str(Rect2i(norm_at.region))
	else:
		norm_key = "_"
	var ck := "%s|%s|%s" % [ap, str(Rect2i(diff_at.region)), norm_key]
	if _lit_cell_image_pair_cache.has(ck):
		return _lit_cell_image_pair_cache[ck] as Array
	var sheet_img: Image = diff_at.atlas.get_image()
	if sheet_img == null:
		return []
	var d_cell: Image = sheet_img.get_region(Rect2i(diff_at.region))
	if d_cell.get_width() <= 0 or d_cell.get_height() <= 0:
		return []
	var d_tex := ImageTexture.create_from_image(d_cell)
	var n_tex: Texture2D = _ensure_flat_normal_map_texture()
	if norm_at != null and norm_at.atlas != null:
		var n_src: Image = norm_at.atlas.get_image()
		if n_src != null:
			var n_cell: Image = n_src.get_region(Rect2i(norm_at.region))
			if n_cell.get_width() > 0 and n_cell.get_height() > 0:
				n_tex = ImageTexture.create_from_image(n_cell)
	var pair: Array = [d_tex, n_tex]
	_lit_cell_image_pair_cache[ck] = pair
	return pair


func _ready() -> void:
	_apply_2d_normal_lighting_setup()
	if sprite_lookup == null:
		sprite_lookup = AnimatedSpriteSheetLookup.new()
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

func _apply_frame_rate() -> void:
	if frame_rate > 0.0:
		animation_timer.wait_time = 1.0 / frame_rate


func _apply_2d_normal_lighting_setup() -> void:
	if sprite == null:
		return
	if _use_2d_normal_lighting:
		if _lit_canvas_bundle == null:
			_lit_canvas_bundle = CanvasTexture.new()
			_lit_canvas_bundle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _lit_canvas_material == null:
			_lit_canvas_material = CanvasItemMaterial.new()
			_lit_canvas_material.light_mode = CanvasItemMaterial.LIGHT_MODE_NORMAL
		sprite.material = _lit_canvas_material
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		sprite.material = null
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE


func update_sprite() -> void:
	if sprite == null or sprite_lookup == null:
		return
	var eid := _get_entity_name()
	if eid.is_empty():
		return
	var diffuse_atlas: AtlasTexture = sprite_lookup.get_texture(eid, action, direction, frame, SpriteSheetLookupBase.SpriteSheetPass.DIFFUSE)
	if diffuse_atlas == null or diffuse_atlas.atlas == null:
		return
	if _use_2d_normal_lighting:
		if _lit_canvas_bundle == null:
			_lit_canvas_bundle = CanvasTexture.new()
			_lit_canvas_bundle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var normal_atlas: AtlasTexture = sprite_lookup.get_texture(eid, action, direction, frame, SpriteSheetLookupBase.SpriteSheetPass.NORMAL)
		var pair: Array = _lit_cell_diffuse_and_normal(diffuse_atlas, normal_atlas)
		if pair.size() < 2:
			return
		_lit_canvas_bundle.diffuse_texture = pair[0] as Texture2D
		_lit_canvas_bundle.normal_texture = pair[1] as Texture2D
		sprite.texture = _lit_canvas_bundle
	else:
		sprite.texture = diffuse_atlas

func _on_animation_timeout() -> void:
	var eid := _get_entity_name()
	if eid.is_empty():
		return
	var max_frames: int = sprite_lookup.get_frame_count(eid, action)
	if max_frames <= 0:
		max_frames = 1
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

## Call when changing action: resets frame to 0 and restarts the timer if it was stopped by a one-shot clip.
func set_action(new_action: String) -> void:
	if action == new_action:
		return
	action = new_action
	frame = 0
	_clip_finished = false
	if not animation_timer.timeout.is_connected(_on_animation_timeout):
		animation_timer.timeout.connect(_on_animation_timeout)
	animation_timer.start()

## Set playback mode for an action (LOOP, PLAY_ONCE, or HOLD_LAST_FRAME).
func set_playback_mode(action_name: String, mode: PlaybackMode) -> void:
	playback_modes[action_name] = mode
