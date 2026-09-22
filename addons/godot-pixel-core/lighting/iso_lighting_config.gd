@tool
class_name IsoLightingConfig
extends RefCounted

## Single place for the isometric camera basis and the lighting look knobs used by
## [code]iso_lit.gdshader[/code]. Everything here is a Godot **global shader parameter**, so values
## fan out to every lit material without an autoload pushing uniforms each frame.
##
## Camera angle is a runtime knob, not a re-render: normal maps are baked in **world** space and this
## config supplies the rotation into the shader's light space, so changing the camera re-lights
## existing art instead of invalidating it.
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

## Measured from the bundled art: left silhouette reads world -X, right silhouette world -Y.
const DEFAULT_YAW_DEGREES := 45.0
## Measured from the bundled tile bake: the ground plane reads (0, 0, 1) and the camera sits 30° above it.
const DEFAULT_ELEVATION_DEGREES := 30.0

## [code]name -> [RenderingServer global var type, default value][/code].
## A [code]static var[/code] rather than a [code]const[/code] so the native enum lookups resolve at
## class init instead of parse time.
static var GLOBAL_DEFINITIONS: Dictionary = {
	AMBIENT_COLOR: [RenderingServer.GLOBAL_VAR_TYPE_COLOR, Color(0.12, 0.13, 0.18, 1.0)],
	AMBIENT_ENERGY: [RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0],
	YAW_ROT: [RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(0.7071068, 0.7071068)],
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
}


## Registers any missing global shader parameter with its default. Safe to call repeatedly.
## Must run before a lit shader compiles, otherwise the shader errors on the undeclared globals.
static func ensure_globals() -> void:
	var present: Dictionary = {}
	for existing_name in RenderingServer.global_shader_parameter_get_list():
		present[String(existing_name)] = true
	for gname in GLOBAL_DEFINITIONS:
		if present.has(gname):
			continue
		var definition: Array = GLOBAL_DEFINITIONS[gname]
		RenderingServer.global_shader_parameter_add(gname, definition[0], definition[1])


static func set_global(gname: String, value: Variant) -> void:
	RenderingServer.global_shader_parameter_set(gname, value)


## Returns the registered value, or [param fallback] when the global is missing or the wrong type.
static func get_global(gname: String, fallback: Variant = null) -> Variant:
	var value: Variant = RenderingServer.global_shader_parameter_get(gname)
	if value == null:
		return fallback
	return value


## Sets the camera basis used to rotate world-space normals and to unsquash ground depth.
static func set_camera(yaw_degrees: float, elevation_degrees: float) -> void:
	ensure_globals()
	var yaw := deg_to_rad(yaw_degrees)
	var elevation := deg_to_rad(elevation_degrees)
	set_global(YAW_ROT, Vector2(cos(yaw), sin(yaw)))
	set_global(COS_ELEVATION, cos(elevation))
	set_global(SIN_ELEVATION, sin(elevation))


static func get_yaw_degrees() -> float:
	var raw: Variant = get_global(YAW_ROT)
	if not (raw is Vector2):
		return DEFAULT_YAW_DEGREES
	var rot: Vector2 = raw
	if rot.length_squared() <= 0.0:
		return DEFAULT_YAW_DEGREES
	return rad_to_deg(atan2(rot.y, rot.x))


static func get_elevation_degrees() -> float:
	var raw_sin: Variant = get_global(SIN_ELEVATION)
	var raw_cos: Variant = get_global(COS_ELEVATION)
	if not (raw_sin is float) or not (raw_cos is float):
		return DEFAULT_ELEVATION_DEGREES
	var s: float = raw_sin
	var c: float = raw_cos
	if s == 0.0 and c == 0.0:
		return DEFAULT_ELEVATION_DEGREES
	return rad_to_deg(atan2(s, c))


## Overall ambient level, changeable at runtime without re-rendering art. Replaces [CanvasModulate]
## on lit scenes, which cannot be used here because it would also multiply emissive.
static func set_ambient(color: Color, energy: float = 1.0) -> void:
	ensure_globals()
	set_global(AMBIENT_COLOR, color)
	set_global(AMBIENT_ENERGY, energy)


## World-space normal pointing straight at the camera: the right fallback for a sprite with no
## [code]normal.png[/code]. Derived from the current basis so it tracks [method set_camera].
static func camera_facing_world_normal() -> Vector3:
	var yaw := deg_to_rad(get_yaw_degrees())
	var elevation := deg_to_rad(get_elevation_degrees())
	return Vector3(-cos(elevation) * sin(yaw), -cos(elevation) * cos(yaw), sin(elevation)).normalized()


## World up: the right fallback normal for ground planes and tile layers.
static func ground_world_normal() -> Vector3:
	return Vector3(0.0, 0.0, 1.0)
