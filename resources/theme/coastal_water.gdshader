shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float tide_y = -145.0;
uniform float clock = 0.0;
varying vec2 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+vec2(1.,1.)),f.x),f.y);
}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){
 float depth=max(0.,world_pos.y-tide_y);
 vec2 p=world_pos*vec2(.012,.065);
 float wave=noise(p+vec2(clock*.24,clock*-.13));
 float detail=noise(p*3.2+vec2(-clock*.38,clock*.12));
 float ribbons=pow(max(0.,sin(world_pos.y*.19+wave*5.+clock*1.5)),18.);
 vec2 refract_offset=vec2((wave-.5)*.009,(detail-.5)*.004);
 vec3 under=texture(screen_texture,SCREEN_UV+refract_offset).rgb;
 vec3 sea=mix(vec3(.018,.068,.102),vec3(.055,.13,.17),wave*.55+detail*.2);
 float veil=clamp(.30+depth*.0011,.30,.76);
 vec3 color=mix(under,sea,veil);
 color+=vec3(.17,.30,.35)*ribbons*.11;
 float glints=pow(detail,14.)*pow(wave,2.);
 color+=vec3(.45,.64,.70)*glints*.8;
 // Vertical, broken reflections from the coastal marker lights.
 float beam=pow(max(0.,1.-abs(sin((world_pos.x+wave*34.)*.0052))),28.);
 color+=vec3(.61,.31,.075)*beam*(.10+.18*ribbons)*exp(-depth*.0016);
 float rim=1.-smoothstep(0.,10.,depth);
 color+=vec3(.28,.45,.50)*rim*.22;
 COLOR=vec4(color,1.);
}
