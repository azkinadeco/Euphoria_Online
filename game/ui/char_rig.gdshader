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
// eyes (blink): up to 8 (the face pair + extra eyes on tails, staffs, creatures...).
// eyes[i] = centre xy (UV), half-width / half-height (UV-height units, x scaled by aspect); z = 0 unused.
// eye_rots[i] = tilt of the corner-to-corner axis; blinks[i] = 0 open .. 1 closed (each eye its own timing).
uniform vec4 eyes[8];
uniform float eye_rots[8];
uniform float blinks[8];
uniform vec4 skins[8];            // per-eye face skin colour measured on the art around the cheek (a = 0: unknown)
uniform int eye_count = 0;
uniform vec4 skin_hint = vec4(0.0);   // rgb = face skin colour for non-human skin (a = 1 to use it)
uniform vec4 blush = vec4(0.0);       // blushing face: rgb = blush colour, a = strength; the closed lid runs from skin (top) into it (bottom)
uniform float lash = 0.34;        // thickness of the upper lash line (in eye half-heights)
uniform float lid_close = 0.42;   // where the closed lash line rests (0 = eye centre, 1 = lower rim)
// animated values
uniform float t = 0.0;
uniform float calm = 1.0;
uniform float head_angle = 0.0;
uniform float body_angle = 0.0;
uniform float breath = 0.0;      // -1..1
uniform float bob = 0.0;         // whole-figure vertical offset (UV)
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

// Skin around an eye, as a smooth field: 10 samples on a ring just outside the eye; the ones that
// look like skin (close to the most skin-like sample) are blended by distance to the pixel, so the
// closed lid matches the face around it on every side and no patch outline shows.
vec3 ring_skin(sampler2D tex, vec2 c, vec2 ex, vec2 ey, vec2 to_uv, vec2 q, vec4 measured) {
	vec4 smp[10];
	vec2 pos[10];
	vec3 best = vec3(0.93, 0.78, 0.7);
	float bs = -10.0;
	// the cheek under the eye is the face's own skin tone: the ring sample closest to it wins
	// (so light hair next to a shadowed face, or a white fringe on blue skin, is never taken for skin)
	vec4 ck0 = texture(tex, c + (ey * 3.2 + ex * 0.2) * to_uv);
	vec4 ck1 = texture(tex, c + (ey * 2.6 - ex * 0.3) * to_uv);
	vec4 ck2 = texture(tex, c + (ey * 3.8 + ex * 0.6) * to_uv);
	float d01 = length(ck0.rgb - ck1.rgb), d02 = length(ck0.rgb - ck2.rgb), d12 = length(ck1.rgb - ck2.rgb);
	vec3 cheek = d01 + d02 <= d01 + d12 && d01 + d02 <= d02 + d12 ? ck0.rgb : (d01 + d12 <= d02 + d12 ? ck1.rgb : ck2.rgb);
	vec3 hint = skin_hint.a > 0.5 ? skin_hint.rgb : (measured.a > 0.5 ? measured.rgb : cheek);
	for (int k = 0; k < 10; k++) {
		float th = float(k) * 0.6283;
		vec2 o = vec2(cos(th) * 1.35, sin(th) * (sin(th) < 0.0 ? 2.3 : 1.9));
		pos[k] = o;
		smp[k] = texture(tex, c + (ex * o.x + ey * o.y) * to_uv);
		float l = dot(smp[k].rgb, vec3(0.3, 0.55, 0.15));
		float sc = (smp[k].r - smp[k].b) * 2.0 + l - (1.0 - smp[k].a) * 3.0 - step(0.97, l) - step(l, 0.25);
		sc = sc * 0.25 - length(smp[k].rgb - hint) * 4.0;
		if (sc > bs) { bs = sc; best = smp[k].rgb; }
	}
	vec3 sum = vec3(0.0);
	float ws = 0.0;
	for (int k = 0; k < 10; k++) {
		// skin = warm and not much darker than the best sample (lashes, brows, hair and shadows drop out)
		float lk = dot(smp[k].rgb, vec3(0.3, 0.55, 0.15)) / max(dot(best, vec3(0.3, 0.55, 0.15)), 0.01);
		lk = min(lk, 2.0 - lk);   // much brighter than the face (light hair, highlights) drops out too
		float warm = 1.0 - smoothstep(0.14, 0.3, length(smp[k].rgb - hint));
		float ok = smoothstep(0.62, 0.8, lk) * warm * smp[k].a;
		vec2 dq = q - pos[k];
		float wd = 1.0 / pow(0.2 + dot(dq, dq), 2.0);
		sum += smp[k].rgb * ok * wd;
		ws += ok * wd;
	}
	vec3 res = ws > 0.0001 ? sum / ws : best;
	// a trusted tone (art hint or the CPU cheek measurement) reins in a ring that drifted onto
	// hair, glow or shadow — the lid never ends up grey, dark or tinted on a normal face
	if (skin_hint.a > 0.5 || measured.a > 0.5)
		res = mix(res, hint, smoothstep(0.06, 0.18, length(res - hint)));
	if (blush.a > 0.0)
		res = mix(res, blush.rgb, blush.a * smoothstep(-1.3, 0.7, q.y));
	return res;
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
	// the face itself never ripples: bones, floaters and heat shimmer leave it alone
	float face = 1.0 - smoothstep(head.z * 0.8, head.z * 1.15, length((uv - head.xy) * vec2(aspect, 1.0)));
	float keep = 1.0 - face;
	// 3) bones (hair, arms, tails, tentacles, wings...)
	for (int i = 0; i < 10; i++) {
		float w = bone_b[i].x;
		if (w > 0.0) {
			vec2 sh = seg(uv, bone_a[i].xy, bone_a[i].zw);
			float m = (1.0 - smoothstep(w * 0.55, w, sh.x)) * smoothstep(0.0, 0.85, sh.y) * keep;
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
			float fm = (1.0 - smoothstep(floats[i].z * 0.6, floats[i].z, length((uv - floats[i].xy) * vec2(aspect, 1.0)))) * keep;
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
			float gm = (1.0 - smoothstep(0.0, glows[i].z, length((uv - glows[i].xy) * vec2(aspect, 1.0)))) * keep;
			uv.x += sin(t * 8.0 + uv.y * 120.0 + float(i)) * 0.002 * gm * calm;
			uv.y += sin(t * 5.0 + float(i) * 1.7) * 0.0022 * gm * calm;
		}
	}
	// 6) blink: computed after sampling (needs the cheek colour) — see below
	vec4 c = texture(TEXTURE, uv);
	// 6) blink, Live2D-style: the painted upper lash slides down along the eye and rests as a curved
	//    closed line; the lid above it and (near the end) the lower lid below it become skin taken from
	//    the face all around the eye, so a closed eye has no visible patch, white or lower lashes.
	for (int i = 0; i < 8; i++) {
		if (i >= eye_count) { break; }
		vec4 e = eyes[i];
		float bk = blinks[i];
		if (e.z <= 0.0 || bk < 0.001) { continue; }
		float ang = eye_rots[i];
		float ca = cos(ang), sa = sin(ang);
		vec2 d = (uv - e.xy) * vec2(aspect, 1.0);
		vec2 l = vec2(ca * d.x + sa * d.y, -sa * d.x + ca * d.y);
		vec2 q = l / e.zw;
		float ax = abs(q.x);
		if (ax > 1.3 || q.y < -1.8 || q.y > 1.8) { continue; }
		float ac = min(ax, 1.0);
		float arc = sqrt(max(0.0, 1.0 - ac * ac));
		float top = -arc;
		float lt = lash * (0.45 + 0.55 * arc);                // lash thins toward the corners
		float rest = arc * lid_close;                          // closed line: lowest in the middle
		float edge = mix(top + lt, rest, bk);                  // bottom of the moving lash band
		float low = mix(edge, arc + 0.5, smoothstep(0.5, 0.95, bk));   // lower lid rises at the end
		if (q.y < top - 1.15 || q.y > max(edge, low) + 0.4) { continue; }
		vec2 to_uv = vec2(1.0) / vec2(aspect, 1.0);
		vec2 ex = vec2(ca, sa) * e.z;
		vec2 ey = vec2(-sa, ca) * e.w;
		vec3 skin = ring_skin(TEXTURE, e.xy, ex, ey, to_uv, q, skins[i]);
		vec3 lashc = min(texture(TEXTURE, e.xy + ey * (-1.0 + lt * 0.5) * to_uv).rgb,
				texture(TEXTURE, e.xy + (ex * 0.35 + ey * (-0.9 + lt * 0.5)) * to_uv).rgb);
		lashc = min(lashc, skin * 0.35);
		float side = 1.0 - smoothstep(0.9, 1.2, ax);          // fade out past the corners
		// outside the eye opening only lashes and skin are painted over: a hair strand crossing the
		// lid or cheek stays (light hair is neither dark like a lash nor close to the skin tone)
		float lsk = max(dot(skin, vec3(0.3, 0.55, 0.15)), 0.01);
		float sel = max(1.0 - smoothstep(0.58, 0.84, dot(c.rgb, vec3(0.3, 0.55, 0.15)) / lsk),
				1.0 - smoothstep(0.12, 0.26, length(c.rgb - skin)));
		float inside = smoothstep(top - 0.15, top + 0.05, q.y) * (1.0 - smoothstep(arc + 0.42, arc + 0.6, q.y));
		float pick = mix(sel, 1.0, inside);
		vec4 outc = c;
		if (q.y < edge - lt) {
			// upper lid (skin), a little darker toward the lash
			float k = clamp((q.y - top) / max(edge - lt - top, 0.001), 0.0, 1.0);
			vec3 col = skin * mix(1.0, 0.9, smoothstep(0.4, 1.0, k) * bk);
			// reaches above the measured top so the painted upper lash is covered too (eases in with the blink)
			float w = smoothstep(top - 0.85, top - 0.45, q.y) * side * smoothstep(0.0, 0.25, bk);
			outc.rgb = mix(c.rgb, col, w * pick);
		} else if (q.y <= edge) {
			// the lash line, carried down from its painted band
			float f = clamp((q.y - (edge - lt)) / max(lt, 0.001), 0.0, 1.0);
			vec3 painted = texture(TEXTURE, e.xy + (ex * q.x + ey * (top + f * lt)) * to_uv).rgb;
			vec3 col = mix(painted, lashc, 0.3 + 0.55 * bk);
			float wl = (1.0 - smoothstep(1.0, 1.16, ax));
			// soft upper edge of the band where it meets the lid
			col = mix(skin * 0.9, col, smoothstep(0.0, 0.35, f) * mix(1.0, 0.85, ac));
			outc.rgb = mix(c.rgb, col, wl);
		} else {
			// below the lash: skin once the lower lid has come up, plus the shadow the lid casts
			float cover = (1.0 - smoothstep(low - 0.12, low + 0.18, q.y)) * side;
			vec3 col = skin * (1.0 - 0.12 * (1.0 - smoothstep(0.0, 0.3, q.y - edge)) * bk);
			outc.rgb = mix(c.rgb, col, cover * pick);
			float sh = (1.0 - smoothstep(edge, edge + 0.22, q.y)) * (1.0 - cover) * side;
			outc.rgb *= 1.0 - sh * 0.2 * bk;
		}
		c.rgb = outc.rgb;
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
