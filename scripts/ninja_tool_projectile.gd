extends Node3D
## Pooled swept projectiles and physical bomb volumes; no distance-based damage.
var active: bool = false
var source: CharacterBody3D
var target: Node3D
var kind: String = "shuriken"
var heading: Vector3 = Vector3.BACK
var hit_mask: int = 16
var remaining: float = 0.0
var sweep_shape: SphereShape3D
var shuriken: Node3D
var kunai: Node3D
var bomb: MeshInstance3D
var wave: MeshInstance3D
var hit_targets: Array[Node] = []

func _ready() -> void:
    process_physics_priority = 15
    sweep_shape = SphereShape3D.new()
    sweep_shape.radius = 0.15
    shuriken = Node3D.new()
    add_child(shuriken)
    var tools: Script = preload("res://scripts/licensed_ninja_tools.gd")
    shuriken.add_child(tools.create(tools.SHURIKEN, 0.38))
    kunai = Node3D.new()
    add_child(kunai)
    kunai.add_child(tools.create(tools.KUNAI, 0.40))
    bomb = MeshInstance3D.new()
    var ball: SphereMesh = SphereMesh.new()
    ball.radius = 0.17
    ball.height = 0.34
    ball.radial_segments = 10
    ball.rings = 5
    var dark: StandardMaterial3D = StandardMaterial3D.new()
    dark.albedo_color = Color(0.08, 0.09, 0.12)
    ball.material = dark
    bomb.mesh = ball
    bomb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(bomb)
    wave = MeshInstance3D.new()
    var arc: TorusMesh = TorusMesh.new()
    arc.inner_radius = 0.32
    arc.outer_radius = 0.37
    arc.rings = 12
    arc.ring_segments = 4
    var chakra: StandardMaterial3D = StandardMaterial3D.new()
    chakra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    chakra.albedo_color = Color(1.0, 0.12, 0.03)
    arc.material = chakra
    wave.mesh = arc
    wave.rotation.x = PI * 0.5
    wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(wave)
    visible = false

func launch(fighter: CharacterBody3D, victim: Node3D, origin: Vector3, direction: Vector3, tool: String) -> void:
    source = fighter
    hit_mask = 8 if source.collision_layer == 4 else 16
    target = victim
    kind = tool
    heading = direction.normalized()
    global_position = origin
    remaining = 1.5
    hit_targets.clear()
    active = true
    visible = true
    shuriken.visible = kind == "shuriken"
    kunai.visible = kind == "kunai"
    bomb.visible = kind == "bomb"
    wave.visible = kind == "wind"
    sweep_shape.radius = 0.40 if kind == "wind" else 0.18

func _physics_process(delta: float) -> void:
    if not active:
        return
    remaining -= delta
    if remaining <= 0.0 or not is_instance_valid(source) or source.defeated:
        recycle()
        return
    if is_instance_valid(target) and bool(target.call("is_targetable")):
        var aim: Vector3 = target.global_position + Vector3.UP * 0.1 - global_position
        if aim.length_squared() > 0.001:
            heading = heading.slerp(aim.normalized(), minf(delta * 1.2, 1.0)).normalized()
    var travel: Vector3 = heading * (12.0 if kind == "bomb" else 24.0) * delta
    var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    query.shape = sweep_shape
    query.transform = Transform3D(Basis.IDENTITY, global_position)
    query.motion = travel
    query.collision_mask = 1 | hit_mask
    query.collide_with_areas = true
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var fractions: PackedFloat32Array = space.cast_motion(query)
    var fraction: float = fractions[0] if fractions.size() == 2 else 1.0
    global_position += travel * fraction
    query.motion = Vector3.ZERO
    query.transform.origin = global_position + travel.normalized() * 0.025
    var contacts: Array[Dictionary] = space.intersect_shape(query, 12)
    if not contacts.is_empty() or fraction < 1.0:
        if kind == "bomb":
            var blast: SphereShape3D = SphereShape3D.new()
            blast.radius = 1.5
            query.shape = blast
            query.collision_mask = hit_mask
            contacts = space.intersect_shape(query, 12)
            source.combat_feedback.call("spawn_impact", global_position, "bounce")
        for contact: Dictionary in contacts:
            var collider: Node = contact["collider"] as Node
            if collider is Area3D and collider.has_method("get_fighter"):
                _strike(collider.call("get_fighter"))
        recycle()
    shuriken.rotation.y += delta * 28.0
    if kind == "kunai":
        var up_hint: Vector3 = Vector3.RIGHT if absf(heading.dot(Vector3.UP)) > 0.95 else Vector3.UP
        kunai.basis = Basis.looking_at(-heading, up_hint)

func _strike(victim: Node) -> void:
    if victim == source or victim in hit_targets or not victim.has_method("receive_combat_hit"):
        return
    hit_targets.append(victim)
    var damage: float = 9.0 if kind == "bomb" else 5.0 if kind == "wind" else 3.0
    var method: String = "receive_tool_hit" if victim.has_method("receive_tool_hit") else "receive_combat_hit"
    var dealt: float = float(victim.call(method, damage * source.call("get_damage_multiplier"), heading, 6.0 if kind == "bomb" else 1.5, 2.0 if kind == "bomb" else 0.0, 0.35 if kind == "bomb" else 0.16))
    source.call("on_attack_connected", victim, dealt, 0.0)

func recycle() -> void:
    active = false
    visible = false
    source = null
    target = null
    hit_targets.clear()
