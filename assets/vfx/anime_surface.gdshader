shader_type spatial;
render_mode specular_disabled, cull_disabled;

// Opaque, single-pass anime lighting for Compatibility / Android.
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform vec4 shade_tint : source_color = vec4(0.67, 0.72, 0.88, 1.0);
uniform float shade_threshold : hint_range(-1.0, 1.0) = 0.12;
uniform float shade_softness : hint_range(0.01, 0.3) = 0.055;
uniform float fill_strength : hint_range(0.0, 1.0) = 0.30;
uniform float rim_strength : hint_range(0.0, 0.5) = 0.12;
uniform vec4 rim_color : source_color = vec4(1.0, 0.91, 0.72, 1.0);

void fragment() {
    vec3 color = base_color.rgb;
    if (use_vertex_color) {
        color *= COLOR.rgb;
    }
    ALBEDO = color;
    ROUGHNESS = 1.0;
    // A colored fill keeps faces readable without flattening the lit band.
    EMISSION = color * shade_tint.rgb * fill_strength;
}

void light() {
    float facing = dot(normalize(NORMAL), normalize(LIGHT));
    float band = smoothstep(shade_threshold - shade_softness,
                           shade_threshold + shade_softness, facing);
    // ATTENUATION also contains the real shadow; do not light through walls.
    vec3 tone = mix(shade_tint.rgb * 0.18, vec3(0.70), band);
    DIFFUSE_LIGHT += tone * LIGHT_COLOR * ATTENUATION / PI;
    float edge = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
    DIFFUSE_LIGHT += rim_color.rgb * edge * rim_strength * band * LIGHT_COLOR * ATTENUATION / PI;
}
