shader_type canvas_item;
render_mode unshaded;

// CC0-derived lightweight manga impact overlay for Godot 4 mobile.
// Source inspiration: hailyn's "Screen-Sampled Black-and-White Manga Hit Impact"
// on GodotShaders.com. Adapted to preserve scene colour, avoid external textures,
// and only render for a few frames around strong combat impacts.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float impact : hint_range(0.0, 1.0) = 0.0;
uniform vec2 impact_center = vec2(0.5, 0.5);
uniform vec4 ink_color : source_color = vec4(0.015, 0.025, 0.045, 0.92);
uniform vec4 flash_color : source_color = vec4(1.0, 0.92, 0.70, 1.0);
uniform float zoom_strength : hint_range(0.0, 0.08) = 0.028;
uniform float line_density : hint_range(16.0, 96.0) = 58.0;
uniform float line_cut : hint_range(0.65, 0.98) = 0.86;
uniform float line_distortion : hint_range(0.0, 64.0) = 24.0;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 delta_uv = uv - impact_center;
    float aspect = SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.000001);
    vec2 radial = vec2(delta_uv.x * aspect, delta_uv.y);
    float dist = length(radial);
    float hit = smoothstep(0.0, 0.08, impact);

    vec2 sampled_uv = impact_center + delta_uv * (1.0 - zoom_strength * hit);
    vec3 base = texture(screen_texture, sampled_uv).rgb;

    float angle = atan(radial.y, radial.x);
    float wave = abs(sin(angle * line_density + dist * line_distortion - TIME * 16.0));
    float radial_mask = smoothstep(0.10, 0.24, dist) * (1.0 - smoothstep(0.58, 0.90, dist));
    float broken = step(0.24, hash21(vec2(floor(angle * 28.0), floor(dist * 22.0))));
    float speed_line = smoothstep(line_cut, 1.0, wave) * radial_mask * broken * hit;

    vec3 color = mix(base, ink_color.rgb, clamp(speed_line * ink_color.a, 0.0, 1.0));

    float center_flash = (1.0 - smoothstep(0.02, 0.24, dist)) * impact * 0.58;
    color = mix(color, flash_color.rgb, center_flash);

    float edge_vignette = smoothstep(0.42, 0.90, dist) * impact * 0.10;
    color *= 1.0 - edge_vignette;

    COLOR = vec4(color, 1.0);
}
