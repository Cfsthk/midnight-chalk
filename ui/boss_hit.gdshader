shader_type canvas_item;

uniform float impact : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(0.86, 1.0, 0.94, 1.0);

void fragment() {
	// Keep the small untextured ground shadow dark throughout a hit.
	if (TEXTURE_PIXEL_SIZE.x < 0.5) {
		COLOR.rgb = mix(COLOR.rgb, hit_color.rgb, impact);
	}
}
