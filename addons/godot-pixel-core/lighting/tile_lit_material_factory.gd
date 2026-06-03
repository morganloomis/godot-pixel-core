class_name TileLitMaterialFactory
extends RefCounted

const MATERIAL_PRESET_PATH := "res://addons/godot-pixel-core/lighting/tile_lit_material.tres"

static var _flat_normal_map_texture: ImageTexture


static func _ensure_flat_normal_map_texture() -> ImageTexture:
	if _flat_normal_map_texture == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGB8)
		img.fill(Color(0.5, 0.5, 1.0))
		_flat_normal_map_texture = ImageTexture.create_from_image(img)
	return _flat_normal_map_texture


## Duplicates the addon [ShaderMaterial] preset ([member MATERIAL_PRESET_PATH]); [param normal_atlas] may be [code]null[/code] or unloaded — a 1×1 flat normal is used instead (same idea as [method AnimatedEntity._ensure_flat_normal_map_texture]).
static func create_material(normal_atlas: Texture2D = null) -> ShaderMaterial:
	var base := load(MATERIAL_PRESET_PATH) as ShaderMaterial
	var m := base.duplicate() as ShaderMaterial
	var tex: Texture2D = normal_atlas
	if tex == null or tex.get_width() <= 0:
		tex = _ensure_flat_normal_map_texture()
	m.set_shader_parameter("normal_atlas", tex)
	return m
