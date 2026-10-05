extends Node
## Persisted render/VFX budgets only. Combat timing, pools and hitboxes stay identical.
const LABELS: Array[String] = ["LOW", "MED", "HIGH"]
const TARGET_SCALE: Array[float] = [0.62, 0.76, 0.92]
const MIN_ADAPTIVE_SCALE: Array[float] = [0.50, 0.58, 0.70]

@export var adaptive_resolution: bool = true
var level: int = 1
var settings: ConfigFile = ConfigFile.new()
var adaptive_timer: float = 3.0
var render_scale: float = 0.76
var low_fps_streak: int = 0
var recovery_streak: int = 0
var emergency_mode: bool = false

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

    adaptive_timer = 1.0
    var fps: float = float(Engine.get_frames_per_second())
    var target: float = TARGET_SCALE[level]
    var minimum: float = MIN_ADAPTIVE_SCALE[level]
    var next_scale: float = render_scale

    if fps > 1.0 and fps < 50.0:
        next_scale = maxf(render_scale - 0.06, minimum)
    elif fps >= 57.0:
        next_scale = minf(render_scale + 0.02, target)

    if not is_equal_approx(next_scale, render_scale):
        render_scale = next_scale
        get_viewport().scaling_3d_scale = render_scale

    if fps > 1.0 and fps < 42.0 and render_scale <= minimum + 0.01:
        low_fps_streak += 1
        recovery_streak = 0
    elif fps >= 56.0:
        low_fps_streak = 0
        recovery_streak += 1
    else:
        low_fps_streak = maxi(low_fps_streak - 1, 0)
        recovery_streak = 0

    if low_fps_streak >= 3 and not emergency_mode:
        _set_emergency_mode(true)
    elif emergency_mode and recovery_streak >= 8:
        _set_emergency_mode(false)

func cycle() -> void:
    apply((level + 1) % 3, true)

func apply(value: int, save: bool = true) -> void:
    level = clampi(value, 0, 2)
    render_scale = TARGET_SCALE[level]
    adaptive_timer = 3.0
    low_fps_streak = 0
    recovery_streak = 0
    emergency_mode = false

    var fighter: CharacterBody3D = get_parent().get_node("Player")
    if fighter.specials.sphere_visual.has_method("set_quality"):
        fighter.specials.sphere_visual.call("set_quality", level)
    if fighter.awakening.has_method("set_quality"):
        fighter.awakening.call("set_quality", level)
    elif fighter.awakening.aura != null and fighter.awakening.aura.has_method("set_quality"):
        fighter.awakening.aura.call("set_quality", level)
    _apply_effect_quality(get_parent())

    var feedback: Node = get_parent().get_node("CombatFeedback")
    feedback.effect_budget = [8, 16, 28][level]
    feedback.trail_interval = [0.12, 0.09, 0.065][level]

    for i: int in range(feedback.effect_budget, feedback.flashes.size()):
        feedback.flashes[i].visible = false
        feedback.lifetimes[i] = 0.0

    feedback.pool_cursor = 0

    var sun: DirectionalLight3D = get_parent().get_node("Sun")
    sun.shadow_enabled = level > 0
    sun.directional_shadow_max_distance = 18.0 if level == 1 else 32.0

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

func _set_emergency_mode(enabled: bool) -> void:
    emergency_mode = enabled
    low_fps_streak = 0
    recovery_streak = 0

    var feedback: Node = get_parent().get_node("CombatFeedback")
    var normal_budget: int = [8, 16, 28][level]
    feedback.effect_budget = mini(normal_budget, [6, 10, 18][level])
    feedback.trail_interval = maxf([0.12, 0.09, 0.065][level], 0.12) if enabled else [0.12, 0.09, 0.065][level]

    if not enabled:
        feedback.effect_budget = normal_budget

    var sun: DirectionalLight3D = get_parent().get_node("Sun")
    sun.shadow_enabled = level > 0 and not enabled
    sun.directional_shadow_max_distance = 0.0 if enabled else (18.0 if level == 1 else 32.0)

    var presentation: Node = get_parent().get_node_or_null("ArenaPresentation")
    if presentation != null and presentation.get("environment") != null:
        var world_environment: WorldEnvironment = presentation.get("environment") as WorldEnvironment
        if world_environment != null and world_environment.environment != null:
            world_environment.environment.fog_enabled = level > 0 and not enabled

    if enabled:
        render_scale = MIN_ADAPTIVE_SCALE[level]
        get_viewport().scaling_3d_scale = render_scale

    var controls: Node = get_parent().get_node("HUD/MobileControls")
    controls.quality_label = LABELS[level] + ("*" if enabled else "")
    controls.queue_redraw()

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
