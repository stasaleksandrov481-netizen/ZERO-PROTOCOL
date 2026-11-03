shader_type spatial;
render_mode unshaded;
varying float height;
void vertex() { height = (MODEL_MATRIX * vec4(VERTEX,1.0)).y; }
void fragment() {
	float t = clamp((height+3.0)/3.0,0.0,1.0);
	vec3 paint = mix(vec3(0.22,0.235,0.25),vec3(0.46,0.48,0.50),t);
	if (height > -0.045) { paint = vec3(0.60,0.62,0.64); }
	ALBEDO = paint;
}
