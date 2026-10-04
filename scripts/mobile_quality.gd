extends Node
## Persisted render/VFX budgets only. Combat timing, pools and hitboxes stay identical.
const LABELS: Array[String] = ["LOW", "MED", "HIGH"]
const TARGET_SCALE: Array[float] = [0.70, 0.85, 1.0]
const MIN_ADAPTIVE_SCALE: Array[float] = [0.58, 0.68, 0.78]

@export var adaptive_resolution: bool = true
var level: int = 1
var settings: ConfigFile = ConfigFile.new()
var adaptive_timer: float = 4.0
var render_scale: float = 0.85

func _ready() -> void:
    settings.load("user://graphics.cfg")
    level = clampi(int(settings.get_value("graphics", "quality", 1)), 0, 2)
    set_process(_is_mobile_runtime() and adaptive_resolution)
    call_deferred("apply", level, false)

func _process(delta: float) -> void:
    if not adaptive_resolution or not _is_mobile_runtime():
        return
    adaptive_timer -= delta
    if adaptive_timer > 0.0:
        return
    adaptive_timer = 1.25

    var fps: float = float(Engine.get_frames_per_second())
    var target: float = TARGET_SCALE[level]
    var minimum: float = MIN_ADAPTIVE_SCALE[level]
    var next_scale: float = render_scale

    if fps > 1.0 and fps < 48.0:
        next_scale = maxf(render_scale - 0.05, minimum)
    elif fps >= 57.0:
        next_scale = minf(render_scale + 0.025, target)

    if not is_equal_approx(next_scale, render_scale):
        render_scale = next_scale
        get_viewport().scaling_3d_scale = render_scale

func cycle() -> void:
    apply((level + 1) % 3, true)

func apply(value: int, save: bool = true) -> void:
    level = clampi(value, 0, 2)
    render_scale = TARGET_SCALE[level]
    adaptive_timer = 4.0
    var fighter: CharacterBody3D = get_parent().get_node("Player")
    fighter.specials.sphere_visual.call("set_quality", level)
    fighter.awakening.aura.call("set_quality", level)
    _apply_effect_quality(get_parent())
    var feedback: Node = get_parent().get_node("CombatFeedback")
    feedback.effect_budget = [12, 24, 32][level]
    feedback.trail_interval = [0.10, 0.075, 0.06][level]
    for i: int in range(feedback.effect_budget, feedback.flashes.size()):
        feedback.flashes[i].visible = false
        feedback.lifetimes[i] = 0.0
    feedback.pool_cursor = 0
    var sun: DirectionalLight3D = get_parent().get_node("Sun")
    sun.shadow_enabled = level > 0
    sun.directional_shadow_max_distance = 20.0 if level == 1 else 35.0
    # Bilinear scaling is supported by Compatibility and keeps the 2D touch HUD native.
    get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    get_viewport().scaling_3d_scale = render_scale
    var controls: Node = get_parent().get_node("HUD/MobileControls")
    controls.quality_label = LABELS[level]
    controls.queue_redraw()
    if save:
        settings.set_value("graphics", "quality", level)
        var result: Error = settings.save("user://graphics.cfg")
        if result != OK:
            push_warning("Não foi possível salvar qualidade gráfica: %s" % error_string(result))

func _apply_effect_quality(node: Node) -> void:
    if node.has_method("set_quality"):
        node.call("set_quality", level)
    for child: Node in node.get_children():
        _apply_effect_quality(child)

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )
