shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
 vec4 texel = texture(TEXTURE, UV);
 float coverage = smoothstep(0.72, 0.92, texel.a);
 COLOR = vec4(texel.rgb * tint.rgb, coverage * tint.a);
}
