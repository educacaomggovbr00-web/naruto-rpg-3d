shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float phase = 0.0;
void vertex() {
    VERTEX.x += sin(phase * 3.0 + UV.y * 2.5) * UV.y * 0.22;
}
void fragment() {
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.0);
    float flow = sin(UV.y * 25.0 - phase * 8.0) * 0.5 + 0.5;
    ALBEDO = mix(vec3(0.55, 0.02, 0.005), vec3(1.0, 0.28, 0.04), rim * 0.5 + flow * 0.25);
}
