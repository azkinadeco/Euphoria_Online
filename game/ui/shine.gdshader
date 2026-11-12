shader_type canvas_item;
render_mode blend_add;

// Periodic diagonal light sweep across a rounded rect (CTA buttons, highlight cards).
uniform float period = 3.6;     // seconds between sweeps
uniform float sweep = 0.75;     // seconds a sweep takes
uniform float offset = 0.0;     // per-instance phase so buttons don't sweep in sync
uniform float width = 0.14;     // band half-width in UV
uniform float strength = 0.5;
uniform vec4 tint : source_color = vec4(1.0, 0.97, 0.85, 1.0);
uniform vec2 rect_size = vec2(200.0, 50.0);
uniform float radius = 12.0;
uniform float inset = 2.0;

void fragment() {
	float t = mod(TIME + offset, period);
	float s = t / sweep;
	if (s > 1.0) {
		COLOR = vec4(0.0);
	} else {
		float skew = 0.45 * rect_size.y / max(rect_size.x, 1.0);
		float pos = mix(-0.25 - skew, 1.25 + skew, s);
		float d = UV.x + (UV.y - 0.5) * skew * 2.0 - pos;
		float band = 1.0 - smoothstep(0.0, width, abs(d));
		band += (1.0 - smoothstep(0.0, width * 0.25, abs(d + width * 1.3))) * 0.45;
		vec2 p = (UV - 0.5) * rect_size;
		vec2 q = abs(p) - (rect_size * 0.5 - vec2(radius));
		float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
		float mask = clamp(-sd - inset, 0.0, 1.0);
		float a = band * strength * mask * sin(s * 3.14159);
		COLOR = vec4(tint.rgb * a, a);
	}
}
