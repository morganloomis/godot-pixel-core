shader_type canvas_item;

/* Isometric lit shader for pre-rendered passes (diffuse, normal, height, specular, emissive, occlusion).
 *
 * Normals are WORLD space (Z up), not screen/tangent space, so this shader writes [code]NORMAL[/code]
 * directly instead of [code]NORMAL_MAP[/code]: the stock path flips green and rebuilds
 * [code]z = sqrt(max(0, 1 - dot(xy, xy)))[/code], which both misreads world-space data and clamps away
 * legitimately back-facing normals (which rim lighting needs).
 *
 * Everything is computed in ONE space, called "light space" below:
 *     (screen-x on the ground, screen-y on the ground, world height), all in pixels.
 * A world normal enters it by a fixed rotation about the vertical axis (the camera yaw), leaving Z alone.
 * Per-pixel height lets [code]LIGHT_VERTEX[/code] report each fragment's real ground position, so lights
 * orbit objects instead of sliding up and down them.
 *
 * Lights must be placed at the screen position of the point DIRECTLY BELOW them on the ground, with
 * [code]height[/code] set to their height above that ground in pixels. This redefines Godot's
 * [code]height[/code] from "out of the screen" to "world up".
 */

// --- per-material: whole sheets, plus which cell of them to use -------------------------------
// Absent passes are bound to 1x1 fallbacks by IsoLitMaterialFactory, so there is no branching here.
uniform sampler2D normal_tex : filter_nearest, repeat_disable;
uniform sampler2D height_tex : filter_nearest, repeat_disable;
uniform sampler2D specular_tex : filter_nearest, repeat_disable;
uniform sampler2D emissive_tex : filter_nearest, repeat_disable;
uniform sampler2D occlusion_tex : filter_nearest, repeat_disable;

// Cell rect within the sheet, in pixels (x, y, w, h). Tile layers set this to the whole sheet,
// which makes sheet_uv() the identity and reproduces the old dual-atlas behaviour.
uniform vec4 cell_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 sheet_size = vec2(1.0, 1.0);

// --- project-wide knobs (Project Settings > Shader Globals) ------------------------------------
global uniform vec4 iso_ambient_color;
global uniform float iso_ambient_energy;
global uniform vec2 iso_yaw_rot;            // (cos, sin) of the camera yaw
global uniform float iso_cos_elevation;     // height -> screen-Y displacement
global uniform float iso_sin_elevation;     // ground depth -> screen-Y displacement
global uniform float iso_terminator_low;
global uniform float iso_terminator_high;
global uniform float iso_rim_power;
global uniform float iso_rim_strength;
global uniform float iso_specular_shininess;
global uniform float iso_specular_strength;
global uniform float iso_height_falloff;    // 0 = off; see "accepted limitations" in the addon README

vec2 sheet_uv(vec2 uv) {
	return (cell_region.xy + uv * cell_region.zw) / sheet_size;
}

// World (X east, Y north, Z up) -> light space. Pure rotation about Z, so Z passes through.
vec3 world_to_light_space(vec3 n) {
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
	vec2 suv = sheet_uv(UV);
	vec4 albedo = texture(TEXTURE, UV);

	NORMAL = normalize(world_to_light_space(texture(normal_tex, suv).rgb * 2.0 - 1.0));

	// 1 alpha step = 1 pixel of height above the ground plane.
	float height_px = texture(height_tex, suv).r * 255.0;
	// Screen-Y grows downward, so shifting DOWN by the projected height lands on the ground point.
	LIGHT_VERTEX = vec3(VERTEX + vec2(0.0, height_px * iso_cos_elevation), height_px);

	float ao = texture(occlusion_tex, suv).r;
	vec3 em = texture(emissive_tex, suv).rgb;
	float cov = emissive_coverage(em);

	// Ambient lives here rather than in a CanvasModulate so emissive can sit on top of it untouched.
	vec3 ambient = iso_ambient_color.rgb * iso_ambient_energy * ao;
	COLOR = vec4(mix(albedo.rgb * ambient, em, cov), albedo.a);
}

void light() {
	// Locals do not carry over from fragment(), so re-sample what we need.
	vec2 suv = sheet_uv(UV);
	vec4 diffuse = texture(TEXTURE, UV);
	float cov = emissive_coverage(texture(emissive_tex, suv).rgb);

	vec3 V = view_dir();
	float inv_sin = 1.0 / max(iso_sin_elevation, 0.0001);

	// Ground depth is squashed by the projection; undo it so the vector is proportional to world space.
	vec3 d;
	float atten = 1.0;
	if (LIGHT_IS_DIRECTIONAL) {
		d = vec3(LIGHT_DIRECTION.xy * vec2(1.0, inv_sin), LIGHT_DIRECTION.z);
	} else {
		d = LIGHT_POSITION - LIGHT_VERTEX;
		d.y *= inv_sin;
		// Godot's falloff texture is sampled in screen space and ignores height. Optionally re-dim by
		// the extra distance the height difference adds; matters for torches close to what they light.
		float ground_sq = dot(d.xy, d.xy);
		atten = mix(1.0, ground_sq / max(ground_sq + d.z * d.z, 0.0001), iso_height_falloff);
	}
	vec3 L = normalize(d);

	float ndl = dot(NORMAL, L);
	// Harsh terminator: a narrow band instead of a soft Lambert ramp. Below it, nothing is added and
	// the pixel falls through to pure ambient from fragment().
	float lambert = smoothstep(iso_terminator_low, iso_terminator_high, ndl);

	vec3 H = normalize(L + V);
	float spec = pow(max(dot(NORMAL, H), 0.0), max(iso_specular_shininess, 0.001));
	spec *= texture(specular_tex, suv).r * iso_specular_strength * lambert;

	// Rim needs no authored mask: with the light behind, the pixels facing it are exactly the ones
	// facing away from the camera, so fresnel and N.L peak together at the silhouette.
	float fresnel = pow(1.0 - clamp(dot(NORMAL, V), 0.0, 1.0), max(iso_rim_power, 0.001));
	float backlit = clamp(-dot(L, V), 0.0, 1.0);
	float rim = fresnel * backlit * clamp(ndl, 0.0, 1.0) * iso_rim_strength;

	// LIGHT_COLOR already carries the light's energy and texture falloff, so neither is applied again.
	// Emissive pixels take no light at all, which keeps them at exactly their authored colour.
	vec3 contribution = LIGHT_COLOR.rgb * (1.0 - cov) * atten * (diffuse.rgb * lambert + vec3(spec + rim));
	LIGHT = vec4(contribution, diffuse.a);
}
