shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;
uniform vec4 energy_color : source_color = vec4(1.0,0.23,0.04,1.0);
uniform float phase = 0.0;
uniform bool fire_mode = true;
uniform bool dark_mode = false;
void vertex() {
    float ripple = sin(VERTEX.y*9.0+phase*12.0+VERTEX.x*5.0)*sin(VERTEX.z*8.0-phase*7.0);
    VERTEX *= 1.0 + ripple * 0.065;
}
void fragment() {
    float facing = max(dot(normalize(NORMAL),normalize(VIEW)),0.0);
    float edge = 1.0-facing;
    float flow = sin(UV.y*25.0+sin(UV.x*18.0+phase*3.0)*1.3-phase*8.0);
    float streak = smoothstep(0.6,0.98,flow);
    if (fire_mode) {
        float heat = clamp(pow(facing,0.65)+streak*0.18,0.0,1.0);
        vec3 outside = vec3(0.98,0.16,0.012);
        vec3 inside = vec3(1.0,0.95,0.55);
        if (dark_mode) { outside = vec3(0.25,0.025,0.35); inside = vec3(0.012,0.004,0.02); }
        ALBEDO = mix(outside,inside,heat);
        EMISSION = ALBEDO * (dark_mode ? 0.05 : 0.35);
        ALPHA = smoothstep(0.03,0.3,facing)*(dark_mode ? 0.93 : 0.9);
    } else {
        ALBEDO = mix(energy_color.rgb,vec3(0.75,0.96,1.0),streak*0.6+edge*0.25);
        EMISSION = ALBEDO*.08;
        ALPHA = .18+facing*.24+streak*.25+pow(edge,2.0)*.16;
    }
}
