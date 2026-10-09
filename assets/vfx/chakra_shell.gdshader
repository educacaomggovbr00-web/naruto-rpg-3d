shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 energy_color : source_color = vec4(0.08, 0.55, 1.0, 1.0);
uniform float phase = 0.0;
void fragment() {
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.8);
    float bands = smoothstep(0.7,0.95,sin(UV.y*42.0+UV.x*24.0-phase*14.0));
    ALBEDO = energy_color.rgb;
    ALPHA = min(0.48, rim * 0.28 + bands * 0.2);
}
