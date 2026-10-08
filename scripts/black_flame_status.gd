extends Node3D
## One bounded flame status per victim. Substitution/invulnerability avoid ticks;
## no direct health writes, so KO, guard and feedback retain their contracts.
var source: WeakRef
var target: WeakRef
var remaining: float = 3.0
var tick: float = 0.75
var clock: float = 0.0
var flames: Array[MeshInstance3D] = []

func _ready() -> void:
    for i: int in range(7):
        var flame: MeshInstance3D = MeshInstance3D.new()
        var mesh: SphereMesh = SphereMesh.new()
        mesh.radius = .10
        mesh.height = .75
        mesh.radial_segments = 8
        mesh.rings = 5
        flame.mesh = mesh
        var material: ShaderMaterial = ShaderMaterial.new()
        material.shader = preload("res://assets/vfx/elemental_core.gdshader")
        material.set_shader_parameter("energy_color", Color("10091d"))
        material.set_shader_parameter("fire_mode", true)
        material.set_shader_parameter("dark_mode", true)
        flame.material_override = material
        flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(flame)
        flames.append(flame)

func _physics_process(delta: float) -> void:
    var victim: Node3D = target.get_ref() as Node3D if target != null else null
    var attacker: Node3D = source.get_ref() as Node3D if source != null else null
    if not is_instance_valid(victim) or not is_instance_valid(attacker) or victim.is_defeated() or attacker.is_defeated():
        queue_free()
        return
    remaining -= delta
    if remaining <= 0.0:
        queue_free()
        return
    clock += delta
    tick -= delta
    if tick <= 0.0:
        tick += 0.75
        victim.receive_combat_hit(2.0, Vector3.ZERO, 0.0, 0.0, 0.0)
    for i: int in range(flames.size()):
        var angle: float = i * TAU / flames.size()
        flames[i].position = Vector3(cos(angle) * 0.35, 0.3, sin(angle) * 0.35)
        flames[i].material_override.set_shader_parameter("phase",clock + i*.3)
        flames[i].scale.y = 0.7 + sin(clock * 12 + i) * 0.3

static func attach(victim: Node3D, attacker: Node3D) -> void:
    if victim.has_node("BlackFlames"):
        return
    var status: Node3D = Node3D.new()
    status.set_script(load("res://scripts/black_flame_status.gd"))
    status.name = "BlackFlames"
    status.source = weakref(attacker)
    status.target = weakref(victim)
    victim.add_child(status)
