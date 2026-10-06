shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

// Screen-space inverted-hull outline adapted from the distance-aware approach
// in albanogiovanni/godot-anime-sdf-shader (MIT). Using clip-space expansion
// keeps the border readable across models imported in meters or centimeters.
uniform vec4 outline_color : source_color = vec4(0.035, 0.045, 0.075, 1.0);
uniform float outline_width : hint_range(0.0, 0.012) = 0.0028;
uniform float distance_growth : hint_range(0.0, 1.0) = 0.35;

void vertex() {
    vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    vec2 direction = view_normal.xy;
    float direction_length = length(direction);
    if (direction_length > 0.0001) {
        direction /= direction_length;
    }

    float depth = max(-view_position.z, 0.1);
    float adaptive = mix(1.0, clamp(depth * 0.12, 0.82, 1.55), distance_growth);

    vec4 clip_position = PROJECTION_MATRIX * view_position;
    clip_position.xy += direction * outline_width * adaptive * clip_position.w;
    POSITION = clip_position;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
