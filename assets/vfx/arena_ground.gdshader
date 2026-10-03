shader_type spatial;
render_mode diffuse_toon, specular_disabled;
uniform vec4 soil : source_color = vec4(0.64, 0.55, 0.37, 1.0);
uniform vec4 paving : source_color = vec4(0.61, 0.63, 0.61, 1.0);
uniform bool courtyard = false;
void fragment() {
    vec2 world = (UV - vec2(0.5)) * 60.0;
    float grain = sin(world.x * 34.0 + sin(world.y * 19.0)) * sin(world.y * 27.0) * 0.017;
    float ring = 1.0 - smoothstep(0.04, 0.13, abs(length(world) - 8.5));
    float center = 1.0 - smoothstep(7.0, 12.0, length(world));
    vec3 base = courtyard ? paving.rgb : soil.rgb;
    vec2 cell = abs(fract(world * 0.50 + vec2(0.0, floor(world.y * 0.50) * 0.5)) - 0.5);
    float mortar = smoothstep(0.47, 0.495, max(cell.x, cell.y));
    base = mix(base, base * 0.77, courtyard ? mortar : 0.0);
    ALBEDO = base + grain + center * 0.025 + ring * 0.075;
    ROUGHNESS = 1.0;
    SPECULAR = 0.0;
}
