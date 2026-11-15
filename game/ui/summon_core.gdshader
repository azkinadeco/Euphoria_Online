shader_type canvas_item;
render_mode blend_add, unshaded;
// Summon gate: a glowing core that gathers power, rune rings made of thick light arcs, soft rotating rays
// and an expanding shock ring. Driven by game/ui/summon_fx.gd.

uniform vec4 tint : source_color = vec4(0.7, 0.75, 1.0, 1.0);    // current colour of the energy
uniform vec4 hot : source_color = vec4(1.0, 1.0, 1.0, 1.0);      // colour of the very centre
uniform float power = 0.0;      // 0..1 how charged the core is
uniform float rays = 0.0;       // 0..1 strength of the light rays
uniform float burst = 0.0;      // 0..1 progress of the shock ring (0 = none)
uniform float rings = 1.0;      // 0..1 visibility of the rune rings
uniform float aspect = 1.78;
uniform vec2 center = vec2(0.5, 0.5);
uniform float spin = 0.0;       // ring rotation (radians), animated from the script

float hash(float n) { return fract(sin(n) * 43758.5453123); }
float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}
// a band of light at radius r0 with soft edges
float band(float r, float r0, float w) {
	return smoothstep(w, 0.0, abs(r - r0));
}
// ring broken into `n` arcs with gaps, rotating
float arcs(float ang, float n, float gap, float rot) {
	float a = fract((ang + rot) / 6.28318 * n);
	return smoothstep(0.0, 0.06, a) * smoothstep(1.0 - gap, 1.0 - gap - 0.06, a);
}

void fragment() {
	vec2 d = (UV - center) * vec2(aspect, 1.0);
	float r = length(d);
	float ang = atan(d.y, d.x);
	float p = clamp(power, 0.0, 1.5);
	// core: tight hot centre + wide halo, breathing faster as it charges
	float pulse = 1.0 + 0.08 * sin(TIME * (5.0 + p * 9.0));
	float core = exp(-r * (26.0 - p * 9.0) / pulse) * (0.6 + p * 1.2);
	float halo = exp(-r * (5.5 - p * 1.5)) * (0.18 + p * 0.5);
	// rays: wide soft beams, two layers turning against each other
	float rr = noise(ang * 5.0 + TIME * 0.6) * 0.6 + noise(ang * 11.0 - TIME * 0.9 + 4.0) * 0.4;
	rr = smoothstep(0.38, 0.9, rr);
	float ray = rr * exp(-r * 2.2) * smoothstep(0.02, 0.16, r) * rays * 1.6;
	// rune rings: three rings of thick arcs at different speeds, plus a ring of small ticks
	float k = rings * (0.35 + p * 0.65);
	float ring = band(r, 0.30, 0.007) * arcs(ang, 3.0, 0.14, spin) * 1.0
		+ band(r, 0.255, 0.004) * arcs(ang, 7.0, 0.3, -spin * 1.7) * 0.8
		+ band(r, 0.345, 0.003) * 0.55
		+ band(r, 0.20, 0.0035) * arcs(ang, 5.0, 0.5, spin * 2.6) * 0.7;
	float ticks = band(r, 0.322, 0.012) * step(0.72, fract((ang - spin * 0.6) / 6.28318 * 48.0)) * 0.5;
	// glow under the rings so they read as light, not as lines
	float ring_glow = (band(r, 0.30, 0.05) * 0.22 + band(r, 0.345, 0.03) * 0.12) * k;
	// shock ring
	float sr = burst * 1.25;
	float shock = band(r, sr, 0.02 + burst * 0.05) * (1.0 - burst) * step(0.001, burst) * 2.2
		+ exp(-r * 3.0) * (1.0 - burst) * step(0.001, burst) * 1.4;
	float a_t = halo + ray + (ring + ticks) * k + ring_glow + shock;
	vec3 col = tint.rgb * a_t + hot.rgb * core;
	float a = clamp(a_t + core, 0.0, 1.0);
	COLOR = vec4(col / max(a, 0.001), a);
}
