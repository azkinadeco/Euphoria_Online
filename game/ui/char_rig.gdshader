shader_type canvas_item;
// Pivot rig for one full-body enemy illustration (same idea as the shop keepers' npc_rig, but
// with "bones"): every part bends around its pivot with soft skin weights, so there are no seams.
// All positions are UV (0..1) of the texture; distances are in UV-height units (x is scaled by aspect).
// Driven by game/ui/char_rig.gd — rigs live in DB.ENEMY_RIGS / DB.HERO_RIGS.
uniform float aspect = 0.7;
uniform vec2 neck = vec2(0.5, 0.25);      // head turns here
uniform vec3 head = vec3(0.5, 0.15, 0.1); // head mask: centre xy + radius
uniform vec2 hips = vec2(0.5, 0.55);      // upper body leans here
uniform vec2 chest = vec2(0.5, 0.35);     // breathing centre
uniform float chest_w = 0.12;             // breathing half-width
uniform float head_band = 1.0;            // 1 = everything above the neck near the head turns too (0 for upside-down poses)
// bones: a = pivot.xy + tip.xy; b = width, swing amplitude (rad), speed, phase. width 0 = unused.
// The weight grows from 0 at the pivot to 1 at the tip, and the swing lags along the bone,
// so hair, tails, tentacles and sleeves wave instead of turning stiffly.
uniform vec4 bone_a[10];
uniform vec4 bone_b[10];
uniform float bone_wave = 1.1;            // phase lag along a bone (0 = stiff)
// floaters (small spirits, slimes, orbs): xy centre, z radius, w bob height (UV); z = 0 unused
uniform vec4 floats[6];
// glows / heat shimmer: xy centre, z radius (0 = unused)
uniform vec3 glows[6];
uniform vec4 glow_color : source_color = vec4(0.6, 0.4, 1.0, 1.0);
// eyes (blink): centre xy (UV), half-width / half-height (UV-height units, i.e. x scaled by aspect);
// eye_rot = tilt of each eye's corner-to-corner axis (radians). eye_on = 0 disables blinking.
uniform vec4 eye0 = vec4(0.45, 0.15, 0.02, 0.01);
uniform vec4 eye1 = vec4(0.55, 0.15, 0.02, 0.01);
uniform vec2 eye_rot = vec2(0.0, 0.0);
uniform float eye_on = 0.0;
uniform float lash = 0.38;        // thickness of the upper lash line (in eye half-heights)
uniform float lid_close = 0.7;    // where the closed lash line rests (0 = eye centre, 1 = lower rim)
uniform float cheek = 2.1;        // lid skin colour is sampled this far below the eye centre (half-heights)
// animated values
uniform float t = 0.0;
uniform float calm = 1.0;
uniform float head_angle = 0.0;
uniform float body_angle = 0.0;
uniform float breath = 0.0;      // -1..1
uniform float bob = 0.0;         // whole-figure vertical offset (UV)
uniform float blink = 0.0;       // 0..1
uniform float jolt = 0.0;        // tap impulse: every bone swings harder for a moment
uniform float flash = 0.0;
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

// distance from p to segment ab (in aspect-corrected space) and the 0..1 position along it
vec2 seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = (p - a) * vec2(aspect, 1.0);
	vec2 ba = (b - a) * vec2(aspect, 1.0);
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
	return vec2(length(pa - ba * h), h);
}

// Eyelid skin tone: several samples under (and one above) the eye; keep the most skin-like
// (warm, bright, opaque) so a hair strand or shadow next to the face is never picked.
vec3 lid_skin(sampler2D tex, vec2 c, vec2 ex, vec2 ey, vec2 to_uv) {
	// 1) the most skin-like sample (warm, bright, opaque)  2) average of the samples close to it
	vec2 offs[8] = vec2[](vec2(0.0, 1.0), vec2(-0.35, 1.0), vec2(0.35, 1.0), vec2(0.0, 1.5),
			vec2(-0.25, 0.7), vec2(0.0, -1.0), vec2(-0.4, -1.0), vec2(0.4, -1.0));
	vec4 smp[8];
	vec3 best = vec3(0.93, 0.78, 0.7);
	float bs = -10.0;
	for (int k = 0; k < 8; k++) {
		vec2 o = offs[k];
		float dd = o.y > 0.0 ? cheek : 0.8 + cheek * 0.5;
		smp[k] = texture(tex, c + (ex * o.x + ey * sign(o.y) * (abs(o.y) + dd)) * to_uv);
		float l = dot(smp[k].rgb, vec3(0.3, 0.55, 0.15));
		float sc = (smp[k].r - smp[k].b) * 2.0 + l - (1.0 - smp[k].a) * 3.0 - step(0.97, l);
		if (sc > bs) { bs = sc; best = smp[k].rgb; }
	}
	vec3 sum = vec3(0.0);
	float ws = 0.0;
	for (int k = 0; k < 8; k++) {
		float wgt = (1.0 - smoothstep(0.06, 0.16, length(smp[k].rgb - best))) * smp[k].a;
		sum += smp[k].rgb * wgt;
		ws += wgt;
	}
	return ws > 0.01 ? sum / ws : best;
}

void fragment() {
	vec2 uv = UV;
	uv.y += bob;
	// 1) upper body leans around the hips (soft band above the waist)
	float upper = 1.0 - smoothstep(hips.y - 0.08, hips.y + 0.05, uv.y);
	uv = mix(uv, rot_about(uv, hips, -body_angle), upper);
	// 2) head turns around the neck (round mask around the head, fading into the neck)
	vec2 hd = (uv - head.xy) * vec2(aspect, 1.0);
	float hm = 1.0 - smoothstep(head.z * 0.85, head.z * 1.25, length(hd));
	hm = max(hm, head_band * (1.0 - smoothstep(neck.y - 0.02, neck.y + 0.015, uv.y)) * (1.0 - smoothstep(head.z * 1.1, head.z * 1.6, abs(uv.x - head.x) * aspect)));
	uv = mix(uv, rot_about(uv, neck, -head_angle), hm);
	// 3) bones (hair, arms, tails, tentacles, wings...)
	for (int i = 0; i < 10; i++) {
		float w = bone_b[i].x;
		if (w > 0.0) {
			vec2 sh = seg(uv, bone_a[i].xy, bone_a[i].zw);
			float m = (1.0 - smoothstep(w * 0.55, w, sh.x)) * smoothstep(0.0, 0.85, sh.y);
			if (m > 0.0) {
				float amp = bone_b[i].y * (calm + jolt * 1.0);
				float a = amp * sin(t * bone_b[i].z + bone_b[i].w - sh.y * bone_wave);
				uv = mix(uv, rot_about(uv, bone_a[i].xy, -a), m);
			}
		}
	}
	// floaters bob up and down (each on its own rhythm)
	for (int i = 0; i < 6; i++) {
		if (floats[i].z > 0.0) {
			float fm = 1.0 - smoothstep(floats[i].z * 0.6, floats[i].z, length((uv - floats[i].xy) * vec2(aspect, 1.0)));
			uv.y += sin(t * (1.1 + float(i) * 0.17) + float(i) * 1.9) * floats[i].w * fm * calm;
			uv.x += cos(t * (0.7 + float(i) * 0.11) + float(i)) * floats[i].w * 0.4 * fm * calm;
		}
	}
	// 4) breathing: chest widens and lifts a little
	float cb = smoothstep(chest.y - 0.12, chest.y - 0.03, uv.y) * (1.0 - smoothstep(chest.y + 0.05, chest.y + 0.13, uv.y));
	cb *= 1.0 - smoothstep(chest_w * 0.7, chest_w * 1.3, abs(uv.x - chest.x) * aspect);
	uv.x = chest.x + (uv.x - chest.x) * (1.0 - breath * 0.008 * cb);
	uv.y += breath * 0.003 * cb;
	// 5) heat shimmer inside glows
	for (int i = 0; i < 6; i++) {
		if (glows[i].z > 0.0) {
			float gm = 1.0 - smoothstep(0.0, glows[i].z, length((uv - glows[i].xy) * vec2(aspect, 1.0)));
			uv.x += sin(t * 8.0 + uv.y * 120.0 + float(i)) * 0.002 * gm * calm;
			uv.y += sin(t * 5.0 + float(i) * 1.7) * 0.0022 * gm * calm;
		}
	}
	// 6) blink: computed after sampling (needs the cheek colour) — see below
	vec4 c = texture(TEXTURE, uv);
	// 6) blink, Live2D-style: the upper lid comes down over the eye. The real painted lash line is
	//    carried down (and deepened toward the lash colour), the lid it uncovers takes the face's
	//    skin tone with a crease and soft shading, and at full close it rests as a curved lash line.
	//    Every edge is feathered so no patch outline shows.
	if (eye_on > 0.5 && blink > 0.001) {
		for (int i = 0; i < 2; i++) {
			vec4 e = i == 0 ? eye0 : eye1;
			if (e.z <= 0.0) { continue; }
			float ang = i == 0 ? eye_rot.x : eye_rot.y;
			float ca = cos(ang), sa = sin(ang);
			vec2 d = (uv - e.xy) * vec2(aspect, 1.0);
			vec2 l = vec2(ca * d.x + sa * d.y, -sa * d.x + ca * d.y);
			vec2 q = l / e.zw;
			float ax = abs(q.x);
			if (ax > 1.15 || q.y < -1.6 || q.y > 1.4) { continue; }
			float ac = min(ax, 1.0);
			float arc = sqrt(max(0.0, 1.0 - ac * ac));
			float top = -arc;
			float lt = lash * (0.5 + 0.5 * arc);                 // lash thins toward the corners
			float rest = arc * lid_close;                         // closed line: lowest in the middle
			float edge = mix(top + lt, rest, blink);              // bottom of the moving lash
			if (q.y < top - 0.22 || q.y > edge + 0.25) { continue; }
			vec2 to_uv = vec2(1.0) / vec2(aspect, 1.0);
			vec2 ex = vec2(ca, sa) * e.z;
			vec2 ey = vec2(-sa, ca) * e.w;
			// colours
			vec3 skin = lid_skin(TEXTURE, e.xy, ex, ey, to_uv);
			vec3 lashc = min(texture(TEXTURE, e.xy + ey * (-1.0 + lt * 0.5) * to_uv).rgb,
					texture(TEXTURE, e.xy + (ex * 0.4 + ey * (-0.92 + lt * 0.5)) * to_uv).rgb);
			lashc = min(lashc, vec3(0.32, 0.22, 0.24));
			vec3 col;
			float w;
			if (q.y >= edge - lt) {
				// the lash line, carried down from its painted band
				float f = clamp((q.y - (edge - lt)) / max(lt, 0.001), 0.0, 1.0);
				vec3 painted = texture(TEXTURE, e.xy + (ex * q.x + ey * (top + f * lt)) * to_uv).rgb;
				col = mix(painted, lashc, 0.35 + 0.4 * blink);
				w = 1.0 - smoothstep(edge - 0.02, edge + 0.08, q.y);
			} else {
				// the lid: skin, blending into the real skin above near the top; crease + shading
				float k = clamp((q.y - top) / max(edge - lt - top, 0.001), 0.0, 1.0);
				// the real eyelid skin between lash and brow, stretched down (keeps eyeshadow & shading);
				// where a hair strand / brow is there instead, fall back to the flat skin tone
				vec3 up = texture(TEXTURE, e.xy + (ex * q.x + ey * (top - 0.3 - (1.0 - k) * 0.5)) * to_uv).rgb;
				float lsk = dot(skin, vec3(0.3, 0.55, 0.15));
				float lup = dot(up, vec3(0.3, 0.55, 0.15));
				float upok = smoothstep(-0.01, 0.05, up.r - up.b) * (1.0 - smoothstep(0.2, 0.36, length(up - skin)))
						* smoothstep(lsk - 0.2, lsk - 0.08, lup);      // never a dark brow / lash stroke
				vec3 base = mix(skin, up, upok);
				float crease = exp(-pow((k - 0.18) * 7.0, 2.0)) * 0.1 * blink;
				float shade = mix(1.0, 0.88, smoothstep(0.45, 1.0, k));
				col = base * (shade - crease);
				w = smoothstep(top - 0.28, top + 0.1, q.y);
			}
			w *= 1.0 - smoothstep(0.86, 1.12, ax);
			c.rgb = mix(c.rgb, col, clamp(w, 0.0, 1.0));
			// soft shadow the lid casts just below the lash
			float below = (1.0 - smoothstep(edge, edge + 0.25, q.y)) * step(edge, q.y);
			c.rgb *= 1.0 - below * 0.22 * blink * (1.0 - smoothstep(0.8, 1.1, ax));
		}
	}
	for (int i = 0; i < 6; i++) {
		if (glows[i].z > 0.0) {
			float d = length((UV - glows[i].xy) * vec2(aspect, 1.0)) / glows[i].z;
			float flick = 0.55 + 0.25 * sin(t * 6.0 + float(i) * 2.3) + 0.2 * sin(t * 11.0 + float(i));
			c.rgb += glow_color.rgb * (1.0 - smoothstep(0.0, 1.0, d)) * flick * 0.32 * c.a;
		}
	}
	c.rgb += vec3(flash) * c.a;
	COLOR = c * mod_color;
}
