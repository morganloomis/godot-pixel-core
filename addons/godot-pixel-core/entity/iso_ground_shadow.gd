@tool
class_name IsoGroundShadow
extends Sprite2D

## Ground shadow for an [AnimatedEntity], cast from the entity's [code]shadow_map.png[/code]
## height field (R = bottom, G = top, A = coverage) by [code]iso_shadow.gdshader[/code].
##
## Add as a **sibling of the presenter's [code]Sprite2D[/code]** (or anywhere under the body) and point
## [member presenter] at the [AnimatedEntity]. The quad lies on the ground and is drawn with
## [code]blend_sub[/code], so it darkens the floor beneath it by exactly the light each 2D light would
## have delivered. Put it below the entity in draw order ([member CanvasItem.z_index]).
##
## Shadow length and direction are not authored: they come from each light's ground position and
## height, so a light lowered toward the horizon lengthens its shadow on its own.

## Presenter to follow. The shadow reads its action, displayed direction and frame every update so the
## cast silhouette always matches the pose on screen.
@export var presenter: NodePath:
	set(value):
		presenter = value
		if is_node_ready():
			_rebind()

## How many caster cells wide the quad is. The height field only covers one cell, so this is how far
## beyond the caster's own footprint a shadow is allowed to reach before it is clipped.
@export_range(1.0, 8.0, 0.25) var field_extent: float = 3.0:
	set(value):
		field_extent = value
		if is_node_ready():
			_apply_extent()

var _presenter: AnimatedEntity = null
var _material: ShaderMaterial = null
var _bound_key: String = ""

const SHADER_PATH := "res://addons/godot-pixel-core/lighting/iso_shadow.gdshader"

## 1x1 white quad; the drawn size comes from [member Node2D.scale], so [code]UV[/code] spans the quad.
static var _quad_texture: ImageTexture


static func _ensure_quad_texture() -> ImageTexture:
	if _quad_texture == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_quad_texture = ImageTexture.create_from_image(img)
	return _quad_texture


func _ready() -> void:
	texture = _ensure_quad_texture()
	centered = true
	IsoLightingConfig.ensure_globals()
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load(SHADER_PATH) as Shader
	material = _material
	_rebind()
	set_process(not Engine.is_editor_hint())


func _rebind() -> void:
	_presenter = get_node_or_null(presenter) as AnimatedEntity
	_bound_key = ""
	_update_shadow()


func _process(_delta: float) -> void:
	_update_shadow()


func _apply_extent() -> void:
	if _material != null:
		_material.set_shader_parameter("field_extent", field_extent)


## Follows the presenter's current cell and keeps the quad centred on the same ground area the
## height field was rendered for.
func _update_shadow() -> void:
	if _presenter == null or _material == null:
		visible = false
		return
	var lookup := _presenter.sprite_lookup
	if not (lookup is SpriteSheetLookupBase):
		visible = false
		return
	var slb := lookup as SpriteSheetLookupBase
	var eid := _presenter.entity_name if _presenter.entity_name != "" else _presenter.name
	var action: String = _presenter.action
	var cell: AtlasTexture = slb.get_texture(
		eid, action, _presenter.direction, _presenter.frame,
		SpriteSheetLookupBase.SpriteSheetPass.SHADOW_MAP
	)
	if cell == null or cell.atlas == null or cell.region.size.x <= 0.0:
		visible = false
		return
	visible = true

	var key := "%s|%s" % [eid, action]
	if key != _bound_key:
		_material.set_shader_parameter("field_tex", cell.atlas)
		_material.set_shader_parameter(
			"field_sheet_size", Vector2(cell.atlas.get_width(), cell.atlas.get_height())
		)
		_apply_extent()
		_bound_key = key

	var region := cell.region
	_material.set_shader_parameter(
		"field_region", Vector4(region.position.x, region.position.y, region.size.x, region.size.y)
	)
	# The field cell frames exactly the same ground area as the diffuse cell, so the quad must be
	# concentric with the presenter's drawable, then scaled out about that centre.
	var sprite: Sprite2D = _presenter.sprite
	if sprite != null:
		global_position = sprite.global_position + sprite.offset * sprite.global_scale
	var quad := region.size * field_extent
	scale = quad / Vector2(maxf(texture.get_width(), 1.0), maxf(texture.get_height(), 1.0))
	_material.set_shader_parameter("quad_size_px", quad)
