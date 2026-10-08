extends Node3D
## Three reusable traps per fighter. Wire arms on floor contact; ball is swept.
var active: bool = false
var phase: String = ""
var owner_fighter: CharacterBody3D
var definition: JutsuDefinition
var remaining: float = 0.0
var hit_mask: int = 16
var wire_shape: BoxShape3D = BoxShape3D.new()
var ball_shape: SphereShape3D = SphereShape3D.new()
var ball: MeshInstance3D
var wire: Node3D
var drop_delay: float = 0.0

func _ready() -> void:
    process_physics_priority = 15
    wire = Node3D.new()
    add_child(wire)
    var metal: StandardMaterial3D = StandardMaterial3D.new()
    metal.albedo_color = Color(0.22, 0.27, 0.32)
    metal.roughness = 0.65
    var thread: MeshInstance3D = MeshInstance3D.new()
    var bar: BoxMesh = BoxMesh.new()
    bar.size = Vector3(2.4, 0.028, 0.028)
    thread.mesh = bar
    thread.material_override = metal
    thread.position.y = 0.16
    thread.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    wire.add_child(thread)
    for side: float in [-1.0, 1.0]:
        var kunai: MeshInstance3D = MeshInstance3D.new()
        var blade: PrismMesh = PrismMesh.new()
        blade.size = Vector3(0.16, 0.4, 0.06)
        kunai.mesh = blade
        kunai.material_override = metal
        kunai.position = Vector3(side * 1.2, 0.13, 0)
        kunai.rotation.z = side * 0.35
        kunai.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        wire.add_child(kunai)
    ball = MeshInstance3D.new()
    var sphere: SphereMesh = SphereMesh.new()
    sphere.radius = 0.6
    sphere.height = 1.2
    sphere.radial_segments = 12
    sphere.rings = 6
    ball.mesh = sphere
    ball.material_override = metal
    ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ball)
    var spikes: MultiMeshInstance3D = MultiMeshInstance3D.new()
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    var cone: CylinderMesh = CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 0.12
    cone.height = 0.32
    cone.radial_segments = 4
    cone.material = metal
    batch.mesh = cone
    batch.instance_count = 12
    batch.custom_aabb = AABB(Vector3.ONE * -0.9, Vector3.ONE * 1.8)
    for index: int in range(12):
        var angle: float = float(index) * TAU / 12.0
        var axis: Vector3 = Vector3(cos(angle), 0.45 if index % 2 == 0 else -0.45, sin(angle)).normalized()
        batch.set_instance_transform(index, Transform3D(Basis(Quaternion(Vector3.UP, axis)), axis * 0.68))
    spikes.multimesh = batch
    spikes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    ball.add_child(spikes)
    recycle()

func arm(source: CharacterBody3D, data: JutsuDefinition) -> bool:
    var origin: Vector3 = source.global_position + source.global_basis.z * 1.7
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var path: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(source.global_position, origin, 1)
    if not space.intersect_ray(path).is_empty():
        return false
    var floor_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin + Vector3.UP, origin - Vector3.UP * 3.0, 1)
    var floor_hit: Dictionary = space.intersect_ray(floor_query)
    if floor_hit.is_empty() or floor_hit.normal.y < 0.6:
        return false
    owner_fighter = source
    definition = data
    hit_mask = 8 if source.collision_layer == 4 else 16
    global_transform = Transform3D(Basis(Vector3.UP, source.rotation.y), floor_hit.position + Vector3.UP * 0.02)
    wire.scale.x = definition.trap_width / 2.4
    wire_shape.size = Vector3(definition.trap_width, 0.8, 0.25)
    ball_shape.radius = definition.hitbox_radius
    remaining = definition.trap_lifetime
    phase = "armed"
    active = true
    visible = true
    wire.visible = true
    ball.visible = false
    return true

func _physics_process(delta: float) -> void:
    if not active:
        return
    remaining -= delta
    if remaining <= 0.0 or not is_instance_valid(owner_fighter) or owner_fighter.call("is_defeated"):
        recycle()
        return
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    query.collide_with_areas = true
    query.collide_with_bodies = false
    query.collision_mask = hit_mask
    if phase == "armed":
        query.shape = wire_shape
        query.transform = global_transform
        query.transform.origin += Vector3.UP * 0.4
        for contact: Dictionary in space.intersect_shape(query, 8):
            var hurtbox: Node = contact.collider
            if not hurtbox.has_method("get_fighter"):
                continue
            var victim: Node3D = hurtbox.call("get_fighter")
            if victim == owner_fighter or not victim.call("is_targetable"):
                continue
            # Freeze the drop origin once triggered. Dodging can avoid the ball.
            ball.global_position = Vector3(victim.global_position.x, global_position.y + 3.5, victim.global_position.z)
            ball.visible = true
            wire.visible = false
            phase = "falling"
            drop_delay = 0.12
            return
    else:
        drop_delay -= delta
        if drop_delay > 0.0:
            return
        var travel: Vector3 = Vector3.DOWN * definition.fall_speed * delta
        query.shape = ball_shape
        query.transform = Transform3D(Basis.IDENTITY, ball.global_position)
        query.motion = travel
        query.collide_with_bodies = true
        query.collision_mask = 1 | hit_mask
        var fractions: PackedFloat32Array = space.cast_motion(query)
        var fraction: float = fractions[0] if fractions.size() == 2 else 1.0
        ball.global_position += travel * fraction
        query.motion = Vector3.ZERO
        query.transform.origin = ball.global_position + Vector3.DOWN * 0.02
        for contact: Dictionary in space.intersect_shape(query, 8):
            var collider: Node = contact.collider
            if collider is Area3D and collider.has_method("get_fighter"):
                var victim: Node = collider.call("get_fighter")
                if victim == owner_fighter:
                    continue
                var heading: Vector3 = victim.global_position - owner_fighter.global_position
                heading.y = 0.0
                var dealt: float = victim.call("receive_combat_hit", definition.damage * float(owner_fighter.call("get_damage_multiplier")), heading.normalized(), definition.knockback, definition.launch_force, definition.hitstun)
                owner_fighter.call("on_attack_connected", victim, dealt, definition.launch_force)
                _impact()
                recycle()
                return
        if fraction < 1.0:
            _impact()
            recycle()

func _impact() -> void:
    var feedback: Node = owner_fighter.get_parent().get_node_or_null("CombatFeedback")
    if feedback != null:
        feedback.spawn_elemental_impact(ball.global_position,"steel",.65,Vector3.DOWN)

func recycle() -> void:
    active = false
    phase = ""
    visible = false
    owner_fighter = null
