extends Node2D
## Verifies iso_shadow.gdshader geometry against an analytically known caster.
##
## A synthetic height field holds a disc of "cylinder" 40 px tall at the quad centre. For a light at
## ground distance D and height H, the shadow tip lands at D*h/(H-h) from the centre, so lowering the
## light must lengthen the shadow by a predictable amount rather than just "looking longer".

const FIELD := 128
const CASTER_TOP_PX := 40.0
const CASTER_RADIUS := 12
const EXTENT := 3.0
const CENTRE := Vector2(180, 240)
const LIGHT_D := 150.0

var _mat: ShaderMaterial
var _light: PointLight2D


func _white(size: int = 1) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


## R = bottom (0, planted on the ground), G = top, A = coverage.
func _make_field() -> ImageTexture:
	var img := Image.create(FIELD, FIELD, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := FIELD / 2
	for y in FIELD:
		for x in FIELD:
			if Vector2(x - c, y - c).length() <= float(CASTER_RADIUS):
				img.set_pixel(x, y, Color(0.0, CASTER_TOP_PX / 255.0, 0.0, 1.0))
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	IsoLightingConfig.ensure_globals()
	IsoLightingConfig.set_global(IsoLightingConfig.SHADOW_STRENGTH, 1.0)
	IsoLightingConfig.set_global(IsoLightingConfig.SHADOW_SOFTNESS, 0.0)
	IsoLightingConfig.set_global(IsoLightingConfig.SHADOW_MAX_LENGTH, 400.0)

	# Unshaded white floor so any darkening is purely the shadow quad's subtraction.
	var bg := Sprite2D.new()
	bg.texture = _white()
	bg.scale = Vector2(640, 480)
	bg.position = Vector2(320, 240)
	bg.z_index = -10
	var bg_mat := CanvasItemMaterial.new()
	bg_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	bg.material = bg_mat
	add_child(bg)

	_mat = ShaderMaterial.new()
	_mat.shader = load("res://addons/godot-pixel-core/lighting/iso_shadow.gdshader") as Shader
	var field := _make_field()
	_mat.set_shader_parameter("field_tex", field)
	_mat.set_shader_parameter("field_region", Vector4(0, 0, FIELD, FIELD))
	_mat.set_shader_parameter("field_sheet_size", Vector2(FIELD, FIELD))
	_mat.set_shader_parameter("field_extent", EXTENT)
	var quad := Vector2(FIELD, FIELD) * EXTENT
	_mat.set_shader_parameter("quad_size_px", quad)

	var shadow := Sprite2D.new()
	shadow.texture = _white()
	shadow.scale = quad
	shadow.position = CENTRE
	shadow.material = _mat
	add_child(shadow)

	# Light to the screen-left, so the shadow runs along +X with no isometric Y squash in play.
	_light = PointLight2D.new()
	_light.texture = _white(256)
	_light.texture_scale = 8.0
	_light.position = CENTRE + Vector2(-LIGHT_D, 0)
	add_child(_light)

	print("PROBE_BEGIN")
	for h: float in [100.0, 80.0, 60.0]:
		_light.height = h
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		var measured := _shadow_tip(shot)
		# The caster is a disc, not a pole: its centre and its far edge bracket the true tip.
		var from_centre: float = LIGHT_D * CASTER_TOP_PX / (h - CASTER_TOP_PX)
		var from_edge: float = (
			-LIGHT_D + (h / (h - CASTER_TOP_PX)) * (LIGHT_D + float(CASTER_RADIUS))
		)
		var clipped: float = FIELD * EXTENT * 0.5 - 1.0
		var lo: float = minf(from_centre, from_edge) - 12.0
		var hi: float = minf(maxf(from_centre, from_edge) + 12.0, clipped)
		var ok := measured >= lo and measured <= hi
		print("PROBE light_height=%5.1f  expect %6.1f..%6.1f px  measured=%6.1f px  %s%s"
			% [h, from_centre, from_edge, measured, "OK" if ok else "OUT OF RANGE",
			   "  (clipped by field_extent)" if measured >= clipped - 1.0 else ""])
	# Same low light, wider quad: if the earlier 191 px was extent clipping and not bad math,
	# the shadow should now reach its full analytic length.
	_light.height = 60.0
	_mat.set_shader_parameter("field_extent", 7.0)
	_mat.set_shader_parameter("quad_size_px", Vector2(FIELD, FIELD) * 7.0)
	var wide: Sprite2D = get_child(1) as Sprite2D
	wide.scale = Vector2(FIELD, FIELD) * 7.0
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var wide_shot := get_viewport().get_texture().get_image()
	print("PROBE wide quad (extent 7), light_height=60: expect ~300..336 px, measured=%.1f px"
		% _shadow_tip(wide_shot))
	_mat.set_shader_parameter("field_extent", EXTENT)
	_mat.set_shader_parameter("quad_size_px", Vector2(FIELD, FIELD) * EXTENT)
	wide.scale = Vector2(FIELD, FIELD) * EXTENT

	_light.height = 80.0
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var side_shot := get_viewport().get_texture().get_image()
	var toward := _shadow_run(side_shot, -1)
	var away := _shadow_run(side_shot, 1)
	print("PROBE side: toward-light run=%d px, away-from-light run=%d px  verdict=%s"
		% [toward, away, "CORRECT SIDE" if away > toward * 3 else "WRONG SIDE"])
	await _softness_check()
	_check_node_without_sheet()
	print("PROBE_END")
	get_tree().quit()


## Furthest +X offset from centre that is still in shadow.
func _shadow_tip(shot: Image) -> float:
	var tip := 0.0
	var limit: int = mini(440, shot.get_width() - 1 - int(CENTRE.x))
	for dx in range(CASTER_RADIUS + 2, limit):
		var p := shot.get_pixel(int(CENTRE.x) + dx, int(CENTRE.y))
		if p.r < 0.5:
			tip = float(dx)
	return tip


## With a disc light the contact point should stay crisp while the far end spreads out.
func _softness_check() -> void:
	_light.height = 80.0
	IsoLightingConfig.set_global(IsoLightingConfig.SHADOW_SOFTNESS, 24.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var near := _edge_width(shot, CASTER_RADIUS + 4)
	var far := _edge_width(shot, 120)
	print("PROBE softness: penumbra near contact=%d px, far=%d px  verdict=%s"
		% [near, far, "SOFTENS WITH DISTANCE" if far > near else "NO GRADIENT"])


## Width of the partial-shadow band crossing the shadow edge, scanning in Y at a given +X offset.
func _edge_width(shot: Image, dx: int) -> int:
	var count := 0
	for dy in range(-60, 61):
		var v := shot.get_pixel(int(CENTRE.x) + dx, int(CENTRE.y) + dy).r
		if v > 0.08 and v < 0.92:
			count += 1
	return count


## Contiguous shadowed run starting just outside the caster, in the given X direction.
func _shadow_run(shot: Image, dir: int) -> int:
	var run := 0
	var limit: int = mini(190, int(CENTRE.x) - 1)
	for step in range(CASTER_RADIUS + 3, limit):
		var v := shot.get_pixel(int(CENTRE.x) + dir * step, int(CENTRE.y)).r
		if v < 0.5:
			run += 1
		else:
			break
	return run


## The bundled test art has no shadow_map.png, so the node must hide itself rather than error.
func _check_node_without_sheet() -> void:
	var scene: PackedScene = load("res://addons/godot-pixel-core/entity/animated_entity.tscn")
	var presenter := scene.instantiate() as AnimatedEntity
	presenter.sprite_lookup = AnimatedSpriteSheetLookup.new()
	(presenter.sprite_lookup as SpriteSheetLookupBase).animated_sheet_root = "res://test/art/sprite/"
	presenter.entity_name = "player"
	add_child(presenter)
	var shadow := IsoGroundShadow.new()
	add_child(shadow)
	shadow.presenter = shadow.get_path_to(presenter)
	print("PROBE node without shadow_map.png: visible=%s  verdict=%s"
		% [shadow.visible, "DEGRADES CLEANLY" if not shadow.visible else "SHOULD BE HIDDEN"])
