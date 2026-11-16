shader_type canvas_item;
// Rarity-coloured text (UI.rarity_text): the glyph fill takes the rarity's border look, the dark outline
// is left as it is. mode: 1 LR rainbow, 2 GR white hologram, 3 OR cosmic black, 4 MR magenta-red.

uniform int mode = 1;
uniform float width = 120.0;
uniform float speed = 1.0;
varying vec2 lp;
varying vec4 vcol;

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void vertex() {
	lp = VERTEX;
	vcol = COLOR;
}

void fragment() {
	float a = texture(TEXTURE, UV).a * vcol.a;
	if (vcol.r + vcol.g + vcol.b < 1.5) {
		COLOR = vec4(vcol.rgb, a);      // outline / shadow pass
	} else {
		float x = lp.x / max(width, 1.0);
		float t = TIME * speed;
		vec3 c;
		if (mode == 1) {
			c = mix(hue(fract(x * 0.9 - t * 0.25)), vec3(1.0), 0.18);
		} else if (mode == 2) {
			vec3 iri = hue(fract(x * 1.5 + t * 0.15));
			c = mix(vec3(0.98, 0.99, 1.0), iri, 0.25);
			c += vec3(1.0) * pow(max(0.0, cos((x - fract(t * 0.3) * 1.6 + 0.3) * 6.2831853)), 30.0) * 0.6;
		} else if (mode == 3) {
			c = mix(vec3(0.16, 0.06, 0.3), vec3(0.62, 0.45, 1.0), 0.5 + 0.5 * sin(x * 9.0 - t * 1.6));
		} else {
			c = mix(vec3(1.0, 0.25, 0.62), vec3(1.0, 0.25, 0.2), 0.5 + 0.5 * sin(x * 7.0 - t * 1.3));
		}
		COLOR = vec4(c, a);
	}
}
