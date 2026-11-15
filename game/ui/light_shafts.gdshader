shader_type canvas_item;
render_mode blend_add, unshaded;
// Soft volumetric light for the lobby: shafts fan out from a light source outside the top-left corner,
// drift slowly, fade with distance, and carry a few floating dust specks. Replaces four flat bars.

uniform vec4 tint : source_color = vec4(1.0, 0.86, 0.6, 1.0);
uniform vec2 origin = vec2(0.08, -0.35);   // light source in screen UV (x right, y down)
uniform float strength = 0.55;
uniform float aspect = 1.78;
uniform float spread_from = 0.55;          // radians: where the fan starts (0 = pointing right)
uniform float spread_to = 1.45;            // where it ends (PI/2 = straight down)
uniform float dust = 1.0;

float hash(float n) { return fract(sin(n) * 43758.5453123); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }
float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

void fragment() {
	vec2 uv = vec2(UV.x * aspect, UV.y);
	vec2 o = vec2(origin.x * aspect, origin.y);
	vec2 d = uv - o;
	float ang = atan(d.y, d.x);
	float dist = length(d);
	// three layers of streaks at different widths, sliding past each other very slowly
	float s = noise(ang * 9.0 + TIME * 0.035) * 0.50
		+ noise(ang * 23.0 - TIME * 0.055 + 7.0) * 0.32
		+ noise(ang * 61.0 + TIME * 0.08 + 19.0) * 0.18;
	s = smoothstep(0.42, 0.86, s);
	// only inside the fan, with soft borders
	float fan = smoothstep(spread_from, spread_from + 0.22, ang) * (1.0 - smoothstep(spread_to - 0.3, spread_to, ang));
	// brightest near the source, gone before the far corner; slow breathing
	float fall = exp(-dist * 1.15) * smoothstep(0.0, 0.35, dist);
	float breathe = 0.86 + 0.14 * sin(TIME * 0.4 + ang * 3.0);
	float shaft = s * fan * fall * breathe;
	// a wide soft bloom around the source so the shafts do not start from nothing
	float bloom = exp(-dist * 2.4) * 0.55 * fan;
	// dust: sparse specks that only show inside the light
	vec2 g = uv * vec2(46.0, 46.0) + vec2(TIME * 0.35, -TIME * 0.22);
	vec2 cell = floor(g);
	vec2 fp = fract(g) - 0.5;
	float h = hash2(cell);
	float speck = 0.0;
	if (h > 0.93) {
		vec2 off = vec2(hash2(cell + 3.1), hash2(cell + 7.7)) - 0.5;
		float tw = 0.5 + 0.5 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);
		speck = smoothstep(0.11, 0.0, length(fp - off * 0.6)) * tw;
	}
	float a = (shaft + bloom) * strength + speck * dust * (shaft * 2.2 + bloom) * strength;
	COLOR = vec4(tint.rgb, clamp(a, 0.0, 0.85));   // additive blend multiplies by alpha itself
}
