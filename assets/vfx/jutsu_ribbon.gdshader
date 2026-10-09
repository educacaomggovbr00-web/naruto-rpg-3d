shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec4 energy_color : source_color = vec4(1.0,0.3,0.03,1.0);
uniform float phase = 0.0;
uniform float width = 0.4;
uniform float length_scale = 2.0;
uniform float rise = 0.0;
uniform float seed = 0.0;
uniform float opacity = 0.65;
uniform bool fire_mode = false;
uniform bool dark_mode = false;
void vertex() {
    float t = UV.y;
    VERTEX.x = (UV.x*2.0-1.0)*width*(1.0-t*0.65);
    VERTEX.x += sin(t*12.0-phase*9.0+seed)*width*t*0.32;
    VERTEX.y = sin(t*8.0-phase*7.0+seed)*width*t*0.22 + rise*t*t;
    VERTEX.z = -t*length_scale;
}
void fragment() {
    float lateral = abs(UV.x*2.0-1.0);
    float flow = sin(UV.y*24.0-phase*12.0+sin(UV.x*11.0+seed)*2.0);
    float edge = 1.0-smoothstep(0.28,0.98,lateral);
    float fade = smoothstep(0.0,0.08,UV.y)*(1.0-smoothstep(0.35,1.0,UV.y));
    float streak = smoothstep(-0.4,0.85,flow);
    vec3 hot = fire_mode ? vec3(1.0,0.85,0.25) : min(energy_color.rgb+vec3(0.4),vec3(1.0));
    if (dark_mode) hot = vec3(0.3,0.08,0.42);
    ALBEDO = mix(energy_color.rgb,hot,streak*(1.0-lateral)*0.7);
    EMISSION = ALBEDO*0.2;
    ALPHA = edge*fade*opacity*(0.4+streak*0.6);
}
