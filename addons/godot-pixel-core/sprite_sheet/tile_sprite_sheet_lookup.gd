class_name TileSpriteSheetLookup
extends SpriteSheetLookupBase


func _warn_pass_size_mismatch(tile_set_id: String, sheet_pass: SpriteSheetPass, pass_tex: Texture2D) -> void:
	if sheet_pass == SpriteSheetPass.DIFFUSE or not OS.is_debug_build():
		return
	var dpath := tile_pass_texture_path(tile_set_id, SpriteSheetPass.DIFFUSE)
	var dtex := get_cached_texture(dpath, dpath)
	if dtex == null:
		return
	var dw := dtex.get_width()
	var dh := dtex.get_height()
	if pass_tex.get_width() != dw or pass_tex.get_height() != dh:
		push_warning(
			"TileSpriteSheetLookup: pass %s size %dx%d != diffuse %dx%d for tile_set_id '%s'"
			% [tile_pass_texture_path(tile_set_id, sheet_pass), pass_tex.get_width(), pass_tex.get_height(), dw, dh, tile_set_id]
		)


func _cell_size_valid_for_diffuse(dtex: Texture2D, cell_size: Vector2) -> bool:
	if cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return false
	var w := dtex.get_width()
	var h := dtex.get_height()
	if w <= 0 or h <= 0:
		return false
	return (w % int(cell_size.x)) == 0 and (h % int(cell_size.y)) == 0


func _grid_extents(dtex: Texture2D, cell_size: Vector2) -> Vector2i:
	var cols := int(dtex.get_width() / cell_size.x)
	var rows := int(dtex.get_height() / cell_size.y)
	return Vector2i(cols, rows)


## Column count from [code]diffuse.png[/code] width and [param cell_size]; [code]0[/code] if diffuse missing or [param cell_size] does not evenly divide the sheet.
func get_column_count(tile_set_id: String, cell_size: Vector2) -> int:
	var dpath := tile_pass_texture_path(tile_set_id, SpriteSheetPass.DIFFUSE)
	var dtex := get_cached_texture(dpath, dpath)
	if dtex == null:
		return 0
	if not _cell_size_valid_for_diffuse(dtex, cell_size):
		return 0
	return _grid_extents(dtex, cell_size).x


## Atlas cell for [param row] / [param col] on the given pass. Empty [AtlasTexture] if [code]diffuse.png[/code] is missing, [param cell_size] is invalid for diffuse, optional pass file is absent, or indices are out of range.
func get_texture(tile_set_id: String, row: int, col: int, cell_size: Vector2, sheet_pass: SpriteSheetPass) -> AtlasTexture:
	var dpath := tile_pass_texture_path(tile_set_id, SpriteSheetPass.DIFFUSE)
	var dtex := get_cached_texture(dpath, dpath)
	if dtex == null:
		return AtlasTexture.new()
	if not _cell_size_valid_for_diffuse(dtex, cell_size):
		return AtlasTexture.new()

	var path := tile_pass_texture_path(tile_set_id, sheet_pass)
	var tex := get_cached_texture(path, path)
	if not tex:
		return AtlasTexture.new()

	_warn_pass_size_mismatch(tile_set_id, sheet_pass, tex)

	var grid := _grid_extents(dtex, cell_size)
	if row < 0 or col < 0 or row >= grid.y or col >= grid.x:
		return AtlasTexture.new()

	var region := compute_rect_static(cell_size, row, col)
	return create_atlas_texture(tex, region)


## Row-major linear index. If [param columns] <= [code]0[/code], columns are derived from diffuse width ÷ [code]cell_size.x[/code] (same rules as [method get_column_count]).
func get_texture_by_index(tile_set_id: String, index: int, columns: int, cell_size: Vector2, sheet_pass: SpriteSheetPass) -> AtlasTexture:
	var cols := columns
	if cols <= 0:
		cols = get_column_count(tile_set_id, cell_size)
	if cols <= 0:
		return AtlasTexture.new()
	var row: int = index / cols
	var col: int = index % cols
	return get_texture(tile_set_id, row, col, cell_size, sheet_pass)
