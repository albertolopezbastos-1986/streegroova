shader_type canvas_item;

// Preserve the supplied sheet; render only its green energy in the golden ulti palette.
void fragment() {
	vec4 pixel = texture(TEXTURE, UV) * COLOR;
	if (pixel.g > 0.55 && pixel.g > pixel.r * 1.08 && pixel.g > pixel.b * 1.12) {
		float light = clamp(pixel.r * 0.6 + pixel.b * 0.4, 0.0, 1.0);
		pixel.rgb = mix(vec3(1.0, 0.67, 0.12), vec3(1.0, 0.94, 0.69), light);
	}
	COLOR = pixel;
}
