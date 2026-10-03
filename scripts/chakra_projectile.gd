extends Node3D

@export var definition: ProjectileDefinition = preload("res://assets/combat/demon_wind_projectile.tres")

var active: bool = false
var owner_fighter: Node3D = null
var target: Node3D = null
var direction: Vector3 = Vector3.BACK
var hit_mask: int = 16
var remaining: float = 0.0
var spin: Node3D
var shape: SphereShape3D

func _ready() -> void:
    process_physics_priority = 15
    shape = SphereShape3D.new()
    shape.radius = definition.radius
    spin = Node3D.new()
    add_child(spin)
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.15, 0.30, 0.55)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for i: int in range(4):
        var blade: MeshInstance3D = MeshInstance3D.new()
        var mesh: PrismMesh = PrismMesh.new()
        mesh.size = Vector3(0.3, 0.08, 1.0)
        mesh.material = material
        blade.mesh = mesh
        blade.rotation.y = float(i) * PI * 0.5
        blade.position = Vector3(sin(blade.rotation.y), 0, cos(blade.rotation.y)) * 0.35
        blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        spin.add_child(blade)
    visible = false

func launch(source: Node3D, destination: Node3D, origin: Vector3, heading: Vector3) -> void:
    owner_fighter = source
    hit_mask = 8 if source.collision_layer == 4 else 16
    target = destination
    global_position = origin
    direction = heading.normalized()
    remaining = definition.lifetime
    shape.radius = definition.radius
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
        var aim: Vector3 = target.global_position + Vector3.UP * 0.2 - global_position
        if aim.length_squared() > 0.001:
            direction = direction.slerp(aim.normalized(), minf(delta * definition.tracking_strength, 1.0)).normalized()
    var travel: Vector3 = direction * definition.speed * delta
    # Sweep the volume through the complete step: no tunnelling at low FPS.
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
    owner_fighter.global_position = global_position - Vector3.UP * 0.25
    query.motion = Vector3.ZERO
    query.transform.origin = global_position + travel.normalized() * 0.02
    var contacts: Array[Dictionary] = space.intersect_shape(query, 8)
    for contact: Dictionary in contacts:
        var collider: Node = contact["collider"] as Node
        if collider is Area3D and collider.has_method("get_fighter"):
            var fighter: Node = collider.call("get_fighter")
            if fighter != owner_fighter and fighter.has_method("receive_combat_hit"):
                var blocked: bool = bool(fighter.call("get_is_guarding"))
                var dealt: float = float(fighter.call("receive_combat_hit", definition.damage * float(owner_fighter.call("get_damage_multiplier")), direction, definition.knockback, definition.launch_force, definition.hitstun))
                owner_fighter.call("on_attack_connected", fighter, dealt, definition.launch_force)
                if dealt > 0.0 and not blocked:
                    owner_fighter.get_node("CombatSpecials").call("demon_confirm", fighter)
                recycle()
                return
        elif collider is StaticBody3D:
            recycle()
            return
    if fraction < 1.0:
        recycle()
    spin.rotation.y += delta * definition.spin_speed

func recycle() -> void:
    var previous_owner: Node3D = owner_fighter
    active = false
    visible = false
    owner_fighter = null
    target = null
    if is_instance_valid(previous_owner) and previous_owner.is_inside_tree():
        previous_owner.get_node("CombatSpecials").call("projectile_finished")
