extends CanvasLayer
var remaining: float = 1.4
var material: ShaderMaterial
func _ready() -> void:
    layer = 24
    var rect: ColorRect = ColorRect.new()
    rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    material = ShaderMaterial.new()
    var shader: Shader = Shader.new()
    shader.code = """shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength = 1.0;
void fragment() {
    vec2 uv = SCREEN_UV;
    float edge = smoothstep(0.1, 0.65, length(uv - vec2(0.5)));
    uv.x += sin(uv.y * 30.0 + TIME * 9.0) * 0.012 * strength;
    vec3 scene = texture(screen_texture, uv).rgb;
    COLOR = vec4(mix(scene, scene * vec3(0.7, 0.25, 0.7), edge * strength * 0.7), 1.0);
}"""
    material.shader = shader
    rect.material = material
    add_child(rect)
func _physics_process(delta: float) -> void:
    remaining -= delta
    material.set_shader_parameter("strength", clampf(remaining / 0.4, 0, 1))
    if remaining <= 0:
        queue_free()
static func attach(victim: Node3D) -> void:
    if victim.name != "Player" or victim.has_node("GenjutsuOverlay"):
        return
    var overlay: CanvasLayer = CanvasLayer.new()
    overlay.set_script(load("res://scripts/genjutsu_overlay.gd"))
    overlay.name = "GenjutsuOverlay"
    victim.add_child(overlay)
