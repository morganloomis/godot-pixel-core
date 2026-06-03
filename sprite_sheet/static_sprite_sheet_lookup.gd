class_name StaticSpriteSheetLookup
extends SpriteSheetLookupBase

func _get_sheet_path(sheet_id: String) -> String:
	return static_sheet_root.path_join(sheet_id) + ".png"

## Get texture for cell at (row, col). cell_size is the uniform size of each cell in the grid.
func get_texture(sheet_id: String, row: int, col: int, cell_size: Vector2) -> AtlasTexture:
	var path := _get_sheet_path(sheet_id)
	var tex := get_cached_texture(path, path)
	if not tex:
		return AtlasTexture.new()
	var region := compute_rect_static(cell_size, row, col)
	return create_atlas_texture(tex, region)

## Get texture for cell at linear index (row-major: index = row * columns + col). columns and cell_size required.
func get_texture_by_index(sheet_id: String, index: int, columns: int, cell_size: Vector2) -> AtlasTexture:
	var row: int = index / columns
	var col: int = index % columns
	return get_texture(sheet_id, row, col, cell_size)
