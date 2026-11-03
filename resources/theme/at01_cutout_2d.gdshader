shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
uniform bool hide_head = false;
void vertex() { tint = COLOR; }
void fragment() {
 vec4 texel = texture(TEXTURE, UV);
 if (hide_head && UV.x > 263.0/1536.0 && UV.x < 471.0/1536.0 && UV.y > 105.0/1024.0 && UV.y < 259.0/1024.0) { texel.a = 0.0; }
 float coverage = smoothstep(0.72, 0.92, texel.a);
 COLOR = vec4(texel.rgb * tint.rgb, coverage * tint.a);
}
