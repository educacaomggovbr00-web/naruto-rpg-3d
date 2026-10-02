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
    monitoring = true
    monitorable = false

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
    _check_overlaps()

func _check_overlaps() -> void:
    if not is_instance_valid(source_fighter):
        return

    for area: Area3D in get_overlapping_areas():
        var fighter: Node = area.get_parent()
        if fighter == source_fighter or fighter in already_hit:
            continue
        if not fighter.has_method("receive_combat_hit"):
            continue

        already_hit.append(fighter)

        var direction: Vector3 = fighter.global_position - source_fighter.global_position
        direction.y = 0.0
        if direction.length_squared() <= 0.001:
            direction = source_fighter.global_basis.z

        var damage_result: Variant = fighter.call(
            "receive_combat_hit",
            damage,
            direction.normalized(),
            knockback,
            launch_velocity,
            hitstun
        )

        var actual_damage: float = damage
        if typeof(damage_result) == TYPE_FLOAT or typeof(damage_result) == TYPE_INT:
            actual_damage = float(damage_result)

        if actual_damage > 0.001 and source_fighter.has_method("on_attack_connected"):
            source_fighter.call(
                "on_attack_connected",
                fighter,
                actual_damage,
                launch_velocity
            )
