shader_type spatial;
render_mode unshaded, cull_back;
uniform float phase = 0.0;
void fragment() {
    vec2 p = UV * vec2(20.0, 14.0);
    float curl = sin(p.x * 0.6 + sin(p.y + phase * 7.0) - phase * 5.0);
    float flames = smoothstep(-0.25, 0.8, sin(p.y - phase * 13.0 + curl * 2.0));
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 1.5);
    ALBEDO = mix(vec3(0.8, 0.035, 0.005), vec3(1.0, 0.82, 0.12), flames * 0.7 + rim * 0.3);
    EMISSION = ALBEDO * 0.5;
}
