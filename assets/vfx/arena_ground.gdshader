shader_type spatial;
render_mode specular_disabled;
uniform vec4 soil : source_color = vec4(0.76, 0.67, 0.47, 1.0);
uniform vec4 paving : source_color = vec4(0.70, 0.75, 0.73, 1.0);
uniform bool courtyard = false;
void fragment() {
    vec2 world = (UV - vec2(0.5)) * 60.0;
    // Broad painted variation avoids subpixel grain shimmer on mobile.
    float grain = sin(world.x * 0.7 + sin(world.y * 0.8)) * sin(world.y * 0.6) * 0.012;
    float ring = 1.0 - smoothstep(0.04, 0.13, abs(length(world) - 8.5));
    float center = 1.0 - smoothstep(7.0, 12.0, length(world));
    vec3 base = courtyard ? paving.rgb : soil.rgb;
    vec2 cell = abs(fract(world * 0.50 + vec2(0.0, floor(world.y * 0.50) * 0.5)) - 0.5);
    float aa = max(max(fwidth(world.x), fwidth(world.y)) * 0.5, 0.006);
    float mortar = smoothstep(0.48 - aa, 0.48 + aa, max(cell.x, cell.y));
    base = mix(base, base * 0.77, courtyard ? mortar : 0.0);
    ALBEDO = base + grain + center * 0.025 + ring * 0.075;
    EMISSION = ALBEDO * vec3(0.08, 0.09, 0.12);
    ROUGHNESS = 1.0;
    SPECULAR = 0.0;
}

void light() {
    float band = smoothstep(0.0, 0.24, dot(normalize(NORMAL), normalize(LIGHT)));
    vec3 tone = mix(vec3(0.12, 0.13, 0.16), vec3(0.70), band);
    DIFFUSE_LIGHT += tone * LIGHT_COLOR * ATTENUATION / PI;
}
