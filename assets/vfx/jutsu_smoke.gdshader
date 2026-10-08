shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;
uniform vec4 smoke_color : source_color = vec4(0.18,0.19,0.22,1.0);
uniform float progress = 0.0;
void vertex() {
    VERTEX *= 1.0+sin(VERTEX.x*7.0+VERTEX.y*9.0+VERTEX.z*5.0)*.06;
}
void fragment() {
    float facing = max(dot(normalize(NORMAL),normalize(VIEW)),0.0);
    ALBEDO = smoke_color.rgb*(.85+facing*.15);
    ALPHA = smoothstep(.02,.65,facing)*.3*sin(clamp(progress,0.0,1.0)*3.14159);
}
