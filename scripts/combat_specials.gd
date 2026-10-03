extends Node3D

var projectiles: Array[Node3D] = []
var selected: String = "demon"
var current: String = ""
var elapsed: float = 0.0
var duration: float = 0.0
var released: bool = false
var rasengan_hitbox: Area3D
var sphere_visual: MeshInstance3D
var sphere_rings: Array[MeshInstance3D] = []
var active_opened: bool = false
var owner_fighter: CharacterBody3D

func _ready() -> void:
    owner_fighter = get_parent() as CharacterBody3D
    process_physics_priority = 15
    rasengan_hitbox = Area3D.new()
    rasengan_hitbox.set_script(preload("res://scripts/combat_hitbox.gd"))
    rasengan_hitbox.collision_layer = 0
    rasengan_hitbox.collision_mask = 16
    var collision: CollisionShape3D = CollisionShape3D.new()
    var hit_shape: SphereShape3D = SphereShape3D.new()
    hit_shape.radius = 0.55
    collision.shape = hit_shape
    rasengan_hitbox.add_child(collision)
    add_child(rasengan_hitbox)
    rasengan_hitbox.top_level = true
    sphere_visual = MeshInstance3D.new()
    var orb: SphereMesh = SphereMesh.new()
    orb.radius = 0.22
    orb.height = 0.44
    orb.radial_segments = 12
    orb.rings = 6
    var energy: StandardMaterial3D = StandardMaterial3D.new()
    energy.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    energy.albedo_color = Color(0.1, 0.6, 1.0)
    orb.material = energy
    sphere_visual.mesh = orb
    sphere_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    rasengan_hitbox.add_child(sphere_visual)
    for i: int in range(2):
        var ring: MeshInstance3D = MeshInstance3D.new()
        var torus: TorusMesh = TorusMesh.new()
        torus.inner_radius = 0.24
        torus.outer_radius = 0.27
        torus.rings = 12
        torus.ring_segments = 6
        torus.material = energy
        ring.mesh = torus
        ring.rotation.x = float(i) * PI * 0.5
        ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        sphere_visual.add_child(ring)
        sphere_rings.append(ring)
    sphere_visual.visible = false
    for i: int in range(3):
        var projectile: Node3D = Node3D.new()
        projectile.set_script(preload("res://scripts/chakra_projectile.gd"))
        owner_fighter.get_parent().add_child.call_deferred(projectile)
        projectiles.append(projectile)

func start(kind: String = "") -> bool:
    var move: String = selected if kind.is_empty() else kind
    if not current.is_empty() or owner_fighter.defeated or owner_fighter.stagger_timer > 0.0 or owner_fighter.attack_active or owner_fighter.dodge_timer > 0.0 or owner_fighter.chakra_dash_timer > 0.0 or owner_fighter.jutsu_cooldown > 0.0:
        return false
    if owner_fighter.chakra < 32.0:
        return false
    owner_fighter.chakra -= 32.0
    owner_fighter.jutsu_cooldown = 1.5
    owner_fighter.jutsu_timer = 0.65
    owner_fighter.is_guarding = false
    owner_fighter.is_charging_chakra = false
    owner_fighter.animation_action_id += 1
    current = move
    elapsed = 0.0
    duration = 0.95 if move == "rasengan" else 0.65
    owner_fighter.jutsu_timer = duration
    active_opened = false
    released = false
    return true

func _physics_process(delta: float) -> void:
    if current.is_empty():
        return
    if owner_fighter.defeated or owner_fighter.stagger_timer > 0.0 or owner_fighter.jutsu_timer <= 0.0:
        cancel()
        return
    elapsed += delta
    if current == "rasengan":
        var hand: Vector3 = owner_fighter.rig_adapter.call("get_hand_world_position")
        rasengan_hitbox.global_position = hand + owner_fighter.global_basis.z * 0.12
        sphere_visual.visible = elapsed > 0.12 and elapsed < 0.84
        sphere_visual.scale = Vector3.ONE * minf(1.0, elapsed * 5.0)
        for ring: MeshInstance3D in sphere_rings:
            ring.rotation.z += delta * 15.0
        if elapsed >= 0.38 and not active_opened:
            active_opened = true
            rasengan_hitbox.call("activate", owner_fighter, 26.0, 11.0, 4.5, 0.6, 0.30)
        if elapsed >= 0.68:
            rasengan_hitbox.call("deactivate")
    elif not released and elapsed >= 0.24:
        released = true
        for projectile: Node3D in projectiles:
            if projectile.is_inside_tree() and not projectile.active:
                projectile.call("launch", owner_fighter, owner_fighter.locked_target, owner_fighter.global_position + Vector3.UP * 0.25 + owner_fighter.global_basis.z * 0.8, owner_fighter.global_basis.z)
                break
    if elapsed >= duration:
        cancel()

func cancel() -> void:
    current = ""
    sphere_visual.visible = false
    rasengan_hitbox.call("deactivate")
    owner_fighter.jutsu_timer = 0.0

func demon_confirm(_target: Node) -> void:
    pass # Clone follow-through added after the reusable clone pool.

func _exit_tree() -> void:
    for projectile: Node3D in projectiles:
        if is_instance_valid(projectile):
            projectile.queue_free()

func movement_velocity(delta: float) -> Vector3:
    if current != "rasengan" or elapsed < 0.28 or elapsed > 0.68:
        return Vector3.ZERO
    var forward: Vector3 = owner_fighter.global_basis.z
    if is_instance_valid(owner_fighter.locked_target):
        var aim: Vector3 = owner_fighter.locked_target.global_position - owner_fighter.global_position
        aim.y = 0.0
        if aim.length() <= 1.0:
            return Vector3.ZERO
        owner_fighter.call("_face_direction", aim, delta, 7.0)
        forward = owner_fighter.global_basis.z
    return forward * 13.0
