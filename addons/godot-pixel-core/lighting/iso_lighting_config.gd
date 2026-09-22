@tool
class_name IsoLightingConfig
extends RefCounted

## Single place for the isometric camera basis and the lighting look knobs used by
## [code]iso_lit.gdshader[/code]. Everything here is a Godot **global shader parameter**, so values
## fan out to every lit material without an autoload pushing uniforms each frame.
##
## Normal sheets are **pre-rotated by the authoring pipeline**: pixel_pipe bakes world XY rotated by
## **minus the camera yaw** into [code]normal.png[/code], leaving Z untouched. That frame is called the
## **sheet frame** throughout. The shader needs the residual rotation from sheet frame into light
## space, which works out to **twice** the camera yaw - see [method set_camera].
##
## Because the yaw is baked into the art, changing the camera yaw means **re-rendering every sheet**
## and updating this config. Elevation is not baked and stays a pure runtime knob.
##
## Consumers must have these globals registered before any lit shader compiles. [method ensure_globals]
## does that and runs from [method IsoLitMaterialFactory.create_material] before the shader is loaded.

const AMBIENT_COLOR := "iso_ambient_color"
const AMBIENT_ENERGY := "iso_ambient_energy"
const YAW_ROT := "iso_yaw_rot"
const COS_ELEVATION := "iso_cos_elevation"
const SIN_ELEVATION := "iso_sin_elevation"
const TERMINATOR_LOW := "iso_terminator_low"
const TERMINATOR_HIGH := "iso_terminator_high"
const RIM_POWER := "iso_rim_power"
const RIM_STRENGTH := "iso_rim_strength"
const SPECULAR_SHININESS := "iso_specular_shininess"
const SPECULAR_STRENGTH := "iso_specular_strength"
const HEIGHT_FALLOFF := "iso_height_falloff"
const SHADOW_STRENGTH := "iso_shadow_strength"
const SHADOW_SOFTNESS := "iso_shadow_softness"
const SHADOW_MAX_LENGTH := "iso_shadow_max_length"

## Real camera yaw, matching pixel_pipe's [code]NORMAL_CANVAS_YAW_DEG[/code]. Keep the two in sync:
## the pipeline bakes minus this angle into every normal sheet.
const DEFAULT_YAW_DEGREES := 45.0
## The pipeline pre-rotates normals, so the shader applies the residual rotation rather than the
## camera yaw itself. Set false only if the pipeline is changed to emit unrotated world normals.
const SHEET_NORMALS_PREROTATED := true
## Measured from the bundled tile bake: the ground plane reads (0, 0, 1) and the camera sits 30° above it.
const DEFAULT_ELEVATION_DEGREES := 30.0

## [code]name -> [RenderingServer global var type, default value][/code].
## A [code]static var[/code] rather than a [code]const[/code] so the native enum lookups resolve at
## class init instead of parse time.
static var GLOBAL_DEFINITIONS: Dictionary = {
	AMBIENT_COLOR: [RenderingServer.GLOBAL_VAR_TYPE_COLOR, Color(0.12, 0.13, 0.18, 1.0)],
	AMBIENT_ENERGY: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0],
	# cos/sin of 2 x 45 deg: the residual sheet->light rotation, not the camera yaw itself.
	YAW_ROT: [RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(0.0, 1.0)],
	COS_ELEVATION: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.8660254],
	SIN_ELEVATION: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.5],
	# A narrow band is the point: dark environments want a hard wrap, not a soft Lambert ramp.
	TERMINATOR_LOW: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.35],
	TERMINATOR_HIGH: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.45],
	# Low power on purpose: the true silhouette is 1-2 px, so the rim has to reach inward to read.
	RIM_POWER: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 2.0],
	RIM_STRENGTH: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0],
	SPECULAR_SHININESS: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 24.0],
	SPECULAR_STRENGTH: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.5],
	HEIGHT_FALLOFF: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0],
	SHADOW_STRENGTH: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0],
	# Light disc radius in screen px. 0 gives hard shadows; larger widens the penumbra with distance
	# while leaving the contact point crisp.
	SHADOW_SOFTNESS: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 10.0],
	SHADOW_MAX_LENGTH: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 192.0],
}


## Runtime-safe presence check. [method RenderingServer.global_shader_parameter_get_list] and
## [method RenderingServer.global_shader_parameter_get] are **editor only** — outside the editor they
## error out and return nothing — so presence is read from [ProjectSettings] instead, and the camera
## basis is mirrored CPU-side rather than read back from the renderer.
static var _globals_ensured: bool = false
static var _yaw_rot: Vector2 = Vector2(0.0, 1.0)
static var _cos_elevation: float = 0.8660254
static var _sin_elevation: float = 0.5


static func _project_global_value(gname: String, fallback: Variant) -> Variant:
	var key := "shader_globals/" + gname
	if not ProjectSettings.has_setting(key):
		return fallback
	var entry: Variant = ProjectSettings.get_setting(key)
	if entry is Dictionary and (entry as Dictionary).has("value"):
		return (entry as Dictionary)["value"]
	return fallback


## Registers any global shader parameter the project does not already declare, and seeds the CPU
## mirror of the camera basis from the project's authored values. Runs once per session.
static func ensure_globals() -> void:
	if _globals_ensured:
		return
	_globals_ensured = true
	for gname in GLOBAL_DEFINITIONS:
		var definition: Array = GLOBAL_DEFINITIONS[gname]
		if ProjectSettings.has_setting("shader_globals/" + gname):
			continue
		RenderingServer.global_shader_parameter_add(gname, definition[0], definition[1])
	var yaw: Variant = _project_global_value(YAW_ROT, _yaw_rot)
	if yaw is Vector2 and (yaw as Vector2).length_squared() > 0.0:
		_yaw_rot = yaw
	var cos_e: Variant = _project_global_value(COS_ELEVATION, _cos_elevation)
	var sin_e: Variant = _project_global_value(SIN_ELEVATION, _sin_elevation)
	if (cos_e is float or cos_e is int) and (sin_e is float or sin_e is int):
		_cos_elevation = float(cos_e)
		_sin_elevation = float(sin_e)


static func set_global(gname: String, value: Variant) -> void:
	RenderingServer.global_shader_parameter_set(gname, value)


## Sets the camera basis used to rotate sheet-frame normals and to unsquash ground depth.
## [param yaw_degrees] is the **real camera yaw**; the angle handed to the shader is doubled, because
## the pipeline has already rotated the art by minus that yaw.
static func set_camera(yaw_degrees: float, elevation_degrees: float) -> void:
	ensure_globals()
	var shader_yaw := yaw_degrees * 2.0 if SHEET_NORMALS_PREROTATED else yaw_degrees
	var yaw := deg_to_rad(shader_yaw)
	var elevation := deg_to_rad(elevation_degrees)
	_yaw_rot = Vector2(cos(yaw), sin(yaw))
	_cos_elevation = cos(elevation)
	_sin_elevation = sin(elevation)
	set_global(YAW_ROT, _yaw_rot)
	set_global(COS_ELEVATION, _cos_elevation)
	set_global(SIN_ELEVATION, _sin_elevation)


## The real camera yaw, undoing the doubling [method set_camera] applies.
static func get_yaw_degrees() -> float:
	ensure_globals()
	var shader_yaw := rad_to_deg(atan2(_yaw_rot.y, _yaw_rot.x))
	return shader_yaw / 2.0 if SHEET_NORMALS_PREROTATED else shader_yaw


static func get_elevation_degrees() -> float:
	ensure_globals()
	return rad_to_deg(atan2(_sin_elevation, _cos_elevation))


## Overall ambient level, changeable at runtime without re-rendering art. Replaces [CanvasModulate]
## on lit scenes, which cannot be used here because it would also multiply emissive.
static func set_ambient(color: Color, energy: float = 1.0) -> void:
	ensure_globals()
	set_global(AMBIENT_COLOR, color)
	set_global(AMBIENT_ENERGY, energy)


## Sheet-frame normal pointing straight at the camera: the right fallback for a sprite with no
## [code]normal.png[/code]. Expressed in the same pre-rotated frame the pipeline writes, so it can be
## encoded into a 1x1 texture and fed to the shader exactly like real sheet data.
## At 45 deg yaw / 30 deg elevation this is (-0.866, 0, 0.5), matching a measured pipeline bake.
static func camera_facing_sheet_normal() -> Vector3:
	var yaw := deg_to_rad(get_yaw_degrees())
	var elevation := deg_to_rad(get_elevation_degrees())
	var cos_e := cos(elevation)
	if SHEET_NORMALS_PREROTATED:
		return Vector3(-cos_e * sin(2.0 * yaw), -cos_e * cos(2.0 * yaw), sin(elevation)).normalized()
	return Vector3(-cos_e * sin(yaw), -cos_e * cos(yaw), sin(elevation)).normalized()


## Straight up: the right fallback normal for ground planes and tile layers. The pipeline's yaw
## rotation leaves Z untouched, so world up and sheet up are the same vector.
static func ground_sheet_normal() -> Vector3:
	return Vector3(0.0, 0.0, 1.0)
