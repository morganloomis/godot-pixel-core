shader_type canvas_item;

/* Isometric lit shader for pre-rendered passes (diffuse, normal, height, specular, emissive, occlusion).
 *
 * Normals arrive in the SHEET FRAME: world XY rotated by minus the camera yaw by the authoring
 * pipeline, Z untouched. Not screen/tangent space, so this shader writes [code]NORMAL[/code] directly
 * instead of [code]NORMAL_MAP[/code]: the stock path flips green and rebuilds
 * [code]z = sqrt(max(0, 1 - dot(xy, xy)))[/code], which both misreads this data and clamps away
 * legitimately back-facing normals (which rim lighting needs).
 *
 * Everything is computed in ONE space, called "light space" below:
 *     (screen-x on the ground, screen-y on the ground, world height), all in pixels.
 * A sheet normal enters it by a fixed rotation about the vertical axis, leaving Z alone. That angle is
 * TWICE the camera yaw, because the pipeline already rotated the art by minus the camera yaw.
 * Per-pixel height lets [code]LIGHT_VERTEX[/code] report each fragment's real ground position, so lights
 * orbit objects instead of sliding up and down them.
 *
 * Lights must be placed at the screen position of the point DIRECTLY BELOW them on the ground, with
 * [code]height[/code] set to their height above that ground in pixels. This redefines Godot's
 * [code]height[/code] from "out of the screen" to "world up".
 */

// --- per-material: whole pass sheets ----------------------------------------------------------
// Absent passes are bound to 1x1 fallbacks by IsoLitMaterialFactory, so there is no branching here.
// UV is atlas-space for both drawables -- a Sprite2D with an AtlasTexture reports the region's UVs
// within the atlas, exactly as a TileMapLayer does -- so every pass samples with plain UV and no
// cell/region bookkeeping is needed. (Measured on 4.6.1: region (32,0,32,32) of a 64x64 atlas reports
// centre UV (0.75, 0.25), not (0.5, 0.5).)
uniform sampler2D normal_tex : filter_nearest, repeat_disable;
uniform sampler2D height_tex : filter_nearest, repeat_disable;
uniform sampler2D specular_tex : filter_nearest, repeat_disable;
uniform sampler2D emissive_tex : filter_nearest, repeat_disable;
uniform sampler2D occlusion_tex : filter_nearest, repeat_disable;


// --- project-wide knobs (Project Settings > Shader Globals) ------------------------------------
global uniform vec4 iso_ambient_color;
global uniform float iso_ambient_energy;
global uniform vec2 iso_yaw_rot;            // (cos, sin) of the residual sheet->light rotation
global uniform float iso_cos_elevation;     // height -> screen-Y displacement
global uniform float iso_sin_elevation;     // ground depth -> screen-Y displacement
global uniform float iso_terminator_low;
global uniform float iso_terminator_high;
global uniform float iso_terminator_form;   // 0 = flat toon lit side, 1 = full N.L shaping above the terminator
global uniform float iso_rim_power;
global uniform float iso_rim_strength;
global uniform float iso_specular_shininess;
global uniform float iso_specular_strength;
global uniform float iso_height_falloff;        // 0 = off, 1 = full height-based dimming
global uniform float iso_height_falloff_scale;  // px of height at which that dimming reaches half

// Sheet frame -> light space. Pure rotation about Z, so Z passes through.
vec3 sheet_to_light_space(vec3 n) {
	float c = iso_yaw_rot.x;
	float s = iso_yaw_rot.y;
	return vec3(n.x * c - n.y * s, -n.x * s - n.y * c, n.z);
}

// Emissive is authored as the literal screen colour, so black means "not emissive".
float emissive_coverage(vec3 em) {
	return clamp(max(max(em.r, em.g), em.b), 0.0, 1.0);
}

// Toward the viewer, in light space. Constant because the camera is orthographic.
vec3 view_dir() {
	return vec3(0.0, iso_cos_elevation, iso_sin_elevation);
}

void fragment() {
	vec4 albedo = texture(TEXTURE, UV);

	NORMAL = normalize(sheet_to_light_space(texture(normal_tex, UV).rgb * 2.0 - 1.0));

	// height.png R channel: 1 step = 1 pixel of height above the ground plane.
	float height_px = texture(height_tex, UV).r * 255.0;
	// Screen-Y grows downward, so shifting DOWN by the projected height lands on the ground point.
	LIGHT_VERTEX = vec3(VERTEX + vec2(0.0, height_px * iso_cos_elevation), height_px);

	float ao = texture(occlusion_tex, UV).r;
	vec3 em = texture(emissive_tex, UV).rgb;
	float cov = emissive_coverage(em);

	// Ambient lives here rather than in a CanvasModulate so emissive can sit on top of it untouched.
	vec3 ambient = iso_ambient_color.rgb * iso_ambient_energy * ao;
	COLOR = vec4(mix(albedo.rgb * ambient, em, cov), albedo.a);
}

void light() {
	// Locals do not carry over from fragment(), so re-sample what we need.
	vec4 diffuse = texture(TEXTURE, UV);
	float cov = emissive_coverage(texture(emissive_tex, UV).rgb);

	vec3 V = view_dir();
	float inv_sin = 1.0 / max(iso_sin_elevation, 0.0001);

	// Ground depth is squashed by the projection; undo it so the vector is proportional to world space.
	vec3 d;
	float atten = 1.0;
	if (LIGHT_IS_DIRECTIONAL) {
		// LIGHT_DIRECTION points TOWARD the light, same as the positional vector, so no sign flip.
		// Measured on 4.6.1: DirectionalLight2D at rotation 90° lights a screen-right-facing normal,
		// 270° lights screen-left. Its `height` becomes the sun's elevation.
		d = vec3(LIGHT_DIRECTION.xy * vec2(1.0, inv_sin), LIGHT_DIRECTION.z);
	} else {
		d = LIGHT_POSITION - LIGHT_VERTEX;
		d.y *= inv_sin;
		// Godot samples the light's falloff texture in SCREEN space, so the light's height never
		// enters it: raising a light straight up changes its brightness not at all. This optionally
		// re-dims by the height difference. Referenced against a scale rather than the ground
		// distance, so a light directly overhead stays bright instead of falling to zero.
		float k = max(iso_height_falloff_scale, 0.0001);
		atten = mix(1.0, (k * k) / (k * k + d.z * d.z), iso_height_falloff);
	}
	vec3 L = normalize(d);

	float ndl = dot(NORMAL, L);
	// Harsh terminator: a narrow band instead of a soft Lambert ramp. Below it, nothing is added and
	// the pixel falls through to pure ambient from fragment().
	float lit = smoothstep(iso_terminator_low, iso_terminator_high, ndl);
	// ...but a bare step flattens the lit side to one value, so all the form disappears. Keep the
	// N.L gradient *inside* the lit region: hard cut at the terminator, shape above it.
	float form = mix(1.0, clamp(ndl, 0.0, 1.0), iso_terminator_form);
	float lambert = lit * form;

	vec3 H = normalize(L + V);
	float spec = pow(max(dot(NORMAL, H), 0.0), max(iso_specular_shininess, 0.001));
	spec *= texture(specular_tex, UV).r * iso_specular_strength * lambert;

	// Rim needs no authored mask: with the light behind, the pixels facing it are exactly the ones
	// facing away from the camera, so fresnel and N.L peak together at the silhouette.
	float fresnel = pow(1.0 - clamp(dot(NORMAL, V), 0.0, 1.0), max(iso_rim_power, 0.001));
	float backlit = clamp(-dot(L, V), 0.0, 1.0);
	float rim = fresnel * backlit * clamp(ndl, 0.0, 1.0) * iso_rim_strength;

	// LIGHT_COLOR carries the light's colour and its texture falloff, but NOT its energy -- measured,
	// not assumed: sweeping energy 0.5 to 4.0 moved the result not at all until this was added.
	// Emissive pixels take no light at all, which keeps them at exactly their authored colour.
	vec3 contribution = LIGHT_COLOR.rgb * LIGHT_ENERGY * (1.0 - cov) * atten
		* (diffuse.rgb * lambert + vec3(spec + rim));
	LIGHT = vec4(contribution, diffuse.a);
}
