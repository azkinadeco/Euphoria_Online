shader_type canvas_item;
// Rarity border + aura drawn around a card (UI.rarity_frame). The ColorRect is `pad` px larger than the
// card on every side; the ring sits on the card edge and the aura fades outward from it.
// mode: 0 solid colour, 1 LR rainbow, 2 GR white hologram, 3 OR cosmic black, 4 MR magenta-red.

uniform vec2 rect_size = vec2(160.0, 200.0);
uniform float pad = 8.0;
uniform float radius = 10.0;
uniform float width = 2.0;
uniform vec4 base_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform int mode = 0;
uniform float aura = 0.6;      // aura strength (0 = border only)
uniform float speed = 1.0;

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * rect_size;
	vec2 c = rect_size * 0.5;
	vec2 half_card = c - vec2(pad);
	float d = sd_round_box(px - c, half_card, radius);   // 0 on the card edge, < 0 inside
	float t = TIME * speed;
	// position around the edge, 0..1 (for travelling colour)
	float ang = atan(px.y - c.y, px.x - c.x) / 6.2831853 + 0.5;

	vec3 col = base_color.rgb;
	float shine = 0.0;
	if (mode == 1) {
		col = mix(hue(fract(ang - t * 0.18)), vec3(1.0), 0.12);
	} else if (mode == 2) {
		// pearly white with a faint iridescent sheen and a bright travelling glint
		vec3 iri = hue(fract(ang * 2.0 + t * 0.12));
		col = mix(vec3(0.97, 0.98, 1.0), iri, 0.22);
		shine = pow(max(0.0, cos((ang - fract(t * 0.25)) * 6.2831853)), 24.0);
	} else if (mode == 3) {
		// deep violet-black ring with twinkling star specks
		col = mix(vec3(0.04, 0.0, 0.1), vec3(0.42, 0.22, 0.9), 0.5 + 0.5 * sin(ang * 12.566 - t * 1.4));
		vec2 cell = floor(px / 3.0);
		float st = step(0.93, hash(cell)) * (0.5 + 0.5 * sin(t * 3.0 + hash(cell + 7.0) * 30.0));
		shine = st;
	} else if (mode == 4) {
		col = mix(vec3(1.0, 0.12, 0.55), vec3(1.0, 0.18, 0.12), 0.5 + 0.5 * sin(ang * 12.566 - t * 1.2));
	}

	// ring on the edge
	float ring = 1.0 - smoothstep(width * 0.5, width * 0.5 + 1.0, abs(d + width * 0.5));
	// aura outside the card only
	float out_d = max(d, 0.0);
	float glow = (1.0 - smoothstep(0.0, pad, out_d)) * step(0.0, d) * aura;
	glow *= 0.75 + 0.25 * sin(t * 2.0);   // breathing
	vec3 gcol = (mode == 3) ? vec3(0.45, 0.25, 0.95) : col;

	float a = max(ring, glow * glow * 0.85);
	vec3 rgb = mix(gcol, col, ring) + vec3(shine) * ring;
	COLOR = vec4(rgb, clamp(a, 0.0, 1.0) * base_color.a);
}
