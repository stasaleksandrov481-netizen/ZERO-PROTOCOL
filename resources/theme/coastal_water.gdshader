shader_type canvas_item;
render_mode unshaded;
// Strict side-view 2D water: a cross-section, without perspective or screen refraction.
uniform float tide_y = -145.0;
uniform float clock = 0.0;
varying vec2 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
 float depth = max(0.0,world_pos.y-tide_y);
 vec3 water = mix(vec3(.045,.125,.166),vec3(.012,.038,.060),clamp(depth/260.0,0.0,1.0));
 float current = pow(max(0.0,sin(world_pos.x*.018+world_pos.y*.11-clock*.7)),24.0);
 water += vec3(.035,.063,.072)*current*exp(-depth*.012);
 water += vec3(.12,.22,.25)*(1.0-smoothstep(0.0,9.0,depth));
 COLOR = vec4(water,mix(.78,.97,clamp(depth/200.0,0.0,1.0)));
}
