extends Node
## Persisted render/VFX budgets only. Combat timing, pools and hitboxes stay identical.
const LABELS: Array[String] = ["LOW", "MED", "HIGH"]
var level: int = 1
var settings: ConfigFile = ConfigFile.new()

func _ready() -> void:
    settings.load("user://graphics.cfg")
    level = clampi(int(settings.get_value("graphics", "quality", 1)), 0, 2)
    call_deferred("apply", level, false)

func cycle() -> void:
    apply((level + 1) % 3, true)

func apply(value: int, save: bool = true) -> void:
    level = clampi(value, 0, 2)
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
    # Bilinear scaling works on the pinned Compatibility renderer; no FSR/TAA.
    get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    get_viewport().scaling_3d_scale = [0.70, 0.85, 1.0][level]
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
