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
uniform int bone_count = 10;   // used slots: the loops stop there (same picture, less work per pixel)
uniform int float_count = 6;
uniform int glow_count = 6;
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
// painted lid (tools/make_lids.py): the eye area of this art with the eyes and upper lashes inpainted away, so a
// closed lid keeps the face's own shading, blush and hair instead of one flat skin colour
uniform sampler2D lid_tex : filter_linear, repeat_disable;
uniform vec4 lid_rect = vec4(0.0);   // UV rect of lid_tex on the art (x, y, w, h); w = 0: none
uniform float lid_slide = 1.0;   // 1 = painted lid revealed above a sliding lash line; 0 = older painted-lid blend
uniform float lid_reach = 1.0;    // how far above the measured top the lid skin reaches (lower for big eyes with hair close above)
// animated values
uniform float t = 0.0;
uniform float calm = 1.0;
uniform float head_angle = 0.0;
uniform float body_angle = 0.0;
uniform float breath = 0.0;      // -1..1
uniform float bob = 0.0;         // whole-figure vertical offset (UV)
uniform float jolt = 0.0;        // tap impulse: every bone swings harder for a moment
uniform float flash = 0.0;
// 2.5D on top of the rig (same idea as live25d.gdshader): the picture turns a few degrees toward the
// pointer, near parts slide further than far parts (depth map), a key light and an edge light follow
// the tilt, and a soft shadow sits behind the figure.
uniform vec2 tilt = vec2(0.0);                 // -1..1, from char_rig.gd (pointer or a slow idle orbit)
uniform sampler2D depth_tex : filter_linear;   // white = near (art/depth/<art>_depth.png)
uniform float depth_on = 0.0;                  // 1 when depth_tex is set
uniform float volume = 1.0;                    // strength of the light / shadow (0 = flat, as before)
uniform vec4 rim_light : source_color = vec4(1.0, 0.92, 1.0, 1.0);
varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;
}

// Cast-shadow sample weight: 0 outside the image and fading in over the last 3% before its border, so
// art that is cut off at the image edge (legs, hair, weapons) never smears into straight streaks.
float shadow_in(vec2 p) {
	float d = min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y));
	return smoothstep(0.0, 0.03, d);
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
// darkest lash colour of an eye: a few samples along the painted upper lash, never lighter than 32% of the lid
vec3 lashc_dark(sampler2D tex, vec2 c, vec2 ex, vec2 ey, vec2 to_uv, vec3 lid) {
	vec3 m = vec3(1.0);
	for (int i = 0; i < 7; i++) {
		float x = -0.6 + float(i) * 0.2;
		for (int j = 0; j < 3; j++) {
			vec3 s = texture(tex, c + (ex * x + ey * (-1.5 + float(j) * 0.35)) * to_uv).rgb;
			if (dot(s, vec3(0.3, 0.55, 0.15)) < dot(m, vec3(0.3, 0.55, 0.15))) { m = s; }
		}
	}
	return min(m, lid * 0.32);
}

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
	// 0) turn: the whole card rotates a little with the tilt (far side a touch shorter). The keystone is
	// scaled by the art's width/height so tall slim figures are not sheared, and the figure is never
	// narrowed (the old narrowing made slim heroes look squashed).
	vec2 pc = UV - vec2(0.5);
	float yaw = tilt.x * 0.07 * calm;
	float pitch = tilt.y * 0.04 * calm;
	pc.y *= 1.0 + pc.x * yaw * 0.7 * min(aspect, 1.0);
	pc.x *= 1.0 + pc.y * pitch * 0.25;
	vec2 buv = pc + vec2(0.5);
	vec2 uv = buv;
	// depth parallax (4 refinement steps): the body comes forward, wings / hair / tails stay back
	if (depth_on > 0.5) {
		vec2 off = tilt * 0.014 * calm;
		for (int i = 0; i < 4; i++) {
			float dd = texture(depth_tex, uv).r;
			uv = mix(uv, buv - off * (dd - 0.45), 0.75);
		}
	}
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
		if (i >= bone_count) { break; }
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
		if (i >= float_count) { break; }
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
		if (i >= glow_count) { break; }
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
		bool has_lid = lid_rect.z > 0.0;
		if (ax > (has_lid ? 2.6 : 1.3) || q.y < (has_lid ? -3.4 : -1.8) || q.y > (has_lid ? 2.6 : 1.8)) { continue; }
		float ac = min(ax, 1.0);
		float arc = sqrt(max(0.0, 1.0 - ac * ac));
		float top = -arc;
		float lt = lash * (0.45 + 0.55 * arc);                // lash thins toward the corners
		float rest = arc * lid_close;                          // closed line: lowest in the middle
		float edge = mix(top + lt, rest, bk);                  // bottom of the moving lash band
		float low = mix(edge, arc + 0.5, smoothstep(0.5, 0.95, bk));   // lower lid rises at the end
		if ((!has_lid && q.y < top - 1.15) || q.y > max(edge, low) + (has_lid ? 0.75 : 0.4)) { continue; }
		vec2 to_uv = vec2(1.0) / vec2(aspect, 1.0);
		vec2 ex = vec2(ca, sa) * e.z;
		vec2 ey = vec2(-sa, ca) * e.w;
		vec3 skin = ring_skin(TEXTURE, e.xy, ex, ey, to_uv, q, skins[i]);
		// skin of the lid at this pixel: the painted lid when there is one, else the measured flat tone
		vec3 lidc = skin;
		float lidw = 0.0;
		float lida = 0.0;
		if (lid_rect.z > 0.0) {
			vec2 lu = (uv - lid_rect.xy) / lid_rect.zw;
			if (lu.x > 0.0 && lu.x < 1.0 && lu.y > 0.0 && lu.y < 1.0) {
				vec4 lt4 = texture(lid_tex, lu);
				lidc = lt4.rgb;
				lida = lt4.a;
				// soft shading and blush stay; a fill that drifted to hair / lash colour goes back to skin
				// (the hue goes back to skin, the fill's own light / shadow is kept: an eye under hair stays shaded)
				lidc = mix(lidc, skin * clamp(dot(lidc, vec3(0.3, 0.55, 0.15)) / max(dot(skin, vec3(0.3, 0.55, 0.15)), 0.01), 0.88, 1.05),
						0.0 * lt4.a);
				lidw = 1.0;
			}
		}
		if (lidw > 0.5 && lid_slide > 0.5) {
			// Painted lid: the removed-eye picture (lid_tex, its alpha = where the eye and the upper lash were
			// painted out) is revealed above a lash line that slides down along the eye. The art's own lashes
			// disappear exactly where the new line takes over, so lashes never double up.
			float lw = lt * 1.1;                                   // closing lash thickness
			float sw = 1.0 - smoothstep(1.2, 1.45, ax);       // the closing line fades past the corners
			vec3 lc = lashc_dark(TEXTURE, e.xy, ex, ey, to_uv, lidc);
			vec3 outp = c.rgb;
			float on = smoothstep(0.0, 0.1, bk);
			if (q.y < edge - lw) {
				outp = mix(c.rgb, lidc, lida * on);
				// a faint shadow on the lid just above the closing line
				float sh_k = smoothstep(edge - lw - 0.9, edge - lw, q.y);
				outp *= 1.0 - 0.2 * on * sw * sh_k * sh_k;
			} else if (q.y <= edge) {
				float f = (q.y - (edge - lw)) / max(lw, 0.001);    // 0 top .. 1 bottom of the line
				float prof = smoothstep(0.0, 0.18, f) * (1.0 - smoothstep(0.82, 1.0, f));
				float thin = 0.55 + 0.45 * arc;                    // thinner toward the corners
				vec3 under = mix(c.rgb, lidc, lida * on) * (1.0 - 0.2 * on * sw);   // same shadow, no light gap
				outp = mix(under, lc, prof * thin * sw * on);
			} else {
				float cover = 1.0 - smoothstep(low + 0.05, low + 0.6, q.y);   // reaches the lower lash / rim too
				outp = mix(c.rgb, lidc, lida * cover * smoothstep(0.5, 0.92, bk));
				outp *= 1.0 - 0.14 * bk * sw * (1.0 - smoothstep(edge, edge + 0.28, q.y));
			}
			c.rgb = outp;
			continue;
		}
		vec3 lashc = min(texture(TEXTURE, e.xy + ey * (-1.0 + lt * 0.5) * to_uv).rgb,
				texture(TEXTURE, e.xy + (ex * 0.35 + ey * (-0.9 + lt * 0.5)) * to_uv).rgb);
		lashc = min(lashc, skin * 0.35);
		float side = 1.0 - smoothstep(0.9, 1.2, ax);          // fade out past the corners
		// with a painted lid the corners and the lower rim (bits of eye white past the measured opening) close too
		float side_l = 1.0 - smoothstep(1.2, 1.45, ax);
		// outside the eye opening only lashes and skin are painted over: a hair strand crossing the
		// lid or cheek stays (light hair is neither dark like a lash nor close to the skin tone)
		float lsk = max(dot(skin, vec3(0.3, 0.55, 0.15)), 0.01);
		float sel = max(1.0 - smoothstep(0.58, 0.84, dot(c.rgb, vec3(0.3, 0.55, 0.15)) / lsk),
				1.0 - smoothstep(0.12, 0.26, length(c.rgb - skin)));
		float inside = smoothstep(top - 0.15, top + 0.05, q.y) * (1.0 - smoothstep(arc + 0.42, arc + 0.6, q.y));
		float pick = mix(sel, 1.0, inside);
		float inside_l = smoothstep(top - 0.3, top, q.y) * (1.0 - smoothstep(arc + 0.62, arc + 0.85, q.y));
		vec4 outc = c;
		if (q.y < edge - lt) {
			// upper lid (skin), a little darker toward the lash
			float k = clamp((q.y - top) / max(edge - lt - top, 0.001), 0.0, 1.0);
			vec3 col = lidc * mix(1.0, mix(0.9, 0.97, lidw), smoothstep(0.4, 1.0, k) * bk);
			// reaches above the measured top so the painted upper lash is covered too (eases in with the blink).
			// A painted lid equals the art outside the removed eye, so its top edge can fade out very softly
			// (no dome-shaped outline above the closed eye).
			float w = mix(smoothstep(top - 0.85 * lid_reach, top - 0.45 * lid_reach, q.y),
					smoothstep(top - 1.1, top + 0.1, q.y), lidw) * mix(side, side_l, lidw) * smoothstep(0.0, 0.25, bk);
			outc.rgb = mix(c.rgb, col, w * mix(pick, max(pick, inside_l), lidw));
		} else if (q.y <= edge) {
			// the lash line, carried down from its painted band
			float f = clamp((q.y - (edge - lt)) / max(lt, 0.001), 0.0, 1.0);
			vec3 painted = texture(TEXTURE, e.xy + (ex * q.x + ey * (top + f * lt)) * to_uv).rgb;
			vec3 col = mix(painted, lashc, 0.3 + 0.55 * bk);
			float wl = (1.0 - smoothstep(1.0, 1.16, ax));
			// soft upper edge of the band where it meets the lid
			col = mix(lidc * 0.9, col, smoothstep(0.0, 0.35, f) * mix(1.0, 0.85, ac));
			outc.rgb = mix(c.rgb, col, wl);
		} else {
			// below the lash: skin once the lower lid has come up, plus the shadow the lid casts
			float cover = (1.0 - smoothstep(low - 0.12, mix(low + 0.18, low + 0.5, lidw), q.y)) * mix(side, side_l, lidw);
			vec3 col = lidc * (1.0 - 0.12 * (1.0 - smoothstep(0.0, 0.3, q.y - edge)) * bk);
			outc.rgb = mix(c.rgb, col, cover * mix(pick, max(pick, inside_l), lidw));
			float sh = (1.0 - smoothstep(edge, edge + 0.22, q.y)) * (1.0 - cover) * side;
			outc.rgb *= 1.0 - sh * 0.2 * bk;
		}
		c.rgb = outc.rgb;
	}
	for (int i = 0; i < 6; i++) {
		if (i >= glow_count) { break; }
		if (glows[i].z > 0.0) {
			float d = length((buv - glows[i].xy) * vec2(aspect, 1.0)) / glows[i].z;
			float flick = 0.55 + 0.25 * sin(t * 6.0 + float(i) * 2.3) + 0.2 * sin(t * 11.0 + float(i));
			c.rgb += glow_color.rgb * (1.0 - smoothstep(0.0, 1.0, d)) * flick * 0.32 * c.a;
		}
	}
	// 2.5D light. Key light from the depth slope, edge light on the silhouette side that faces the light,
	// and a soft cast shadow behind the figure (pushed away from the light).
	if (volume > 0.001) {
		vec2 L2 = normalize(vec2(-0.6, -0.8) + tilt * 0.9);
		if (depth_on > 0.5) {
			float e = 0.006;
			float dx = texture(depth_tex, uv + vec2(e, 0.0)).r - texture(depth_tex, uv - vec2(e, 0.0)).r;
			float dy = texture(depth_tex, uv + vec2(0.0, e)).r - texture(depth_tex, uv - vec2(0.0, e)).r;
			vec3 nrm = normalize(vec3(-dx * 7.0, -dy * 7.0, 1.0));
			vec3 L = normalize(vec3(L2 * 0.9, 0.75));
			float key = clamp(dot(nrm, L) - 0.64, -0.5, 0.5) * 2.0;
			c.rgb += rim_light.rgb * max(key, 0.0) * 0.2 * volume * c.a;
			c.rgb *= 1.0 + min(key, 0.0) * 0.16 * volume;
		}
		float a_lit = texture(TEXTURE, uv + L2 * 0.01).a;
		c.rgb += rim_light.rgb * clamp(c.a - a_lit, 0.0, 1.0) * 0.4 * volume;
		vec2 so = -L2 * 0.02 + vec2(0.0, 0.005);
		float sh = texture(TEXTURE, uv + so).a * shadow_in(uv + so) * 0.4
			+ texture(TEXTURE, uv + so * 1.5 + vec2(0.006, 0.0)).a * shadow_in(uv + so * 1.5 + vec2(0.006, 0.0)) * 0.2
			+ texture(TEXTURE, uv + so * 1.5 - vec2(0.006, 0.0)).a * shadow_in(uv + so * 1.5 - vec2(0.006, 0.0)) * 0.2
			+ texture(TEXTURE, uv + so * 2.0).a * shadow_in(uv + so * 2.0) * 0.2;
		float sa = sh * 0.38 * volume * (1.0 - c.a);
		c = vec4(mix(vec3(0.02, 0.0, 0.06), c.rgb, c.a / max(c.a + sa, 0.0001)), c.a + sa);
	}
	c.rgb += vec3(flash) * c.a;
	COLOR = c * mod_color;
}
