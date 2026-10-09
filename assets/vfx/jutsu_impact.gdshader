shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;
uniform vec4 energy_color : source_color = vec4(1.0,0.3,0.03,1.0);
uniform float progress = 0.0;
uniform bool fire_mode = false;
uniform bool dark_mode = false;
void vertex() {
    float ripple = sin(VERTEX.y*13.0+progress*19.0)*sin(VERTEX.x*9.0-VERTEX.z*11.0);
    VERTEX *= 1.0 + ripple*(fire_mode ? 0.18 : 0.05);
}
void fragment() {
    float rim = pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),1.6);
    float bands = smoothstep(0.2,0.9,sin(UV.y*42.0+UV.x*19.0-progress*25.0));
    vec3 hot = fire_mode ? vec3(1.0,0.85,0.25) : vec3(0.88,0.97,1.0);
    if (dark_mode) hot = vec3(0.32,0.07,0.42);
    ALBEDO = mix(energy_color.rgb,hot,bands*0.6);
    EMISSION = ALBEDO*0.3;
    ALPHA = (rim*0.6+bands*0.25)*(1.0-smoothstep(0.1,1.0,progress));
}
