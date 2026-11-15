shader_type canvas_item;
// Studio logo intro: one soft band of light sweeps across the logo. It only brightens what is already
// bright (the chrome), so the dark backdrop stays dark.
uniform float sweep = -0.3;      // position of the band, -0.3 .. 1.3
uniform float strength = 0.9;

varying vec4 mod_color;

void vertex() {
	mod_color = COLOR;   // in a fragment shader COLOR already holds the texture: keep the plain modulate
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = UV.x + (UV.y - 0.5) * 0.35 - sweep;
	float band = 1.0 - smoothstep(0.0, 0.09, abs(d));
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb += vec3(1.0, 0.98, 1.0) * band * strength * smoothstep(0.08, 0.6, lum);
	COLOR = c * mod_color;
}
