shader_type canvas_item;

/* Default lit tiles: diffuse from TileMapLayer/TILEMAP [code]TEXTURE[/code] + [code]UV[/code];
 * normals from a second full atlas ([code]normal_atlas[/code]) with the same pixel size and grid as the tile set [code]diffuse.png[/code].
 * Match [code]AnimatedEntity[/code] / engine 2D normal encoding: RGB in [0,1], [code]normal_y_flip[/code] for inverted green. */

uniform sampler2D normal_atlas : source_color, filter_nearest, repeat_disable;
uniform float normal_y_flip : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
	vec4 albedo = texture(TEXTURE, UV);
	COLOR = albedo;
	vec3 nm = texture(normal_atlas, UV).rgb;
	if (normal_y_flip < 0.0) {
		nm.g = 1.0 - nm.g;
	}
	NORMAL_MAP = nm;
}
