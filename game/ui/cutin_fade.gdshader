shader_type canvas_item;
// Ultimate cut-in art: fades out towards the right edge of its frame instead of a hard clip line,
// so wide art (bows, wings) melts into the backdrop behind the skill name.
uniform float fade_from = 0.46;   // screen x (0..1) where the fade starts
uniform float fade_to = 0.58;     // screen x where the art is fully gone

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
	COLOR.a *= 1.0 - smoothstep(fade_from, fade_to, SCREEN_UV.x);
}
