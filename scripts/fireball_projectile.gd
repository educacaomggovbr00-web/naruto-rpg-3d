extends Node3D
@export var definition: ProjectileDefinition = preload("res://assets/combat/fireball_projectile.tres")
var active: bool = false
var owner_fighter: CharacterBody3D
var target: Node3D
var direction: Vector3 = Vector3.BACK
var remaining: float = 0.0
var shape: SphereShape3D
var hit_mask: int = 16
var elemental_visual: Node3D
var orb: MeshInstance3D
func _ready() -> void:
    process_physics_priority = 15
    shape = SphereShape3D.new()
    shape.radius = definition.radius
    orb = MeshInstance3D.new()
    orb.set_script(preload("res://scripts/chakra_orb.gd"))
    add_child(orb)
    orb.call("set_energy_color", Color(1.0, 0.25, 0.02))
    orb.scale = Vector3.ONE * 2.0
    orb.core_material.shader = preload("res://assets/vfx/fire_core.gdshader")
    orb.visible = false
    elemental_visual = Node3D.new()
    elemental_visual.set_script(preload("res://scripts/elemental_jutsu_visual.gd"))
    add_child(elemental_visual)
    visible = false
func launch(source: CharacterBody3D, destination: Node3D, origin: Vector3, heading: Vector3) -> void:
    owner_fighter = source
    target = destination
    global_position = origin
    direction = heading.normalized()
    hit_mask = 8 if source.collision_layer == 4 else 16
    shape.radius = definition.radius
    remaining = definition.lifetime
    elemental_visual.configure("fire",definition.radius)
    elemental_visual.heading = direction
    active = true
    visible = true
func _physics_process(delta: float) -> void:
    if not active:
        return
    remaining -= delta
    if remaining <= 0.0 or not is_instance_valid(owner_fighter) or owner_fighter.call("is_defeated"):
        recycle()
        return
    if is_instance_valid(target) and not target.call("is_defeated"):
        var aim: Vector3 = target.global_position - global_position
        if aim.length_squared() > 0.001:
            direction = direction.slerp(aim.normalized(), minf(delta * definition.tracking_strength, 1.0)).normalized()
    elemental_visual.heading = direction
    var travel: Vector3 = direction * definition.speed * delta
    var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = Transform3D(Basis.IDENTITY, global_position)
    query.motion = travel
    query.collision_mask = 1 | hit_mask
    query.collide_with_areas = true
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var fractions: PackedFloat32Array = space.cast_motion(query)
    var fraction: float = fractions[0] if fractions.size() == 2 else 1.0
    global_position += travel * fraction
    query.motion = Vector3.ZERO
    query.transform.origin = global_position + direction * 0.02
    for contact: Dictionary in space.intersect_shape(query, 8):
        var collider: Node = contact.collider
        if collider is Area3D and collider.has_method("get_fighter"):
            var fighter: Node = collider.call("get_fighter")
            if fighter != owner_fighter and fighter.has_method("receive_combat_hit"):
                var dealt: float = fighter.call("receive_combat_hit", definition.damage * float(owner_fighter.call("get_damage_multiplier")), direction, definition.knockback, definition.launch_force, definition.hitstun)
                owner_fighter.call("on_attack_connected", fighter, dealt, definition.launch_force)
                _impact()
                recycle()
                return
        elif collider is StaticBody3D:
            _impact()
            recycle()
            return
    if fraction < 1.0:
        recycle()
func _impact() -> void:
    var feedback: Node = owner_fighter.get_parent().get_node_or_null("CombatFeedback")
    if feedback != null:
        feedback.spawn_chakra_impact(global_position,Color(1,.25,.02))

func recycle() -> void:
    active = false
    visible = false
    owner_fighter = null
    target = null
