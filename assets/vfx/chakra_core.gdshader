shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 energy_color : source_color = vec4(0.08, 0.55, 1.0, 1.0);
uniform float phase = 0.0;
void fragment() {
    vec2 p = UV * vec2(18.0, 12.0);
    float warp = sin(p.y * 1.7 + phase * 4.0) * 0.7;
    float flow = sin(p.x + p.y * 2.0 + warp - phase * 9.0);
    float cross_flow = sin(p.y * 3.0 - p.x + phase * 6.0);
    float veins = pow(max(0.0, flow * cross_flow), 3.0);
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.0);
    ALBEDO = mix(energy_color.rgb * 0.55, vec3(0.87, 0.96, 1.0), veins * 0.65 + rim * 0.35);
    EMISSION = energy_color.rgb * (0.3 + veins * 0.5);
}
