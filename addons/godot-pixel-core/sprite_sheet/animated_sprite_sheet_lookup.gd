class_name AnimatedSpriteSheetLookup
extends SpriteSheetLookupBase

## Optional override: entity+action -> frame_count. If not set, frame count is derived from [code]diffuse.png[/code] size (square cells: [code]cell_h = height/8[/code], columns = width / cell_h).
var frame_count_override: Dictionary = {}


func _get_frame_count_from_diffuse_size(sheet_size: Vector2) -> int:
	var cell_h: float = sheet_size.y / 8.0
	if cell_h <= 0:
		return 0
	var cell_w: float = cell_h
	return int(sheet_size.x / cell_w) if cell_w > 0 else 0


func _warn_pass_size_mismatch(entity: String, action: String, sheet_pass: SpriteSheetLookupBase.SpriteSheetPass, pass_tex: Texture2D) -> void:
	if sheet_pass == SpriteSheetLookupBase.SpriteSheetPass.DIFFUSE or not OS.is_debug_build():
		return
	var dpath := animated_pass_texture_path(entity, action, SpriteSheetLookupBase.SpriteSheetPass.DIFFUSE)
	var dtex := get_cached_texture(dpath, dpath)
	if dtex == null:
		return
	var dw := dtex.get_width()
	var dh := dtex.get_height()
	if pass_tex.get_width() != dw or pass_tex.get_height() != dh:
		push_warning(
			"AnimatedSpriteSheetLookup: pass %s size %dx%d != diffuse %dx%d for entity '%s' action '%s'"
			% [animated_pass_texture_path(entity, action, sheet_pass), pass_tex.get_width(), pass_tex.get_height(), dw, dh, entity, action]
		)


## Try [code]idle[/code] first; else first folder name (A→Z) under the entity with a valid diffuse grid. Returns [code]""[/code] if none.
func resolve_editor_preview_action(entity: String) -> String:
	if entity.is_empty():
		return ""
	if get_frame_count(entity, "idle") > 0:
		return "idle"
	for action_name in list_animated_action_folder_names_sorted(entity):
		if get_frame_count(entity, action_name) > 0:
			return action_name
	return ""


## Frame count from [code]diffuse.png[/code] only (or override). Returns [code]0[/code] if diffuse is missing or size is invalid.
func get_frame_count(entity: String, action: String) -> int:
	var key := entity + ":" + action
	if frame_count_override.has(key):
		return int(frame_count_override[key])
	var path := animated_pass_texture_path(entity, action, SpriteSheetLookupBase.SpriteSheetPass.DIFFUSE)
	var tex := get_cached_texture(path, path)
	if not tex:
		return 0
	return _get_frame_count_from_diffuse_size(Vector2(tex.get_width(), tex.get_height()))


## Atlas for the given pass file when present. Cached by full resource path. Empty [AtlasTexture] if the pass file is missing or diffuse is missing (no valid grid).
## Direction: name in [member SpriteSheetLookupBase.DIRECTIONS] or row index [code]0..7[/code].
func get_texture(entity: String, action: String, direction: Variant, frame: int, sheet_pass: SpriteSheetLookupBase.SpriteSheetPass) -> AtlasTexture:
	var direction_index: int
	if direction is String:
		direction_index = direction_name_to_index(direction)
		if direction_index < 0:
			direction_index = 0
	else:
		direction_index = int(direction) % 8

	var path := animated_pass_texture_path(entity, action, sheet_pass)
	var tex := get_cached_texture(path, path)
	if not tex:
		return AtlasTexture.new()

	var frame_count := get_frame_count(entity, action)
	if frame_count <= 0:
		return AtlasTexture.new()

	_warn_pass_size_mismatch(entity, action, sheet_pass, tex)

	var frame_index := frame % frame_count
	var sheet_size := Vector2(tex.get_width(), tex.get_height())
	var region := compute_rect_animated(sheet_size, frame_count, direction_index, frame_index)
	return create_atlas_texture(tex, region)
