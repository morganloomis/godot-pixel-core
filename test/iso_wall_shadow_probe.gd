extends Node2D
## Verifies raised receive in iso_lit.gdshader against an analytically known cylinder caster.
##
## Occupancy encoding matches the floor probe (R=bottom, G=top, A=coverage). The camera looks
## straight down (elevation 90°) so LIGHT_VERTEX.xy stays on the ground point and a small lit
## quad can stand in for a wall or prop at a chosen height.

const FIELD := 128
const CASTER_TOP_PX := 40.0
const CASTER_RADIUS := 12
const CENTRE := Vector2(220, 260)
const LIGHT_D := 150.0
const WALL_X := 80.0
const PROP_X := 96.0
const QUAD := 20

var _wall_mat: ShaderMaterial
var _floor_mat: ShaderMaterial
var _prop_mat: ShaderMaterial
var _light: PointLight2D
var _wall: Sprite2D
var _floor: Sprite2D
var _prop: Sprite2D


func _solid(c: Color, w: int = 1, h: int = 1) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


func _make_field() -> ImageTexture:
	var img := Image.create(FIELD, FIELD, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := FIELD / 2
	for y in FIELD:
		for x in FIELD:
			if Vector2(x - c, y - c).length() <= float(CASTER_RADIUS):
				img.set_pixel(x, y, Color(0.0, CASTER_TOP_PX / 255.0, 0.0, 1.0))
	return ImageTexture.create_from_image(img)


func _height_tex(height_px: float) -> ImageTexture:
	return _solid(Color(height_px / 255.0, 0.0, 0.0, 1.0), QUAD, QUAD)


func _facing_tex() -> ImageTexture:
	return _solid(IsoLitMaterialFactory.encode_sheet_normal(Vector3(-1.0, 0.0, 0.0)), QUAD, QUAD)


func _lit_quad(height_px: float) -> ShaderMaterial:
	return IsoLitMaterialFactory.create_material({
		SpriteSheetLookupBase.SpriteSheetPass.NORMAL: _facing_tex(),
		SpriteSheetLookupBase.SpriteSheetPass.HEIGHT: _height_tex(height_px),
	})


func _set_height(mat: ShaderMaterial, height_px: float) -> void:
	IsoLitMaterialFactory.apply_pass_sheets(mat, {
		SpriteSheetLookupBase.SpriteSheetPass.NORMAL: _facing_tex(),
		SpriteSheetLookupBase.SpriteSheetPass.HEIGHT: _height_tex(height_px),
	})


func _ready() -> void:
	IsoLightingConfig.ensure_globals()
	# Identity sheet->light yaw; 90° elevation keeps ground XY = VERTEX (no height squash).
	IsoLightingConfig.set_camera(-45.0, 90.0)
	IsoLightingConfig.set_ambient(Color.BLACK, 0.0)
	IsoLightingConfig.set_global(IsoLightingConfig.SHADOW_STRENGTH, 1.0)
	IsoLightingConfig.set_global(IsoLightingConfig.SHADOW_SOFTNESS, 0.0)
	IsoLightingConfig.set_global(IsoLightingConfig.SHADOW_MAX_LENGTH, 400.0)

	var bg := Sprite2D.new()
	bg.texture = _solid(Color(0.12, 0.12, 0.12, 1))
	bg.scale = Vector2(640, 480)
	bg.position = Vector2(320, 240)
	bg.z_index = -10
	var bg_mat := CanvasItemMaterial.new()
	bg_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	bg.material = bg_mat
	add_child(bg)

	_wall_mat = _lit_quad(8.0)
	_wall = Sprite2D.new()
	_wall.texture = _solid(Color(0.55, 0.55, 0.55, 1), QUAD, QUAD)
	_wall.material = _wall_mat
	_wall.position = CENTRE + Vector2(WALL_X, 0)
	add_child(_wall)

	_prop_mat = _lit_quad(12.0)
	_prop = Sprite2D.new()
	_prop.texture = _solid(Color(0.55, 0.55, 0.55, 1), QUAD, QUAD)
	_prop.material = _prop_mat
	_prop.position = CENTRE + Vector2(PROP_X, 0)
	add_child(_prop)

	_floor_mat = _lit_quad(0.0)
	_floor = Sprite2D.new()
	_floor.texture = _solid(Color(0.55, 0.55, 0.55, 1), QUAD, QUAD)
	_floor.material = _floor_mat
	_floor.position = CENTRE + Vector2(WALL_X, 36)
	add_child(_floor)

	IsoLightingConfig.set_manual_shadow_casters([{
		"tex": _make_field(),
		"origin": CENTRE,
		"cell": Vector2(FIELD, FIELD),
		"region": Vector4(0, 0, FIELD, FIELD),
		"sheet": Vector2(FIELD, FIELD),
	}])

	_light = PointLight2D.new()
	_light.texture = _solid(Color.WHITE, 512, 512)
	_light.texture_scale = 8.0
	_light.color = Color.WHITE
	_light.energy = 2.0
	_light.position = CENTRE + Vector2(-LIGHT_D, 0)
	_light.height = 80.0
	add_child(_light)

	print("PROBE_BEGIN")
	var empty_shadow := IsoGroundShadow.new()
	add_child(empty_shadow)
	IsoLightingConfig.publish_shadow_casters()
	print("PROBE published casters=%d (empty IsoGroundShadow must not add a slot)  verdict=%s"
		% [IsoLightingConfig.published_shadow_caster_count(),
		   "OK" if IsoLightingConfig.published_shadow_caster_count() == 1 else "SLOT LEAK"])
	empty_shadow.queue_free()
	var tip := _analytic_tip(WALL_X, 80.0)
	print("PROBE analytic wall tip=%.1f px  prop tip=%.1f px"
		% [tip, _analytic_tip(PROP_X, 80.0)])

	await _sweep_wall()
	await _check_prop()
	await _check_floor()
	await _check_self_skip()
	print("PROBE_END")
	get_tree().quit()


func _analytic_tip(wall_x: float, light_h: float) -> float:
	var s := (wall_x - float(CASTER_RADIUS)) / (wall_x + LIGHT_D)
	return (CASTER_TOP_PX - s * light_h) / maxf(1.0 - s, 0.0001)


func _sample(shot: Image, pos: Vector2) -> float:
	var x := clampi(int(pos.x), 0, shot.get_width() - 1)
	var y := clampi(int(pos.y), 0, shot.get_height() - 1)
	return shot.get_pixel(x, y).r


func _sweep_wall() -> void:
	var tip := _analytic_tip(WALL_X, _light.height)
	var shadowed_ok := 0
	var lit_ok := 0
	var last_dark := -1.0
	for h: float in [2.0, 8.0, 14.0, 20.0, 26.0, 34.0, 48.0]:
		_set_height(_wall_mat, h)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var v := _sample(get_viewport().get_texture().get_image(), _wall.position)
		var expect_dark := h < tip - 4.0
		var expect_lit := h > tip + 4.0
		var dark := v < 0.22
		if expect_dark and dark:
			shadowed_ok += 1
			last_dark = h
		if expect_lit and not dark:
			lit_ok += 1
		print("PROBE wall h=%5.1f  sample=%.3f  expect=%s  %s"
			% [h, v, "DARK" if expect_dark else ("LIT" if expect_lit else "BAND"),
			   "OK" if (expect_dark and dark) or (expect_lit and not dark) or (not expect_dark and not expect_lit)
			   else "WRONG"])
	print("PROBE wall sweep: below-tip dark=%d  above-tip lit=%d  last_dark=%.1f  verdict=%s"
		% [shadowed_ok, lit_ok, last_dark,
		   "OK" if shadowed_ok >= 2 and lit_ok >= 1 else "OUT OF RANGE"])


func _check_prop() -> void:
	var tip := _analytic_tip(PROP_X, _light.height)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var v := _sample(get_viewport().get_texture().get_image(), _prop.position)
	var expect_dark := 12.0 < tip - 4.0
	print("PROBE prop h=12 tip=%.1f sample=%.3f  verdict=%s"
		% [tip, v, "SHADOWED" if expect_dark and v < 0.22 else ("LIT" if not expect_dark and v > 0.30 else "WRONG")])


func _check_floor() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var v := _sample(get_viewport().get_texture().get_image(), _floor.position)
	print("PROBE height0 floor=%.3f  verdict=%s"
		% [v, "SKIPPED RECEIVE" if v > 0.30 else "FALSE SHADOW"])


func _check_self_skip() -> void:
	_set_height(_wall_mat, 8.0)
	_wall_mat.set_shader_parameter("shadow_self_origin", CENTRE)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var v := _sample(get_viewport().get_texture().get_image(), _wall.position)
	print("PROBE self-skip h=8 sample=%.3f  verdict=%s"
		% [v, "SKIPPED SELF" if v > 0.30 else "SELF SHADOWED"])
