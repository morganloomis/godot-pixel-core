@tool
class_name LitTileMapLayer
extends TileMapLayer

## When [code]true[/code]: [ShaderMaterial] from [TileLitMaterialFactory] with [code]tile_lit.gdshader[/code] (default shading, not [code]unshaded[/code]) so the layer receives Godot 2D lights; [member CanvasItem.texture_filter] is nearest. [code]normal.png[/code] comes from [member tile_sheet_lookup] + [member tile_set_id], or [member normal_map_texture_path], or the first atlas source path (parent folder = tile set id, e.g. [code].../paver/diffuse.png[/code] → [code]paver[/code]).
@export var use_2d_normal_lighting: bool = false:
	set(value):
		if use_2d_normal_lighting == value:
			return
		use_2d_normal_lighting = value
		if is_node_ready():
			_apply_lit_setup()

## Folder name under [member TileSpriteSheetLookup.tile_sheet_root]. If empty at runtime, the addon infers it from [member tile_set] (first [TileSetAtlasSource] texture [code]resource_path[/code]: parent directory name).
@export var tile_set_id: String = "":
	set(value):
		if tile_set_id == value:
			return
		tile_set_id = value
		if is_node_ready() and use_2d_normal_lighting:
			_apply_lit_setup()

## Optional explicit [code]res://[/code] path to a normal atlas PNG. When set, overrides [code]{tile_sheet_root}/{tile_set_id}/normal.png[/code].
@export var normal_map_texture_path: String = "":
	set(value):
		if normal_map_texture_path == value:
			return
		normal_map_texture_path = value
		if is_node_ready() and use_2d_normal_lighting:
			_apply_lit_setup()

## If set before [code]_ready[/code], used for path resolution instead of a temporary [TileSpriteSheetLookup].
var tile_sheet_lookup: TileSpriteSheetLookup = null

## When non-empty, normal map path resolution uses this as [member TileSpriteSheetLookup.tile_sheet_root] (e.g. [code]res://test/art/tile/[/code] for tests). Ignored if [member tile_sheet_lookup] is set.
@export var tile_sheet_root_override: String = "":
	set(value):
		if tile_sheet_root_override == value:
			return
		tile_sheet_root_override = value
		if is_node_ready() and use_2d_normal_lighting:
			_apply_lit_setup()


func _ready() -> void:
	_apply_lit_setup()


func _resolve_tile_set_id() -> String:
	if not tile_set_id.is_empty():
		return tile_set_id
	var ts := tile_set
	if ts == null:
		return ""
	for i in ts.get_source_count():
		var sid := ts.get_source_id(i)
		var src := ts.get_source(sid)
		if src is TileSetAtlasSource:
			var at := src as TileSetAtlasSource
			var tex: Texture2D = at.texture
			if tex == null:
				continue
			var p := tex.resource_path
			if p.is_empty():
				continue
			return p.get_base_dir().get_file()
	return ""


func _resolve_normal_texture() -> Texture2D:
	if not normal_map_texture_path.is_empty() and ResourceLoader.exists(normal_map_texture_path):
		return load(normal_map_texture_path) as Texture2D
	var lookup := tile_sheet_lookup
	if lookup == null:
		lookup = TileSpriteSheetLookup.new()
		if not tile_sheet_root_override.is_empty():
			lookup.tile_sheet_root = tile_sheet_root_override
	var id := _resolve_tile_set_id()
	if id.is_empty():
		return null
	var npath := lookup.tile_pass_texture_path(id, SpriteSheetLookupBase.SpriteSheetPass.NORMAL)
	if not ResourceLoader.exists(npath):
		return null
	return lookup.get_cached_texture(npath, npath)


func _apply_lit_setup() -> void:
	if not use_2d_normal_lighting:
		material = null
		texture_filter = TEXTURE_FILTER_PARENT_NODE
		return
	texture_filter = TEXTURE_FILTER_NEAREST
	var normal_tex := _resolve_normal_texture()
	material = TileLitMaterialFactory.create_material(normal_tex)
