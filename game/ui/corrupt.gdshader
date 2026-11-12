shader_type canvas_item;
// Placeholder "Corrupted / Elite" enemy variant: hue shift + dark outline glow + pulsing veins of light.
uniform float hue_shift = 0.72;
uniform vec4 glow : source_color = vec4(0.75, 0.2, 1.0, 1.0);
uniform float desat = 0.0;     // 0 = keep colour, 1 = full tone (sepia for "Echo" memories)
uniform vec3 tone = vec3(1.18, 1.02, 0.78);   // grey-scale tint used by desat (icy blue for "Frostbound")
varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;
}

vec3 hue(vec3 c, float h) {
	const vec3 k = vec3(0.57735);
	float a = h * 6.28318;
	float ca = cos(a);
	return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = hue(c.rgb, hue_shift) * vec3(0.8, 0.75, 0.9);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, g * tone, desat);
	float a_l = texture(TEXTURE, UV + vec2(-0.01, 0.0)).a;
	float a_r = texture(TEXTURE, UV + vec2(0.01, 0.0)).a;
	float a_u = texture(TEXTURE, UV + vec2(0.0, -0.01)).a;
	float edge = clamp(max(a_l, max(a_r, a_u)) - c.a, 0.0, 1.0);
	float pulse = 0.55 + 0.45 * sin(TIME * 3.0);
	vec4 outline = vec4(glow.rgb, edge * pulse);
	COLOR = mix(outline, c, c.a) * mod_color;
}
