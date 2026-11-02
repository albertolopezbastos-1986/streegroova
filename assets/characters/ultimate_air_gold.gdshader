shader_type canvas_item;

// Tint the energy in the aerial sheet without changing clothing or skin.
uniform vec4 aura_color : source_color = vec4(1.0, 0.82, 0.36, 1.0);
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (pixel.g > 0.55 && pixel.g > pixel.r * 1.08 && pixel.g > pixel.b * 1.12) {
		float light = clamp(pixel.r * 0.6 + pixel.b * 0.4, 0.0, 1.0);
		pixel.rgb = mix(aura_color.rgb, mix(aura_color.rgb, vec3(1.0), 0.65), light);
	}
	COLOR = pixel * tint;
}
