shader_type canvas_item;

// Touch ripple: a soft disc + bright rim expanding from the press point, clipped to a rounded rect.
uniform vec2 center = vec2(0.0);
uniform float prog = 0.0;
uniform vec2 rect_size = vec2(200.0, 50.0);
uniform float radius = 12.0;
uniform vec4 tint : source_color = vec4(1.0, 0.96, 0.88, 1.0);

void fragment() {
	vec2 p = UV * rect_size;
	float far = length(max(center, rect_size - center));
	float r = far * (1.0 - pow(1.0 - prog, 3.0));
	float d = length(p - center);
	float fade = 1.0 - prog;
	float disc = 1.0 - smoothstep(r - 2.0, r, d);
	float rim = smoothstep(r - 7.0, r - 1.5, d) * disc;
	vec2 q = abs(p - rect_size * 0.5) - (rect_size * 0.5 - vec2(radius));
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float mask = clamp(-sd, 0.0, 1.0);
	float a = (disc * 0.2 + rim * 0.42) * fade * mask;
	COLOR = vec4(tint.rgb, a);
}
