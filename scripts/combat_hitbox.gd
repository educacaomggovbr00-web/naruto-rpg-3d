extends Area3D

@export var active_duration: float = 0.08

var remaining_time: float = 0.0
var damage: float = 0.0
var knockback: float = 0.0
var launch_velocity: float = 0.0
var hitstun: float = 0.0
var source_fighter: Node3D = null
var already_hit: Array[Node] = []

func _ready() -> void:
    process_physics_priority = 20
    monitoring = true
    monitorable = false
    if GameFlow.battle_rules_enabled:
        collision_mask |= 1

func _physics_process(delta: float) -> void:
    if remaining_time <= 0.0:
        return

    remaining_time = maxf(remaining_time - delta, 0.0)
    _check_overlaps()

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

func deactivate() -> void:
    remaining_time = 0.0
    source_fighter = null
    already_hit.clear()

func _check_overlaps() -> void:
    if not is_instance_valid(source_fighter):
        return

    for area: Area3D in get_overlapping_areas():
        var fighter: Node = area.call("get_fighter") if area.has_method("get_fighter") else area.get_parent()
        try_hit(fighter)
    for body: Node3D in get_overlapping_bodies():
        if body not in already_hit and body.has_method("receive_scenery_hit"):
            already_hit.append(body)
            var scaled: float = damage * (source_fighter.get_damage_multiplier() if source_fighter.has_method("get_damage_multiplier") else 1.0)
            body.receive_scenery_hit(scaled)
            preload("res://scripts/arena_interactions.gd").impact(source_fighter, body.global_position, "earth", .8)

func try_hit(fighter: Node) -> void:
    if remaining_time <= 0.0 or not is_instance_valid(source_fighter) or not is_instance_valid(fighter):
        return
    var source: Node3D = source_fighter
    if fighter == source or fighter in already_hit or not fighter.has_method("receive_combat_hit"):
        return
    already_hit.append(fighter)

    var direction: Vector3 = fighter.global_position - source.global_position
    direction.y = 0.0
    if direction.length_squared() <= 0.001:
        direction = source.global_basis.z

    var was_blocked: bool = fighter.has_method("get_is_guarding") and bool(fighter.call("get_is_guarding"))
    var scaled_damage: float = damage * (float(source.call("get_damage_multiplier")) if source.has_method("get_damage_multiplier") else 1.0)
    var damage_result: Variant = fighter.call(
        "receive_combat_hit",
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

    if actual_damage > 0.001 and source.has_method("on_attack_resolved"):
        source.call("on_attack_resolved",fighter,actual_damage,launch_velocity,was_blocked)
    elif actual_damage > 0.001 and source.has_method("on_attack_connected"):
        source.call(
            "on_attack_connected",
            fighter,
            actual_damage,
            launch_velocity
        )
