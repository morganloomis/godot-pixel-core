extends Node2D
## Measures how iso_lit.gdshader actually responds to (a) surface angle, (b) light distance and
## (c) light energy. Uses a flat mid-grey quad with a controlled normal so the art cannot confound it.

const W := 256
const H := 64
const GROUND := Vector2(320, 300)

var _mat: ShaderMaterial
var _light: PointLight2D
var _sprite: Sprite2D
var _flat_light_tex: Texture2D


func _solid(c: Color, w: int = 1, h: int = 1) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


## Normal sweeps left-to-right from facing well away from the light to facing straight at it, so a
## horizontal scan of the render is the shader's transfer curve.
func _normal_ramp() -> ImageTexture:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var elev := deg_to_rad(IsoLightingConfig.get_elevation_degrees())
	for x in W:
		var t := float(x) / float(W - 1)
		var ang := lerpf(-PI * 0.75, PI * 0.5, t)
		# Rotate in the vertical plane that contains the light, then store it the way the
		# pipeline would (sheet frame).
		var world := Vector3(0.0, -cos(ang) * cos(elev), sin(ang)).normalized()
		var c := IsoLitMaterialFactory.encode_sheet_normal(world)
		for y in H:
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _mean_row(shot: Image, y: int, x0: int, x1: int) -> float:
	var total := 0.0
	for x in range(x0, x1):
		total += shot.get_pixel(x, y).r
	return total / maxf(float(x1 - x0), 1.0)


func _ready() -> void:
	IsoLightingConfig.ensure_globals()
	IsoLightingConfig.set_ambient(Color.BLACK, 0.0)

	_mat = IsoLitMaterialFactory.create_material({
		SpriteSheetLookupBase.SpriteSheetPass.NORMAL: _normal_ramp(),
		SpriteSheetLookupBase.SpriteSheetPass.HEIGHT: _solid(Color(0, 0, 0, 1)),
	})
	_sprite = Sprite2D.new()
	_sprite.texture = _solid(Color(0.5, 0.5, 0.5, 1), W, H)   # mid grey: clipping is visible
	_sprite.material = _mat
	_sprite.position = GROUND
	add_child(_sprite)

	_light = PointLight2D.new()
	_light.texture = _solid(Color.WHITE, 512, 512)   # flat: no texture falloff in the way
	_flat_light_tex = _light.texture
	_light.texture_scale = 4.0
	_light.color = Color.WHITE
	_light.energy = 1.0
	_light.height = 40.0
	_light.position = GROUND + Vector2(0, 60)
	add_child(_light)

	print("PROBE_BEGIN")
	await _transfer_curve()
	await _energy_response()
	await _distance_response()
	await _falloff_isolated()
	print("PROBE_END")
	get_tree().quit()


## Sample brightness across the normal ramp: a step means toon shading, a ramp means form.
func _transfer_curve() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var y := int(GROUND.y)
	var vals: Array[float] = []
	var s := ""
	for i in 11:
		var x := int(GROUND.x) - W / 2 + int(float(i) / 10.0 * float(W - 1))
		var v := shot.get_pixel(x, y).r
		vals.append(v)
		s += "%.2f " % v
	print("PROBE transfer across normal sweep: %s" % s)
	var distinct := 0
	for v in vals:
		if v > 0.02 and v < 0.98:
			distinct += 1
	print("PROBE   midtone samples (neither black nor clipped) = %d of 11" % distinct)


func _energy_response() -> void:
	var s := ""
	for e: float in [0.5, 1.0, 2.0, 4.0]:
		_light.energy = e
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		s += "e=%.1f:%.3f  " % [e, _mean_row(shot, int(GROUND.y), int(GROUND.x) + 60, int(GROUND.x) + 120)]
	print("PROBE energy response (lit side mean): %s" % s)
	_light.energy = 1.0


func _distance_response() -> void:
	var s := ""
	# Scale height with distance so the direction to the light is unchanged and only falloff varies.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color.WHITE, Color.BLACK])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	_light.texture = gt
	_light.texture_scale = 3.0
	for d: float in [40.0, 90.0, 160.0, 260.0]:
		_light.position = GROUND + Vector2(0, d)
		_light.height = d * 0.5
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		s += "d=%.0f:%.3f  " % [d, _mean_row(shot, int(GROUND.y), int(GROUND.x) + 60, int(GROUND.x) + 120)]
	print("PROBE distance response (lit side mean): %s" % s)


## Falloff with everything else held still: one fixed up-facing normal, light directly overhead,
## only its height changing. Any variation here is the light texture's falloff and nothing else.
func _falloff_isolated() -> void:
	IsoLitMaterialFactory.apply_pass_sheets(_mat, {
		SpriteSheetLookupBase.SpriteSheetPass.NORMAL:
			_solid(IsoLitMaterialFactory.encode_sheet_normal(Vector3(0, 0, 1)), 8, 8),
		SpriteSheetLookupBase.SpriteSheetPass.HEIGHT: _solid(Color(0, 0, 0, 1)),
	})
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color.WHITE, Color.BLACK])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	_light.texture = gt
	_light.texture_scale = 2.0
	_light.energy = 1.0
	_light.position = GROUND
	var s := ""
	for hgt: float in [20.0, 60.0, 120.0, 200.0]:
		_light.height = hgt
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		s += "h=%.0f:%.3f  " % [hgt, shot.get_pixel(int(GROUND.x), int(GROUND.y)).r]
	print("PROBE falloff vs light height (fixed normal, overhead): %s" % s)
	print("PROBE   note: with a Light2D the falloff curve comes from its texture, and its height")
	print("PROBE   does not enter that lookup - see the known limitation in the README.")
