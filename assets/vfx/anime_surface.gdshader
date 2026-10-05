shader_type spatial;
render_mode specular_disabled, cull_disabled;

// Mobile-friendly anime lighting. Vertex colors keep the procedural village
// varied without extra textures or materials.
uniform vec4 base_color : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform vec4 shade_tint : source_color = vec4(0.48, 0.57, 0.74, 1.0);
uniform float shade_threshold : hint_range(-1.0, 1.0) = 0.10;
uniform float shade_softness : hint_range(0.01, 0.3) = 0.055;
uniform float fill_strength : hint_range(0.0, 0.5) = 0.10;
uniform float rim_strength : hint_range(0.0, 0.35) = 0.08;
uniform vec4 rim_color : source_color = vec4(1.0, 0.83, 0.58, 1.0);

void fragment() {
    vec3 color = base_color.rgb;
    if (use_vertex_color) {
        color *= COLOR.rgb;
    }
    ALBEDO = color;
    ROUGHNESS = 1.0;
    // Small fill only. The old large emission value was flattening the scene.
    EMISSION = color * shade_tint.rgb * fill_strength;
}

void light() {
    vec3 n = normalize(NORMAL);
    float facing = dot(n, normalize(LIGHT));
    float band = smoothstep(shade_threshold - shade_softness,
                            shade_threshold + shade_softness, facing);
    vec3 shadow_tone = shade_tint.rgb * 0.30;
    vec3 light_tone = vec3(0.82, 0.84, 0.88);
    vec3 tone = mix(shadow_tone, light_tone, band);
    DIFFUSE_LIGHT += tone * LIGHT_COLOR * ATTENUATION / PI;

    float edge = pow(1.0 - clamp(dot(n, normalize(VIEW)), 0.0, 1.0), 3.2);
    DIFFUSE_LIGHT += rim_color.rgb * edge * rim_strength * band * LIGHT_COLOR * ATTENUATION / PI;
}
