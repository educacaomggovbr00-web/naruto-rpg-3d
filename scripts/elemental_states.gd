class_name ElementalStates
extends Node3D
## Bounded elemental states. Water extinguishes ordinary fire, oil fuels it,
## lightning consumes wetness for one conduction pulse; black flames stay distinct.
const DURATION: Dictionary = {"fire": 3.0, "wet": 4.0, "oil": 5.0, "shock": .45}
var states: Dictionary = {}
var sources: Dictionary = {}
var tick_clock: float = 0.0
var visuals: Array[MeshInstance3D] = []

func _ready() -> void:
    for index: int in range(4):
        var visual: MeshInstance3D = MeshInstance3D.new()
        var mesh: SphereMesh = SphereMesh.new()
        mesh.radius = .065
        mesh.height = .26
        mesh.radial_segments = 6
        mesh.rings = 3
        visual.mesh = mesh
        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.emission_enabled = true
        visual.material_override = material
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(visual)
        visuals.append(visual)
    _update_visuals()

static func apply_hit(victim: Node, attacker: Node, effect: String, blocked: bool = false) -> void:
    if blocked or not is_instance_valid(victim) or not is_instance_valid(attacker) or victim.is_defeated() or victim.invulnerable_timer > 0.0:
        return
    if effect == "black_fire":
        preload("res://scripts/black_flame_status.gd").attach(victim, attacker)
        return
    var flow: Node = victim.get_tree().root.get_node("GameFlow")
    if not flow.battle_rules_enabled or effect not in ["fire", "water", "lightning", "oil"]:
        return
    var status: ElementalStates = victim.get_node_or_null("ElementalStates") as ElementalStates
    if status == null:
        status = ElementalStates.new()
        status.name = "ElementalStates"
        victim.add_child(status)
    status.apply_element(effect, attacker)

func apply_element(effect: String, attacker: Node) -> void:
    var victim: Node = get_parent()
    match effect:
        "water":
            states.erase("fire")
            sources.erase("fire")
            states.wet = DURATION.wet
        "oil":
            states.oil = DURATION.oil
        "fire":
            if states.has("wet"):
                states.erase("wet")
                sources.erase("wet")
            else:
                states.fire = DURATION.fire
        "lightning":
            states.shock = DURATION.shock
            if states.has("wet"):
                states.erase("wet")
                sources.erase("wet")
                victim.receive_status_damage(3.0)
                victim.guard_meter = maxf(0.0, victim.guard_meter - 8.0)
    var key: String = {"water": "wet", "lightning": "shock"}.get(effect, effect)
    if states.has(key):
        sources[key] = weakref(attacker)
    _update_visuals()

func _physics_process(delta: float) -> void:
    var victim: Node = get_parent()
    if victim.is_defeated():
        queue_free()
        return
    tick_clock += delta
    if tick_clock >= .75:
        tick_clock = fmod(tick_clock, .75)
        if states.has("fire"):
            victim.receive_status_damage(2.25 if states.has("oil") else 1.5)
    for key: String in states.keys():
        var source: Node = sources[key].get_ref() if sources.has(key) else null
        states[key] = float(states[key]) - delta
        if float(states[key]) <= 0.0 or not is_instance_valid(source) or source.is_defeated():
            states.erase(key)
            sources.erase(key)
    if states.is_empty():
        queue_free()
        return
    _update_visuals()

func _update_visuals() -> void:
    var color: Color = Color("ff7226") if states.has("fire") else Color("b6edff") if states.has("shock") else Color("4aa9ff") if states.has("wet") else Color("bc913e")
    for index: int in range(visuals.size()):
        var angle: float = float(index) * TAU / 4.0 + tick_clock * 2.0
        visuals[index].position = Vector3(cos(angle) * .36, -.15 + index * .18, sin(angle) * .36)
        visuals[index].visible = not states.is_empty()
        visuals[index].material_override.albedo_color = color
        visuals[index].material_override.emission = color

func summary() -> String:
    var result: PackedStringArray = []
    for key: String in states:
        result.append({"fire":"QUEIMANDO", "wet":"MOLHADO", "oil":"ÓLEO", "shock":"CHOQUE"}[key])
    return " • ".join(result)
