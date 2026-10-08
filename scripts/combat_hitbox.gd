extends Area3D

@export var active_duration: float = 0.08

var remaining_time: float = 0.0
var damage: float = 0.0
var knockback: float = 0.0
var launch_velocity: float = 0.0
var hitstun: float = 0.0
var source_fighter: Node3D = null
var already_hit: Array[Node] = []
var previous_transform: Transform3D = Transform3D.IDENTITY
var sweep_valid: bool = false
var shape_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
var guard_piercing: bool = false

func _ready() -> void:
    process_physics_priority = 20
    monitoring = true
    monitorable = false

func _physics_process(delta: float) -> void:
    if remaining_time <= 0.0:
        return

    _check_overlaps()
    remaining_time = maxf(remaining_time - delta, 0.0)

func activate(
    source: Node3D,
    new_damage: float,
    new_knockback: float,
    new_launch_velocity: float,
    new_hitstun: float,
    duration: float = -1.0
) -> void:
    source_fighter = source
    damage = new_damage
    knockback = new_knockback
    launch_velocity = new_launch_velocity
    hitstun = new_hitstun
    already_hit.clear()
    remaining_time = active_duration if duration <= 0.0 else duration
    previous_transform = global_transform
    sweep_valid = false

func deactivate() -> void:
    remaining_time = 0.0
    source_fighter = null
    already_hit.clear()
    sweep_valid = false

func _check_overlaps() -> void:
    if not is_instance_valid(source_fighter):
        return

    var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision == null:
        # Dynamically-created ability volumes do not always name their shape.
        for child: Node in get_children():
            if child is CollisionShape3D:
                collision = child as CollisionShape3D
                break
    if collision == null or collision.shape == null or collision.disabled:
        return
    shape_query.shape = collision.shape
    shape_query.collision_mask = collision_mask
    shape_query.collide_with_areas = true
    shape_query.collide_with_bodies = false
    var current_transform: Transform3D = collision.global_transform
    var travel: float = previous_transform.origin.distance_to(current_transform.origin)
    # Interpolate physical volumes, bounded to eight samples. Teleports never
    # create a damaging line across the arena.
    var steps: int = clampi(int(ceil(travel / 0.18)), 1, 8) if sweep_valid and travel < 4.0 else 1
    for step: int in range(1, steps + 1):
        if remaining_time <= 0.0 or not is_instance_valid(source_fighter):
            break
        shape_query.transform = previous_transform.interpolate_with(current_transform, float(step) / float(steps)) if steps > 1 else current_transform
        for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(shape_query, 16):
            var area: Area3D = hit.get("collider") as Area3D
            if is_instance_valid(area):
                var fighter: Node = area.call("get_fighter") if area.has_method("get_fighter") else area.get_parent()
                try_hit(fighter)
    previous_transform = current_transform
    sweep_valid = true

func try_hit(fighter: Node) -> void:
    if remaining_time <= 0.0 or not is_instance_valid(source_fighter) or not is_instance_valid(fighter):
        return
    var source: Node3D = source_fighter
    if fighter == source or fighter in already_hit or not fighter.has_method("receive_combat_hit"):
        return
    var wall_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        source.global_position + Vector3.UP * 0.5, fighter.global_position + Vector3.UP * 0.5, 1)
    if not get_world_3d().direct_space_state.intersect_ray(wall_query).is_empty():
        return
    already_hit.append(fighter)

    var direction: Vector3 = fighter.global_position - source.global_position
    direction.y = 0.0
    if direction.length_squared() <= 0.001:
        direction = source.global_basis.z

    var was_blocked: bool = not guard_piercing and fighter.has_method("get_is_guarding") and bool(fighter.call("get_is_guarding"))
    var scaled_damage: float = damage * (float(source.call("get_damage_multiplier")) if source.has_method("get_damage_multiplier") else 1.0)
    var techniques: Node = fighter.get_node_or_null("CombatTechniques")
    if not guard_piercing and was_blocked and techniques != null and bool(techniques.call("try_perfect_guard", source, scaled_damage)):
        if source.has_method("on_hitbox_contact"):
            source.call("on_hitbox_contact", self, fighter, 0.0, true)
        return
    var damage_result: Variant = fighter.call(
        "receive_grab_hit" if guard_piercing and fighter.has_method("receive_grab_hit") else "receive_combat_hit",
        scaled_damage,
        direction.normalized(),
        knockback,
        launch_velocity,
        hitstun
    )

    var actual_damage: float = damage
    if typeof(damage_result) == TYPE_FLOAT or typeof(damage_result) == TYPE_INT:
        actual_damage = float(damage_result)

    if source.has_method("on_hitbox_contact"):
        source.call("on_hitbox_contact", self, fighter, actual_damage, was_blocked)

    if source.has_method("on_attack_contact"):
        source.call("on_attack_contact", fighter, actual_damage)

    if actual_damage > 0.001 and source.has_method("on_attack_connected"):
        source.call(
            "on_attack_connected",
            fighter,
            actual_damage,
            launch_velocity
        )
