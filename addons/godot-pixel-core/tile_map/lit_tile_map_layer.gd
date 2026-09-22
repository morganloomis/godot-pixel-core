@tool
class_name LitTileMapLayer
extends TileMapLayer

## When [code]true[/code]: [ShaderMaterial] from [IsoLitMaterialFactory] with [code]iso_lit.gdshader[/code]
## (default shading, not [code]unshaded[/code]) so the layer receives Godot 2D lights;
## [member CanvasItem.texture_filter] is nearest. Pass atlases ([code]normal.png[/code],
## [code]height.png[/code], [code]specular.png[/code], [code]emissive.png[/code], [code]occlusion.png[/code])
## come from [member tile_sheet_lookup] + [member tile_set_id], or the first atlas source path
## (parent folder = tile set id, e.g. [code].../paver/diffuse.png[/code] → [code]paver[/code]).
##
## Tiles draw straight from the atlas, so the shader's cell region is the whole sheet. Ground tiles
## with no [code]normal.png[/code] fall back to a world-up normal, which is correct for a floor.
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

## When non-empty, pass path resolution uses this as [member TileSpriteSheetLookup.tile_sheet_root] (e.g. [code]res://test/art/tile/[/code] for tests). Ignored if [member tile_sheet_lookup] is set.
@export var tile_sheet_root_override: String = "":
	set(value):
		if tile_sheet_root_override == value:
			return
		tile_sheet_root_override = value
		if is_node_ready() and use_2d_normal_lighting:
			_apply_lit_setup()

static var _LIT_PASSES: Array = [
	SpriteSheetLookupBase.SpriteSheetPass.NORMAL,
	SpriteSheetLookupBase.SpriteSheetPass.HEIGHT,
	SpriteSheetLookupBase.SpriteSheetPass.SPECULAR,
	SpriteSheetLookupBase.SpriteSheetPass.EMISSIVE,
	SpriteSheetLookupBase.SpriteSheetPass.OCCLUSION,
]


func _ready() -> void:
	_apply_lit_setup()


## [TileSetAtlasSource] textures are sometimes a [CanvasTexture] wrapper, which has no
## [code]resource_path[/code] of its own; unwrap to the diffuse it carries.
static func _unwrap_atlas_texture(tex: Texture2D) -> Texture2D:
	if tex is CanvasTexture:
		var ct := tex as CanvasTexture
		if ct.diffuse_texture != null:
			return ct.diffuse_texture
	return tex


func _first_atlas_texture() -> Texture2D:
	var ts := tile_set
	if ts == null:
		return null
	for i in ts.get_source_count():
		var src := ts.get_source(ts.get_source_id(i))
		if src is TileSetAtlasSource:
			var tex: Texture2D = (src as TileSetAtlasSource).texture
			if tex != null:
				return _unwrap_atlas_texture(tex)
	return null


func _resolve_tile_set_id() -> String:
	if not tile_set_id.is_empty():
		return tile_set_id
	var tex := _first_atlas_texture()
	if tex == null:
		return ""
	var p := tex.resource_path
	if p.is_empty():
		return ""
	return p.get_base_dir().get_file()


func _resolve_lookup() -> TileSpriteSheetLookup:
	var lookup := tile_sheet_lookup
	if lookup == null:
		lookup = TileSpriteSheetLookup.new()
		if not tile_sheet_root_override.is_empty():
			lookup.tile_sheet_root = tile_sheet_root_override
	return lookup


func _resolve_pass_texture(lookup: TileSpriteSheetLookup, id: String, sheet_pass: SpriteSheetLookupBase.SpriteSheetPass) -> Texture2D:
	if sheet_pass == SpriteSheetLookupBase.SpriteSheetPass.NORMAL \
			and not normal_map_texture_path.is_empty() \
			and ResourceLoader.exists(normal_map_texture_path):
		return load(normal_map_texture_path) as Texture2D
	if id.is_empty():
		return null
	return lookup.get_tile_pass_sheet(id, sheet_pass)


func _apply_lit_setup() -> void:
	if not use_2d_normal_lighting:
		material = null
		texture_filter = TEXTURE_FILTER_PARENT_NODE
		return
	texture_filter = TEXTURE_FILTER_NEAREST

	var lookup := _resolve_lookup()
	var id := _resolve_tile_set_id()
	var sheets: Dictionary = {}
	for sheet_pass in _LIT_PASSES:
		var tex := _resolve_pass_texture(lookup, id, sheet_pass)
		if tex != null:
			sheets[sheet_pass] = tex

	material = IsoLitMaterialFactory.create_material(sheets, IsoLightingConfig.ground_sheet_normal())
