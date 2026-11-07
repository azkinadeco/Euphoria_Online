shader_type canvas_item;
// "Pseudo-Live2D" placeholder until real Live2D/Spine rigs exist.
// Works on any transparent full-body hero art:
//  - breathing: the chest band gently expands/contracts
//  - hair & cloth sway: outer edges and lower parts drift with a soft wave
//  - head bob: the top of the image nods slightly
//  - rim light that follows the sway
uniform float strength = 1.0;
uniform float speed = 1.0;
uniform float seed = 0.0;
uniform vec4 rim_color : source_color = vec4(1.0, 0.85, 1.0, 1.0);
uniform float rim = 0.25;
// In Godot 4 the fragment COLOR already contains the texture, so keep the pure
// vertex colour (modulate) separately — otherwise the art is multiplied twice (darker).
varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;
}

void fragment() {
	float t = TIME * speed + seed;
	vec2 uv = UV;
	// breathing: horizontal stretch around the chest (y ~ 0.25..0.5)
	float chest = smoothstep(0.18, 0.32, uv.y) * (1.0 - smoothstep(0.42, 0.56, uv.y));
	float breath = sin(t * 1.6) * 0.006 * strength * chest;
	uv.x = (uv.x - 0.5) * (1.0 - breath) + 0.5;
	uv.y += sin(t * 1.6) * 0.003 * strength * chest;
	// head bob (top 20%)
	float head = 1.0 - smoothstep(0.0, 0.22, uv.y);
	uv.y += sin(t * 0.8 + 1.3) * 0.004 * strength * head;
	uv.x += sin(t * 0.7) * 0.003 * strength * head;
	// hair / cloth sway: stronger at the sides and lower half
	float side = smoothstep(0.18, 0.5, abs(uv.x - 0.5));
	float low = smoothstep(0.35, 1.0, uv.y);
	float sway = sin(t * 1.1 + uv.y * 6.0) * 0.006 + sin(t * 2.3 + uv.y * 13.0) * 0.002;
	uv.x += sway * strength * (side * 0.8 + low * 0.35);
	vec4 c = texture(TEXTURE, uv);
	// soft rim light on the silhouette edge
	float a_l = texture(TEXTURE, uv + vec2(-0.004, 0.0)).a;
	float a_r = texture(TEXTURE, uv + vec2(0.004, 0.0)).a;
	float edge = clamp(abs(a_l - a_r) * 1.5, 0.0, 1.0) * c.a;
	float pulse = 0.6 + 0.4 * sin(t * 1.2);
	c.rgb = mix(c.rgb, rim_color.rgb, edge * rim * pulse);
	COLOR = c * mod_color;
}
