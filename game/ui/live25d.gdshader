shader_type canvas_item;
// 2.5D "live" illustration: depth-map parallax + Live2D-style idle rig on ONE painting.
// depth_tex: white = near, black = far. tilt (-1..1) comes from the pointer / idle orbit.
uniform sampler2D depth_tex : filter_linear;
uniform vec2 tilt = vec2(0.0);
uniform float strength = 0.018;
uniform float aspect = 0.857;
uniform float calm = 1.0;            // 0.35 with reduce-fx
uniform bool generic = false;        // auto depth map: parallax + breathing + 3D light only
// corrupted / variant look (mirror, hollow, echo, ashen, feral) — same as corrupt.gdshader
uniform bool corrupt_on = false;
uniform float hue_shift = 0.72;
uniform float desat = 0.0;
uniform vec3 tone = vec3(1.18, 1.02, 0.78);
uniform vec4 variant_glow : source_color = vec4(0.75, 0.2, 1.0, 1.0);
uniform vec2 head_c = vec2(0.46, 0.30);
uniform vec2 head_r = vec2(0.11, 0.095);
uniform vec2 neck = vec2(0.48, 0.378);
uniform vec2 chest = vec2(0.49, 0.46);
uniform vec2 eye = vec2(0.473, 0.309);
uniform vec2 eye_size = vec2(0.021, 0.0098);
uniform vec2 mouth = vec2(0.502, 0.3496);
uniform vec2 mouth_size = vec2(0.02, 0.012);
uniform vec4 halo = vec4(0.482, 0.15, 0.115, 0.03);   // centre xy, radius xy
uniform vec3 big_eye = vec3(0.893, 0.569, 0.055);      // centre, radius (height units)
uniform vec3 small_eye = vec3(0.149, 0.7375, 0.02);
uniform vec4 glow_color : source_color = vec4(0.45, 0.85, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.75, 0.9, 1.0, 1.0);
varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;
}

float hash(float n) { return fract(sin(n) * 43758.5453); }

vec3 hue_rot(vec3 c, float h) {
	const vec3 k = vec3(0.57735);
	float a = h * 6.28318;
	float ca = cos(a);
	return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}

vec2 rot_about(vec2 uv, vec2 piv, float a) {
	vec2 d = (uv - piv) * vec2(aspect, 1.0);
	float c = cos(a), s = sin(a);
	d = vec2(c * d.x - s * d.y, s * d.x + c * d.y);
	return piv + d / vec2(aspect, 1.0);
}

void fragment() {
	float t = TIME;
	vec2 uv = UV;
	// --- 1) parallax: shift by depth (3 refinement steps so near layers don't smear)
	vec2 off = tilt * strength;
	for (int i = 0; i < 3; i++) {
		float d = texture(depth_tex, uv).r;
		uv = UV - off * (d - 0.45);
	}
	float dep = texture(depth_tex, uv).r;
	float girl = smoothstep(0.62, 0.85, dep);
	// --- 2) breathing: chest rises, whole figure sways a hair
	float br = sin(t * 1.5);
	float ch = 1.0 - smoothstep(0.0, 0.12, length((uv - chest) * vec2(aspect, 1.0)));
	uv.y += br * 0.0022 * ch * girl * calm;
	uv.x = chest.x + (uv.x - chest.x) * (1.0 - br * 0.004 * ch * girl * calm);
	float er = 9.0;
	if (!generic) {
	// --- 3) head: drifts / tilts around the neck (soft ellipse mask, only the girl layer)
	vec2 hq = (uv - head_c) / head_r;
	float hm = (1.0 - smoothstep(0.75, 1.15, length(hq))) * girl;
	float ha = (sin(t * 0.7) * 0.022 + sin(t * 1.9) * 0.006) * calm + tilt.x * 0.015;
	uv = mix(uv, rot_about(uv, neck, -ha), hm);
	// --- 4) construct undulates: dark mid layers ripple like living shadow
	float mid = (1.0 - girl) * smoothstep(0.2, 0.45, dep);
	float edge = smoothstep(0.15, 0.5, abs(uv.x - 0.5) + abs(uv.y - 0.45) * 0.5);
	uv.x += sin(t * 1.3 + uv.y * 14.0) * 0.0035 * mid * edge * calm;
	uv.y += cos(t * 1.1 + uv.x * 11.0) * 0.0025 * mid * edge * calm;
	// --- 5) halo bobs
	vec2 hq2 = (uv - halo.xy) / halo.zw;
	float hb = 1.0 - smoothstep(0.9, 1.6, length(hq2));
	uv.y += sin(t * 1.2) * 0.004 * hb * calm;
	// --- 6) big construct eyeball: the pupil narrows and dilates
	vec2 eq = (uv - big_eye.xy) * vec2(aspect, 1.0);
	er = length(eq) / big_eye.z;
	float pupil = 1.0 + 0.12 * sin(t * 0.9) * calm;
	if (er < 1.0) {
		uv = big_eye.xy + (uv - big_eye.xy) * mix(pupil, 1.0, smoothstep(0.3, 1.0, er));
	}
	// --- 7) panting mouth (already open in the art: stretch it gently)
	vec2 mq = (uv - mouth) / mouth_size;
	float mm = 1.0 - smoothstep(0.6, 1.4, length(mq));
	uv.y = mix(uv.y, mouth.y + (uv.y - mouth.y) * (1.0 - 0.18 * (0.5 + 0.5 * sin(t * 3.2))), mm);
	}
	vec4 c = texture(TEXTURE, uv);
	if (!generic) {
	// --- 8) blink (random-ish every 3-6 s, sometimes double)
	float cyc = 4.3;
	float k = floor(t / cyc);
	float ph = fract(t / cyc) * cyc - hash(k) * 2.0;
	float bl = max(1.0 - abs(ph - 0.12) / 0.12, 0.0);
	if (hash(k + 7.0) > 0.7) { bl = max(bl, 1.0 - abs(ph - 0.42) / 0.12); }
	vec2 eq2 = (uv - eye) / eye_size;
	float inside = 1.0 - smoothstep(0.85, 1.1, length(eq2));
	float lid = -1.0 + 2.0 * clamp(bl, 0.0, 1.0);
	if (bl > 0.02 && inside > 0.0 && eq2.y < lid) {
		vec4 skin = texture(TEXTURE, eye + vec2(0.0, -eye_size.y * 2.8));
		c.rgb = mix(c.rgb, skin.rgb * 0.96, inside);
	}
	float lash = (1.0 - smoothstep(0.0, 0.2, abs(eq2.y - lid))) * inside * step(0.05, bl);
	c.rgb = mix(c.rgb, vec3(0.1, 0.06, 0.08), lash * 0.85);
	// --- 9) the construct's blue fire and eyes pulse with light
	float blue = smoothstep(0.12, 0.3, c.b - c.r) * smoothstep(0.45, 0.75, c.b);
	float pulse = 0.55 + 0.45 * sin(t * 2.4 + uv.y * 9.0 + uv.x * 4.0);
	c.rgb += glow_color.rgb * blue * pulse * 0.35 * calm;
	float ee = max(1.0 - smoothstep(0.4, 1.0, er), 1.0 - smoothstep(0.4, 1.0, length((uv - small_eye.xy) * vec2(aspect, 1.0)) / small_eye.z));
	c.rgb += glow_color.rgb * ee * (0.15 + 0.15 * sin(t * 3.0)) * c.a;
	}
	// --- variant look (after the rig, before the light)
	if (corrupt_on) {
		c.rgb = hue_rot(c.rgb, hue_shift) * vec3(0.8, 0.75, 0.9);
		float gg = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		c.rgb = mix(c.rgb, gg * tone, desat);
		float a_l = texture(TEXTURE, uv + vec2(-0.01, 0.0)).a;
		float a_r = texture(TEXTURE, uv + vec2(0.01, 0.0)).a;
		float a_u = texture(TEXTURE, uv + vec2(0.0, -0.01)).a;
		float edge_v = clamp(max(a_l, max(a_r, a_u)) - c.a, 0.0, 1.0);
		float pulse_v = 0.55 + 0.45 * sin(TIME * 3.0);
		c = mix(vec4(variant_glow.rgb, edge_v * pulse_v), c, c.a);
	}
	// --- 10) 3D light: shading from the depth slope, light follows the tilt
	float e = 0.006;
	float dx = texture(depth_tex, uv + vec2(e, 0.0)).r - texture(depth_tex, uv - vec2(e, 0.0)).r;
	float dy = texture(depth_tex, uv + vec2(0.0, e)).r - texture(depth_tex, uv - vec2(0.0, e)).r;
	vec2 n = vec2(dx, dy) * 6.0;
	vec2 L = normalize(vec2(-0.6, -0.8) + tilt * 0.9);
	float lit = clamp(-dot(n, L), -1.0, 1.0);
	c.rgb += rim_color.rgb * max(lit, 0.0) * 0.22 * c.a;
	c.rgb *= 1.0 + min(lit, 0.0) * 0.12;
	COLOR = c * mod_color;
}
