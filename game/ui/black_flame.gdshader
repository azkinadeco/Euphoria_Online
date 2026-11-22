shader_type canvas_item;
// Black-flame aura for Abyss (Evolution tier 4) stars, drawn on a ColorRect behind the star row.
// UV.x runs along the row (one flame per star), UV.y = 0 at the top, 1 at the star baseline.
// Noise flames scroll upward; near-black violet core, bright violet rim, soft transparent edges.

uniform float stars = 6.0;
uniform float speed = 1.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = TIME * speed + seed;
	vec2 uv = UV;
	// one tongue per star: strongest over the star centre
	float cell = fract(uv.x * stars);
	float bump = 1.0 - abs(cell - 0.5) * 2.0;
	bump = smoothstep(0.0, 1.0, bump);
	float up = 1.0 - uv.y;                                    // 0 at the stars, 1 at the top
	float n = fbm(vec2(uv.x * stars * 1.7, uv.y * 2.6 + t * 1.8));
	float n2 = fbm(vec2(uv.x * stars * 3.1 + 7.0, uv.y * 4.0 + t * 2.6));
	float flame = bump * 0.85 + n * 0.75 + n2 * 0.25 - up * 1.35 - 0.2;
	float a = smoothstep(0.0, 0.35, flame);
	float rim = smoothstep(0.0, 0.18, flame) - smoothstep(0.18, 0.55, flame);
	vec3 core = vec3(0.03, 0.0, 0.07);
	vec3 edge = vec3(0.62, 0.18, 1.0);
	vec3 col = mix(core, edge, clamp(rim * 1.4, 0.0, 1.0));
	// fade the very bottom so the flames rise out of the stars instead of sitting on a line
	a *= smoothstep(1.0, 0.82, uv.y) * 0.95;
	COLOR = vec4(col, a);
}
