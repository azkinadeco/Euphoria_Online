shader_type canvas_item;
// Pivot-point rig for a single full-body illustration (Live2D-style deformation).
// Every body part bends around its pivot with soft masks, so there are no visible seams.
// Pivots are in UV space (0..1) of the texture; `aspect` = width / height of the texture.
uniform float aspect = 0.321;
// --- pivots (from the "Titik Tumpu" reference sheet)
uniform vec2 neck = vec2(0.53, 0.19);       // head rotates here (Pangkal Leher)
uniform vec2 hips = vec2(0.55, 0.52);       // upper body leans here (Pusat Pinggul)
uniform vec2 chest = vec2(0.55, 0.32);      // breathing centre
uniform vec2 hand = vec2(0.30, 0.36);       // hand resting on the chest
uniform vec2 eye_l = vec2(0.445, 0.111);
uniform vec2 eye_r = vec2(0.615, 0.109);
uniform vec2 eye_size = vec2(0.046, 0.0105);
uniform vec2 mouth = vec2(0.535, 0.156);
uniform vec2 mouth_size = vec2(0.024, 0.0018);  // half-width, closed half-height
uniform vec2 hair_band = vec2(0.04, 0.21);      // vertical range of hair that sways
// optional spirit flames: xy = centre (UV), z = radius (UV height units); z = 0 → unused
uniform vec3 flames[6];
uniform vec4 flame_color : source_color = vec4(0.35, 1.0, 0.55, 1.0);
uniform float flame_time = 0.0;
// --- animated values (driven from NPCPuppet)
uniform float head_angle = 0.0;     // radians
uniform float body_angle = 0.0;     // radians
uniform float breath = 0.0;         // -1..1
uniform float hand_lift = 0.0;      // -1..1
uniform float hair_phase = 0.0;
uniform float blink = 0.0;          // 0 open .. 1 closed
uniform float mouth_open = 0.0;     // 0..1
uniform float blush = 0.0;          // 0..1
uniform vec4 lip_color : source_color = vec4(0.42, 0.10, 0.12, 1.0);
varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;
}

vec2 rot_about(vec2 uv, vec2 piv, float a) {
	vec2 d = (uv - piv) * vec2(aspect, 1.0);
	float c = cos(a), s = sin(a);
	d = vec2(c * d.x - s * d.y, s * d.x + c * d.y);
	return piv + d / vec2(aspect, 1.0);
}

void fragment() {
	vec2 uv = UV;
	// 1) upper body leans around the hips (everything above the waist, soft falloff)
	float upper = 1.0 - smoothstep(hips.y - 0.06, hips.y + 0.04, uv.y);
	uv = mix(uv, rot_about(uv, hips, -body_angle), upper);
	// 2) head tilts around the neck base
	float head = 1.0 - smoothstep(neck.y - 0.03, neck.y + 0.012, uv.y);
	uv = mix(uv, rot_about(uv, neck, -head_angle), head);
	// 3) breathing: chest widens / lifts a hair
	float ch = smoothstep(chest.y - 0.12, chest.y - 0.04, uv.y) * (1.0 - smoothstep(chest.y + 0.05, chest.y + 0.12, uv.y));
	uv.x = chest.x + (uv.x - chest.x) * (1.0 - breath * 0.006 * ch);
	uv.y += breath * 0.0025 * ch;
	// 4) the hand on the chest rises and falls with the breath
	vec2 hd = (uv - hand) * vec2(aspect, 1.0);
	float hm = 1.0 - smoothstep(0.03, 0.075, length(hd));
	uv.y += hand_lift * 0.004 * hm;
	// 5) hair ends sway (sides of the head, below the ears)
	float side = smoothstep(0.08, 0.2, abs(uv.x - neck.x));
	float hb = smoothstep(hair_band.x, hair_band.x + 0.06, uv.y) * (1.0 - smoothstep(hair_band.y - 0.04, hair_band.y, uv.y));
	uv.x += (sin(hair_phase + uv.y * 30.0) * 0.003) * side * hb;
	// heat shimmer: pixels inside a flame wobble upward
	for (int i = 0; i < 6; i++) {
		if (flames[i].z > 0.0) {
			vec2 fd = (uv - flames[i].xy) * vec2(aspect, 1.0);
			float fm = 1.0 - smoothstep(0.0, flames[i].z, length(fd));
			uv.x += sin(flame_time * 9.0 + uv.y * 140.0 + float(i)) * 0.0022 * fm;
			uv.y += sin(flame_time * 6.0 + float(i) * 1.7) * 0.0025 * fm;
		}
	}
	vec4 c = texture(TEXTURE, uv);
	// flickering glow over each flame
	for (int i = 0; i < 6; i++) {
		if (flames[i].z > 0.0) {
			vec2 fd = (UV - flames[i].xy) * vec2(aspect, 1.0);
			float d = length(fd) / flames[i].z;
			float flick = 0.55 + 0.25 * sin(flame_time * 7.0 + float(i) * 2.3) + 0.2 * sin(flame_time * 13.0 + float(i));
			float g = (1.0 - smoothstep(0.0, 1.0, d)) * flick;
			c.rgb += flame_color.rgb * g * 0.35 * c.a;
		}
	}
	// 6) blink: eyelids sweep down from the top of each eye, skin-coloured, with a lash line
	for (int i = 0; i < 2; i++) {
		vec2 e = i == 0 ? eye_l : eye_r;
		vec2 q = (uv - e) / eye_size;
		float inside = 1.0 - smoothstep(0.85, 1.05, length(q));
		float lid_edge = -1.0 + 2.0 * blink;
		if (blink > 0.01 && inside > 0.0 && q.y < lid_edge) {
			vec4 skin = texture(TEXTURE, e + vec2(0.0, -eye_size.y * 2.6));
			c.rgb = mix(c.rgb, skin.rgb * 0.97, inside);
		}
		float lash = (1.0 - smoothstep(0.0, 0.18, abs(q.y - lid_edge))) * inside * step(0.05, blink);
		c.rgb = mix(c.rgb, vec3(0.08, 0.05, 0.06), lash * 0.85);
	}
	// 7) mouth opens while talking (soft dark-red ellipse between the lips)
	vec2 mq = (uv - mouth) / vec2(mouth_size.x, mouth_size.y + mouth_open * mouth_size.y * 2.6);
	float mm = (1.0 - smoothstep(0.6, 1.0, length(mq))) * step(0.02, mouth_open);
	c.rgb = mix(c.rgb, lip_color.rgb * 0.6, mm * 0.9);
	// 8) blush on the cheeks
	for (int i = 0; i < 2; i++) {
		vec2 ck = (i == 0 ? eye_l : eye_r) + vec2(0.0, 0.03);
		float bm = 1.0 - smoothstep(0.0, 0.035, length((uv - ck) * vec2(aspect * 1.6, 1.0) * vec2(1.0, 2.2)));
		c.rgb = mix(c.rgb, vec3(1.0, 0.55, 0.6), bm * blush * 0.35 * c.a);
	}
	COLOR = c * mod_color;
}
