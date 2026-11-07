shader_type canvas_item;
// Battle chibi lighting: a rim light on the edges facing the scene's light, a soft
// shade on the opposite side and a little ambient occlusion at the feet.
// The surface "normal" comes from the alpha slope around each pixel (no depth map needed).
uniform vec4 light_col : source_color = vec4(1.0, 0.92, 0.8, 1.0);
uniform vec4 ambient : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 light_dir = vec2(-0.6, -0.8);   // where the light comes FROM (screen space)
uniform float rim = 0.55;
uniform float px = 0.012;                    // sampling radius in UV
varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;
}

float a_at(sampler2D t, vec2 uv) {
	return texture(t, uv).a;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.01) {
		vec2 g = vec2(0.0);
		float around = 0.0;
		for (int k = 1; k <= 2; k++) {
			float r = px * float(k);
			float l = a_at(TEXTURE, UV + vec2(-r, 0.0));
			float rr = a_at(TEXTURE, UV + vec2(r, 0.0));
			float u = a_at(TEXTURE, UV + vec2(0.0, -r));
			float d = a_at(TEXTURE, UV + vec2(0.0, r));
			g += vec2(rr - l, d - u) / float(k);
			around += (l + rr + u + d) * 0.25;
		}
		around *= 0.5;
		// outward normal points to where alpha drops
		vec2 n = -g;
		float edge = 1.0 - around;                      // 0 deep inside, →1 at the rim
		float facing = length(n) > 0.001 ? dot(normalize(n), normalize(light_dir)) : 0.0;
		float lit = clamp(facing, 0.0, 1.0);           // edges facing the light
		float shade = clamp(-facing, 0.0, 1.0);        // edges facing away
		c.rgb *= ambient.rgb;
		c.rgb += light_col.rgb * lit * smoothstep(0.05, 0.6, edge) * rim;
		c.rgb *= 1.0 - shade * smoothstep(0.1, 0.7, edge) * 0.28;
		c.rgb *= mix(1.0, 0.78, smoothstep(0.82, 1.0, UV.y));   // feet touch the ground
	}
	COLOR = c * mod_color;
}
