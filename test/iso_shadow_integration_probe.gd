extends Node2D
## Integration check: does the real shadow_map.png from pixel_pipe cast a visible shadow in-engine?
## Renders the test scene twice, with the ground shadow enabled and disabled, and diffs. Anything
## that got darker with it on is the shadow, so this cannot be fooled by the floor or the lighting.

func _ready() -> void:
	var scene: PackedScene = load("res://test/test_scene.tscn")
	var inst := scene.instantiate()
	add_child(inst)
	await get_tree().process_frame

	var shadow := inst.get_node_or_null("PlayerEntity/GroundShadow") as IsoGroundShadow
	if shadow == null:
		print("REAL no GroundShadow node found")
		get_tree().quit()
		return

	# Let the presenter resolve its sheets first.
	for _i in 4:
		await RenderingServer.frame_post_draw
	print("REAL shadow node visible=%s (false means no shadow_map.png resolved)" % shadow.visible)

	# _process() re-asserts visible every frame, so stop it before hiding.
	shadow.set_process(false)
	shadow.visible = false
	for _i in 3:
		await RenderingServer.frame_post_draw
	var without := get_viewport().get_texture().get_image()

	shadow.visible = true
	shadow.set_process(true)
	for _i in 3:
		await RenderingServer.frame_post_draw
	var with_shadow := get_viewport().get_texture().get_image()

	var w := without.get_width()
	var h := without.get_height()
	var darker := 0
	var max_drop := 0.0
	var sum_drop := 0.0
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var drop := without.get_pixel(x, y).r - with_shadow.get_pixel(x, y).r
			if drop > 0.02:
				darker += 1
				sum_drop += drop
				max_drop = maxf(max_drop, drop)
	print("REAL darkened samples=%d  max_drop=%.3f  mean_drop=%.3f"
		% [darker, max_drop, sum_drop / maxf(float(darker), 1.0)])
	print("REAL verdict=%s" % ("SHADOW VISIBLE" if darker > 50 and max_drop > 0.05 else "NO SHADOW"))
	get_tree().quit()
