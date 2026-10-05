extends Node3D

var active: bool = false
var owner_fighter: CharacterBody3D = null
var target: Node3D = null
var direction: Vector3 = Vector3.BACK
var remaining: float = 0.0
var shape: SphereShape3D
var hit_mask: int = 16
var definition: JutsuDefinition = null
var orb: MeshInstance3D
var material: StandardMaterial3D

func _ready() -> void:
    process_physics_priority = 15
    shape = SphereShape3D.new()
    orb = MeshInstance3D.new()
    var mesh: SphereMesh = SphereMesh.new()
    mesh.radius = 0.38
    mesh.height = 0.76
    mesh.radial_segments = 10
    mesh.rings = 5
    material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    mesh.material = material
    orb.mesh = mesh
    orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(orb)
    visible = false

func launch_jutsu(source: CharacterBody3D, destination: Node3D, origin: Vector3, heading: Vector3, data: JutsuDefinition) -> void:
    owner_fighter = source
    target = destination
    definition = data
    global_position = origin
    direction = heading.normalized()
    hit_mask = 8 if source.collision_layer == 4 else 16
    shape.radius = data.hitbox_radius
    remaining = maxf(0.6, 1.4 + data.hitbox_radius * 0.35)
    var scale_value: float = clampf(data.hitbox_radius / 0.45, 0.75, 2.2)
    orb.scale = Vector3.ONE * scale_value
    var color: Color = _effect_color(data.effect, source.character_definition.energy_color)
    material.albedo_color = color
    material.emission = color
    active = true
    visible = true

func _physics_process(delta: float) -> void:
    if not active:
        return
    remaining -= delta
    if remaining <= 0.0 or not is_instance_valid(owner_fighter) or bool(owner_fighter.call("is_defeated")):
        recycle()
        return

    if is_instance_valid(target) and bool(target.call("is_targetable")):
        var aim: Vector3 = target.global_position + Vector3.UP * 0.25 - global_position
        if aim.length_squared() > 0.001:
            direction = direction.slerp(aim.normalized(), minf(delta * definition.tracking_strength, 1.0)).normalized()

    var travel: Vector3 = direction * definition.movement_speed * delta
    var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = Transform3D(Basis.IDENTITY, global_position)
    query.motion = travel
    query.collision_mask = 1 | hit_mask
    query.collide_with_areas = true
    query.collide_with_bodies = true

    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var fractions: PackedFloat32Array = space.cast_motion(query)
    var fraction: float = fractions[0] if fractions.size() == 2 else 1.0
    global_position += travel * fraction

    query.motion = Vector3.ZERO
    query.transform.origin = global_position + direction * 0.02
    for contact: Dictionary in space.intersect_shape(query, 8):
        var collider: Node = contact["collider"] as Node
        if collider is Area3D and collider.has_method("get_fighter"):
            var fighter: Node = collider.call("get_fighter")
            if fighter != owner_fighter and fighter.has_method("receive_combat_hit"):
                var dealt: float = float(fighter.call(
                    "receive_combat_hit",
                    definition.damage * float(owner_fighter.call("get_damage_multiplier")),
                    direction,
                    definition.knockback,
                    definition.launch_force,
                    definition.hitstun
                ))
                owner_fighter.call("on_attack_connected", fighter, dealt, definition.launch_force)
                recycle()
                return
        elif collider is StaticBody3D:
            recycle()
            return

    if fraction < 1.0:
        recycle()
        return

    orb.rotation.y += delta * 7.0
    orb.rotation.x += delta * 3.0

func recycle() -> void:
    active = false
    visible = false
    owner_fighter = null
    target = null
    definition = null

func _effect_color(effect: String, fallback: Color) -> Color:
    match effect:
        "shadow":
            return Color(0.16, 0.10, 0.24)
        "mind":
            return Color(0.95, 0.35, 0.75)
        "steel", "puppet", "bone":
            return Color(0.72, 0.76, 0.82)
        "insect":
            return Color(0.22, 0.18, 0.12)
        "wind":
            return Color(0.55, 0.92, 0.92)
        "sand", "earth", "oil":
            return Color(0.82, 0.62, 0.28)
        "fire":
            return Color(1.0, 0.24, 0.04)
        "snake":
            return Color(0.35, 0.72, 0.28)
        "water":
            return Color(0.10, 0.52, 0.95)
        _:
            return fallback
