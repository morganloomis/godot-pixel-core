shader_type canvas_item;
render_mode blend_sub;

/* Ground shadows cast from the bottom/top height field (`shadow_map.png`).
 *
 * Drawn as a quad lying on the ground under the caster. For each ground pixel it marches back
 * toward the light and asks whether the caster's vertical extent intersects the ray. Because
 * `shadow_map.png` is the ground plane rendered through the sprite camera, a ground point maps to a
 * texel by the same projection the sprite uses, and the march is a straight line in screen space:
 * both the fragment and the light are already projected, so the isometric squash needs no undoing.
 *
 * `blend_sub` plus a `light()` body means each light subtracts exactly the light it would have
 * delivered. Culling, masks, colour and energy all come from the light node, and a warm torch's
 * shadow correctly leaves the cool ambient behind instead of painting flat grey.
 *
 * Shape falls out of the geometry rather than being faked: a low light makes the ray to it shallow,
 * so it stays inside the caster over a longer ground distance and the shadow lengthens. Softness
 * comes from treating the light as a disc and averaging several rays -- near the contact point all
 * rays pass through nearly the same place so the edge stays crisp, and it widens with distance.
 */

// Ground height field: R = bottom, G = top (both 1 step = 1 px), A = coverage.
uniform sampler2D field_tex : filter_nearest, repeat_disable;
uniform vec4 field_region = vec4(0.0, 0.0, 1.0, 1.0);   // cell rect within the sheet, in pixels
uniform vec2 field_sheet_size = vec2(1.0, 1.0);
uniform vec2 quad_size_px = vec2(128.0, 128.0);         // on-screen size of this quad
// How many caster cells wide the quad is. >1 lets a shadow reach beyond the caster's own footprint.
uniform float field_extent = 3.0;

global uniform float iso_sin_elevation;
global uniform float iso_shadow_strength;
global uniform float iso_shadow_softness;     // light disc radius in screen px; 0 = hard shadows
global uniform float iso_shadow_max_length;   // furthest a shadow is traced, in screen px

const int SHADOW_RAYS = 8;
const int SHADOW_STEPS = 24;
const float GOLDEN_ANGLE = 2.39996323;

// Is the caster's vertical extent in the way at this point along the ray?
float occluded_at(vec2 screen_pos, vec2 frag_screen, vec2 frag_uv, float ray_height) {
	vec2 quad_uv = frag_uv + (screen_pos - frag_screen) / quad_size_px;
	vec2 cell_uv = (quad_uv - 0.5) * field_extent + 0.5;
	if (cell_uv.x < 0.0 || cell_uv.x > 1.0 || cell_uv.y < 0.0 || cell_uv.y > 1.0) {
		return 0.0;
	}
	vec4 field = texture(field_tex, (field_region.xy + cell_uv * field_region.zw) / field_sheet_size);
	if (field.a < 0.5) {
		return 0.0;   // nothing stands above this ground point
	}
	float bottom = field.r * 255.0;
	float top = field.g * 255.0;
	// A slab test, not a heightfield test: without the top the ray could never leave the caster and
	// shadows would run on forever, and without the bottom a lifted foot could not detach its shadow.
	return (ray_height >= bottom && ray_height <= top) ? 1.0 : 0.0;
}

// Marches one ray from this ground pixel toward a (possibly jittered) light position.
float trace_ray(vec2 frag_screen, vec2 frag_uv, vec2 to_light, float light_height) {
	float dist = max(length(to_light), 0.001);
	// Bound the march so a distant light does not spend every step far past the caster.
	float s_max = min(1.0, iso_shadow_max_length / dist);
	for (int i = 1; i <= SHADOW_STEPS; i++) {
		float s = s_max * float(i) / float(SHADOW_STEPS);
		if (occluded_at(frag_screen + to_light * s, frag_screen, frag_uv, light_height * s) > 0.5) {
			return 1.0;
		}
	}
	return 0.0;
}

void fragment() {
	// Subtracting black is a no-op, so an unlit quad leaves the ground untouched.
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}

void light() {
	// VERTEX is not exposed to light(); LIGHT_VERTEX carries the same canvas position (its default
	// value is vec3(vertex, 0.0), and this shader's fragment() leaves it alone).
	vec2 frag_screen = LIGHT_VERTEX.xy;

	vec2 to_light;
	float light_height;
	if (LIGHT_IS_DIRECTIONAL) {
		// No position to aim at, so build a far stand-in along the light direction. Ground XY is
		// squashed by the projection while height is not, so the ratio is taken in world proportions.
		float inv_sin = 1.0 / max(iso_sin_elevation, 0.0001);
		vec3 world_dir = normalize(vec3(LIGHT_DIRECTION.x * 1.0, LIGHT_DIRECTION.y * inv_sin, LIGHT_DIRECTION.z));
		vec2 ground_dir = world_dir.xy;
		float ground_len = max(length(ground_dir), 0.0001);
		float reach = iso_shadow_max_length;
		vec2 world_offset = normalize(ground_dir) * reach;
		to_light = vec2(world_offset.x, world_offset.y * iso_sin_elevation);
		light_height = reach * world_dir.z / ground_len;
	} else {
		to_light = LIGHT_POSITION.xy - frag_screen;
		light_height = LIGHT_POSITION.z;
	}

	float shadow = 0.0;
	// A light at or below the ground plane casts nothing meaningful. Guarded rather than returned
	// early: `return` is not allowed in the light processor function.
	if (light_height > 0.0) {
		for (int r = 0; r < SHADOW_RAYS; r++) {
			// Vogel disc: even coverage of the light's area without a lookup table.
			float radius = sqrt((float(r) + 0.5) / float(SHADOW_RAYS)) * iso_shadow_softness;
			float angle = float(r) * GOLDEN_ANGLE;
			vec2 jitter = vec2(cos(angle), sin(angle)) * radius;
			shadow += trace_ray(frag_screen, UV, to_light + jitter, light_height);
		}
		shadow /= float(SHADOW_RAYS);
	}

	LIGHT = vec4(LIGHT_COLOR.rgb * shadow * iso_shadow_strength, 1.0);
}
