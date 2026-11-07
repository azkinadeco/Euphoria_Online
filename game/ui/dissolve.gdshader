shader_type canvas_item;
// Burn-away death: noise-driven dissolve sweeping upward with a glowing ember edge.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform float edge_width = 0.08;
varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// bottom burns first; noise breaks up the line
	float n = noise(UV * 9.0) * 0.6 + noise(UV * 23.0) * 0.4;
	float h = (1.0 - UV.y) * 0.65 + n * 0.35;
	float t = progress * 1.15;
	float cut = step(h, t);
	float edge = (1.0 - smoothstep(0.0, edge_width, t - h)) * cut;
	vec3 rgb = mix(c.rgb, edge_color.rgb * 1.8, edge);
	float a = c.a * (cut * edge + (1.0 - cut));
	COLOR = vec4(rgb, a) * mod_color;
}
