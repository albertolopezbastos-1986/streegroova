shader_type canvas_item;
// Keep the guitar shading and white pickguard while replacing saturated green.
uniform vec4 olive_color : source_color = vec4(0.4392, 0.5098, 0.2196, 1.0);
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
 vec4 pixel = texture(TEXTURE, UV);
 if (pixel.g > pixel.r * 1.6 && pixel.g > pixel.b * 1.6 && pixel.g > 0.12) {
  pixel.rgb = olive_color.rgb * (pixel.g / 0.8);
 }
 COLOR = pixel * tint;
}
