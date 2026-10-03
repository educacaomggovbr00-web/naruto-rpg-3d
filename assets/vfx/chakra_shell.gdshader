shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 energy_color : source_color = vec4(0.08, 0.55, 1.0, 1.0);
uniform float phase = 0.0;
void fragment() {
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.8);
    float bands = pow(max(0.0, sin(UV.y * 35.0 + UV.x * 18.0 - phase * 12.0)), 5.0);
    ALBEDO = energy_color.rgb;
    ALPHA = min(0.65, rim * 0.4 + bands * 0.22);
}
