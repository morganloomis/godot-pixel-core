@tool
class_name IsoLitMaterialFactory
extends RefCounted

## Builds [ShaderMaterial]s for [code]iso_lit.gdshader[/code]. Used by both [AnimatedEntity]
## (one material per instance, cell picked by [member cell_region]) and [LitTileMapLayer]
## (one material per layer, whole sheet).
##
## Absent passes are bound to cached 1x1 fallbacks rather than guarded by [code]bool[/code] uniforms,
## so the shader has no branching and every sampler is always valid.

const SHADER_PATH := "res://addons/godot-pixel-core/lighting/iso_lit.gdshader"

## Pass name -> shader sampler uniform. [code]DIFFUSE[/code] is absent on purpose: it comes from
## the drawable's own [code]TEXTURE[/code] so [AtlasTexture] regions and tile drawing keep working.
static var PASS_UNIFORMS: Dictionary = {
	SpriteSheetLookupBase.SpriteSheetPass.NORMAL: "normal_tex",
	SpriteSheetLookupBase.SpriteSheetPass.HEIGHT: "height_tex",
	SpriteSheetLookupBase.SpriteSheetPass.SPECULAR: "specular_tex",
	SpriteSheetLookupBase.SpriteSheetPass.EMISSIVE: "emissive_tex",
	SpriteSheetLookupBase.SpriteSheetPass.OCCLUSION: "occlusion_tex",
}

# Height 0 = on the ground; no specular; no emission; no occlusion.
const FALLBACK_HEIGHT := Color(0.0, 0.0, 0.0, 1.0)
const FALLBACK_SPECULAR := Color(0.0, 0.0, 0.0, 1.0)
const FALLBACK_EMISSIVE := Color(0.0, 0.0, 0.0, 1.0)
const FALLBACK_OCCLUSION := Color(1.0, 1.0, 1.0, 1.0)

static var _solid_texture_cache: Dictionary = {}


static func _solid_texture(color: Color) -> ImageTexture:
	var key := str(color)
	if _solid_texture_cache.has(key):
		return _solid_texture_cache[key]
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex := ImageTexture.create_from_image(img)
	_solid_texture_cache[key] = tex
	return tex


## Encodes a world-space normal into the shader's [code][0,1][/code] storage convention.
static func encode_world_normal(world_normal: Vector3) -> Color:
	var n := world_normal.normalized()
	return Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0)


static func _fallback_for(sheet_pass: SpriteSheetLookupBase.SpriteSheetPass, default_world_normal: Vector3) -> Texture2D:
	match sheet_pass:
		SpriteSheetLookupBase.SpriteSheetPass.NORMAL:
			return _solid_texture(encode_world_normal(default_world_normal))
		SpriteSheetLookupBase.SpriteSheetPass.HEIGHT:
			return _solid_texture(FALLBACK_HEIGHT)
		SpriteSheetLookupBase.SpriteSheetPass.SPECULAR:
			return _solid_texture(FALLBACK_SPECULAR)
		SpriteSheetLookupBase.SpriteSheetPass.EMISSIVE:
			return _solid_texture(FALLBACK_EMISSIVE)
		SpriteSheetLookupBase.SpriteSheetPass.OCCLUSION:
			return _solid_texture(FALLBACK_OCCLUSION)
	return _solid_texture(FALLBACK_EMISSIVE)


## [param pass_sheets] maps [enum SpriteSheetLookupBase.SpriteSheetPass] to whole-sheet textures;
## missing or empty entries fall back to 1x1 defaults. [param default_world_normal] is what an
## entity without [code]normal.png[/code] is shaded as — world up for ground, camera-facing for sprites
## (see [method IsoLightingConfig.camera_facing_world_normal]).
static func create_material(pass_sheets: Dictionary, default_world_normal: Vector3 = Vector3(0.0, 0.0, 1.0)) -> ShaderMaterial:
	IsoLightingConfig.ensure_globals()
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH) as Shader
	apply_pass_sheets(material, pass_sheets, default_world_normal)
	return material


## Rebinds every sampler. Cheap enough to call on action changes; do NOT call per frame — per frame
## only [method set_cell_region] needs to change.
static func apply_pass_sheets(material: ShaderMaterial, pass_sheets: Dictionary, default_world_normal: Vector3 = Vector3(0.0, 0.0, 1.0)) -> void:
	if material == null:
		return
	for sheet_pass in PASS_UNIFORMS:
		var tex: Texture2D = pass_sheets.get(sheet_pass, null)
		if tex == null or tex.get_width() <= 0:
			tex = _fallback_for(sheet_pass, default_world_normal)
		material.set_shader_parameter(PASS_UNIFORMS[sheet_pass], tex)


## Which cell of the sheet this draw uses, in pixels. The only value that changes per animation frame.
static func set_cell_region(material: ShaderMaterial, region: Rect2) -> void:
	if material == null:
		return
	material.set_shader_parameter("cell_region", Vector4(region.position.x, region.position.y, region.size.x, region.size.y))


static func set_sheet_size(material: ShaderMaterial, size: Vector2) -> void:
	if material == null:
		return
	material.set_shader_parameter("sheet_size", Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)))


## Tile layers draw straight from the atlas, so the cell region is the whole sheet and
## [code]sheet_uv()[/code] becomes the identity.
static func set_whole_sheet(material: ShaderMaterial, size: Vector2) -> void:
	set_sheet_size(material, size)
	set_cell_region(material, Rect2(Vector2.ZERO, Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))))
