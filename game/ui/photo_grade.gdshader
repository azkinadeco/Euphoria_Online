shader_type canvas_item;
// Photo Studio colour grading over everything drawn below it (screen texture).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 tint : source_color = vec4(1.0);
uniform float saturation = 1.0;
uniform float contrast = 1.0;
uniform float brightness = 0.0;
uniform float sepia = 0.0;
uniform float vignette = 0.25;
uniform float bloom = 0.0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	if (bloom > 0.0) {
		vec3 b = vec3(0.0);
		for (int i = -2; i <= 2; i++) {
			for (int j = -2; j <= 2; j++) {
				b += texture(screen_tex, SCREEN_UV + vec2(float(i), float(j)) * 0.004).rgb;
			}
		}
		b /= 25.0;
		c = mix(c, max(c, b), bloom);
	}
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(g), c, saturation);
	c = mix(c, vec3(g * 1.07, g * 0.88, g * 0.66), sepia);
	c = (c - 0.5) * contrast + 0.5 + brightness;
	c *= tint.rgb;
	float d = distance(SCREEN_UV, vec2(0.5));
	c *= 1.0 - smoothstep(0.35, 0.85, d) * vignette;
	COLOR = vec4(c, 1.0);
}
