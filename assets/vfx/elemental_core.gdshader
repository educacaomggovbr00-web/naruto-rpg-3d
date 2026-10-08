shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 energy_color : source_color = vec4(0.1,0.6,1.0,1.0);
uniform float phase = 0.0;
uniform bool grain_mode = false;
uniform bool solid_mode = false;
uniform bool fire_mode = false;
uniform bool dark_mode = false;
void vertex() {
    float ripple = sin(VERTEX.y*9.0 + phase*12.0 + VERTEX.x*5.0) * sin(VERTEX.z*8.0-phase*7.0);
    VERTEX *= 1.0 + ripple * (fire_mode ? 0.13 : 0.035);
}
void fragment() {
    float flow = sin(UV.x*34.0 + sin(UV.y*23.0+phase*6.0)*2.0 - phase*11.0);
    float streak = smoothstep(0.35,0.95,flow);
    float rim = pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),1.8);
    vec3 bright = fire_mode ? vec3(1.0,0.83,0.16) : min(energy_color.rgb+vec3(0.35),vec3(1.0));
    if (dark_mode) bright = vec3(0.36,0.08,0.55);
    ALBEDO = mix(energy_color.rgb*0.65,bright,streak*0.65+rim*0.35);
    if (grain_mode) ALBEDO = energy_color.rgb * (0.6 + step(0.0,sin(UV.x*123.0)*sin(UV.y*89.0))*0.3 + rim*0.1);
    if (solid_mode) ALBEDO = energy_color.rgb * (0.65 + rim*0.35);
    EMISSION = ALBEDO*(solid_mode || grain_mode ? 0.05 : 0.35);
}
