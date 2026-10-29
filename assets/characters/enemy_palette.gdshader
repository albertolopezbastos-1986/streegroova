shader_type canvas_item;

uniform vec4 outfit_color : source_color = vec4(0.8, 0.3, 0.4, 1.0);

void fragment() {
	vec4 pixel = COLOR;
	float brightest = max(pixel.r, max(pixel.g, pixel.b));
	float darkest = min(pixel.r, min(pixel.g, pixel.b));
	float lightness = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	float fabric = (1.0 - smoothstep(0.28, 0.43, lightness)) * (1.0 - smoothstep(0.09, 0.22, brightest - darkest));
	vec3 dyed = outfit_color.rgb * lightness * 2.2;
	pixel.rgb = mix(pixel.rgb, dyed, fabric * 0.86);
	COLOR = pixel;
}
