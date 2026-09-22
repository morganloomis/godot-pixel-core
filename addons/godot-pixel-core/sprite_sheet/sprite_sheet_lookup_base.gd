class_name SpriteSheetLookupBase
extends RefCounted

## Per-action pass files under [code]{animated_root}/{entity}/{action}/[/code].
## [code]HEIGHT[/code] and [code]EMISSIVE[/code] are appended so existing serialized values keep their meaning.
enum SpriteSheetPass {
	DIFFUSE,
	NORMAL,
	SPECULAR,
	OCCLUSION,
	HEIGHT,
	EMISSIVE,
}

## Filename per [enum SpriteSheetPass]; shared by the animated and tile layouts.
const PASS_FILE_NAMES: Dictionary = {
	SpriteSheetPass.DIFFUSE: "diffuse.png",
	SpriteSheetPass.NORMAL: "normal.png",
	SpriteSheetPass.SPECULAR: "specular.png",
	SpriteSheetPass.OCCLUSION: "occlusion.png",
	SpriteSheetPass.HEIGHT: "height.png",
	SpriteSheetPass.EMISSIVE: "emissive.png",
}

# Animated sheet rows (top→bottom): S=0, then counter-clockwise (S, SE, E, NE, N, NW, W, SW)
const DIRECTIONS: Array[String] = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]

# Configurable roots; animated and static sheets use separate directories
var animated_sheet_root: String = "res://sprite/animated/"
var static_sheet_root: String = "res://sprite/static/"
## Per-pass tile sets: [code]{tile_sheet_root}/{tile_set_id}/diffuse.png[/code] etc. Default mirrors [code]res://art/sprite/[/code] → [code]res://art/tile/[/code].
var tile_sheet_root: String = "res://art/tile/"

# Cache: key (path or composite key) -> Texture2D
var _texture_cache: Dictionary = {}

func _init() -> void:
	pass

## Returns 0-7 for S, SE, E, NE, N, NW, W, SW (row index in each 8-row block); -1 if invalid.
func direction_name_to_index(direction_name: String) -> int:
	var i := DIRECTIONS.find(direction_name)
	return i if i >= 0 else -1

## Load texture from path and cache by key. Returns cached Texture2D or null if load fails.
func get_cached_texture(key: String, path: String) -> Texture2D:
	if _texture_cache.has(key):
		return _texture_cache[key]
	if not ResourceLoader.exists(path):
		return null
	var res = load(path) as Texture2D
	if res:
		_texture_cache[key] = res
	return res


## Subfolder names under [code]{animated_sheet_root}/{entity}/[/code], sorted A→Z (for editor preview discovery). Skips hidden names.
func list_animated_action_folder_names_sorted(entity: String) -> Array[String]:
	var out: Array[String] = []
	if entity.is_empty():
		return out
	var dir_path := animated_sheet_root.path_join(entity)
	var da := DirAccess.open(dir_path)
	if da == null:
		return out
	da.list_dir_begin()
	var n := da.get_next()
	while n != "":
		if da.current_is_dir() and not n.begins_with("."):
			out.append(n)
		n = da.get_next()
	da.list_dir_end()
	out.sort()
	return out


## Filename for [param sheet_pass]; falls back to [code]diffuse.png[/code] for unknown values.
static func pass_file_name(sheet_pass: SpriteSheetPass) -> String:
	return PASS_FILE_NAMES.get(sheet_pass, "diffuse.png")


func animated_pass_texture_path(entity: String, action: String, sheet_pass: SpriteSheetPass) -> String:
	return animated_sheet_root.path_join(entity).path_join(action).path_join(pass_file_name(sheet_pass))


## Path to pass file for a tile set: [code]{tile_sheet_root}/{tile_set_id}/{pass}.png[/code] (same filenames as [method animated_pass_texture_path]).
func tile_pass_texture_path(tile_set_id: String, sheet_pass: SpriteSheetPass) -> String:
	return tile_sheet_root.path_join(tile_set_id).path_join(pass_file_name(sheet_pass))


## Whole sheet [Texture2D] for an animated pass (not a cell region); [code]null[/code] when the file is absent.
## Shader-driven lit paths bind whole sheets and pick cells with a region uniform, so they do not need [AtlasTexture] per cell.
func get_animated_pass_sheet(entity: String, action: String, sheet_pass: SpriteSheetPass) -> Texture2D:
	var path := animated_pass_texture_path(entity, action, sheet_pass)
	return get_cached_texture(path, path)


## Whole sheet [Texture2D] for a tile pass (not a cell region); [code]null[/code] when the file is absent.
func get_tile_pass_sheet(tile_set_id: String, sheet_pass: SpriteSheetPass) -> Texture2D:
	var path := tile_pass_texture_path(tile_set_id, sheet_pass)
	return get_cached_texture(path, path)


## Compute cell Rect2 for animated layout: single 8-row grid (row 0 = S, then counter-clockwise to SW), [param frame_count] columns.
func compute_rect_animated(sheet_size: Vector2, frame_count: int, direction_index: int, frame_index: int) -> Rect2:
	var fc: int = maxi(frame_count, 1)
	var cell_h: float = sheet_size.y / 8.0
	var cell_w: float = sheet_size.x / float(fc)
	var y: float = direction_index * cell_h
	var x: float = frame_index * cell_w
	return Rect2(x, y, cell_w, cell_h)

## Compute cell Rect2 for static grid: uniform cell size, row and column.
func compute_rect_static(cell_size: Vector2, row: int, col: int) -> Rect2:
	return Rect2(col * cell_size.x, row * cell_size.y, cell_size.x, cell_size.y)

## Create an AtlasTexture for the given region of the sheet texture.
func create_atlas_texture(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	return atlas
