extends CharacterBody3D

@export var moveset: MovesetDefinition = preload("res://assets/combat/naruto_moveset.tres")
var selected_attack: AttackDefinition = null
var combo_branch: String = "neutral"

@export var max_health: float = 120.0
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var attack_range: float = 1.35
@export var detection_range: float = 18.0
@export var attack_damage: float = 10.0
@export var attack_knockback: float = 5.5
@export var attack_cooldown_time: float = 1.05
@export var guard_duration: float = 0.65
@export var recovery_delay: float = 2.5
@export var knockback_friction: float = 12.0
@export var ground_bounce_velocity: float = 6.2
@export var wall_bounce_strength: float = 0.68

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var health: float = 120.0
var targetable: bool = true
var cinematic_owner: Node = null
var cinematic_watchdog: float = 0.0
var guarding: bool = false
var spawn_position: Vector3 = Vector3.ZERO

var attack_cooldown: float = 0.0
var guard_timer: float = 0.0
var stagger_timer: float = 0.0
var dodge_timer: float = 0.0
var respawn_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var attack_cycle: int = 0
var hit_cycle: int = 0
var guard_meter: float = 100.0
var guard_regen_delay: float = 0.0
var substitutions: int = 4
var substitution_regen: float = 0.0
var substitution_cooldown: float = 0.0
var invulnerable_timer: float = 0.0
var reaction_timer: float = 0.0
var juggle_hits: int = 0
var juggle_timer: float = 0.0
@export var reactive_substitution: bool = true

@export var decision_interval_min: float = 0.18
@export var decision_interval_max: float = 0.32
var decision_timer: float = 0.20
var neutral_motion: String = "approach"
var orbit_side: float = 1.0
var decision_rng: RandomNumberGenerator = RandomNumberGenerator.new()

var locked_target: CharacterBody3D = null
var combo_step: int = 1
var animation_action_id: int = 0
var attack_confirmed: bool = false
var attack_airborne: bool = false
var attack_timing: Dictionary = {}

var attack_active: bool = false
var attack_elapsed: float = 0.0
var attack_hit_triggered: bool = false
var ground_bounce_pending: bool = false
var wall_bounce_pending: bool = false

@onready var rig_adapter: Node3D = $RiggedCharacterAdapter
@onready var visual: MeshInstance3D = $Visual
@onready var lock_label: Label3D = $LockLabel
@onready var health_label: Label3D = $HealthLabel
@onready var player: CharacterBody3D = $"../Player"
@onready var attack_hitbox: Area3D = $AttackHitbox
@onready var combat_feedback: Node = get_node_or_null("../CombatFeedback")

func _ready() -> void:
    decision_rng.randomize()
    locked_target = player
    health = max_health
    spawn_position = global_position
    _update_labels()

func _physics_process(delta: float) -> void:
    if is_instance_valid(cinematic_owner):
        cinematic_watchdog -= delta
        if cinematic_watchdog > 0.0 and targetable:
            _update_timers(delta)
            velocity = Vector3.ZERO
            return
        cinematic_owner = null
    if not is_on_floor():
        velocity.y -= gravity * delta

    _update_timers(delta)
    _update_attack_timeline(delta)

    if not targetable:
        velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
        velocity.z = move_toward(velocity.z, 0.0, knockback_friction * delta)
        _move_and_handle_bounces()

        if respawn_timer <= 0.0:
            _respawn()
        return

    if not is_instance_valid(player) or bool(player.call("is_defeated")):
        _slow_down(delta)
        _move_and_handle_bounces()
        return

    if stagger_timer > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, knockback_friction * 0.35 * delta)
        velocity.z = move_toward(velocity.z, 0.0, knockback_friction * 0.35 * delta)
        _move_and_handle_bounces()
        return

    if dodge_timer > 0.0:
        velocity.x = dodge_direction.x * 8.5
        velocity.z = dodge_direction.z * 8.5
        _move_and_handle_bounces()
        return

    var to_player: Vector3 = player.global_position - global_position
    to_player.y = 0.0
    var distance: float = to_player.length()

    if distance <= detection_range and to_player.length_squared() > 0.001:
        _face_direction(to_player, delta)

    if guard_timer > 0.0:
        guarding = true
        _slow_down(delta)
        _move_and_handle_bounces()
        return

    guarding = false

    decision_timer = maxf(decision_timer - delta, 0.0)
    if not attack_active and decision_timer <= 0.0:
        _decide_neutral(distance)

    if attack_active:
        if distance > 1.05 and attack_elapsed < float(attack_timing.get("startup", 0.12)):
            _chase_player(to_player, delta)
        else:
            _slow_down(delta)
    elif distance > detection_range:
        _slow_down(delta)
    elif neutral_motion == "retreat" and distance < 6.0:
        _chase_player(-to_player, delta)
    elif neutral_motion == "strafe" and distance > attack_range:
        _chase_player(Vector3(-to_player.z, 0.0, to_player.x) * orbit_side, delta)
    elif distance > attack_range:
        _chase_player(to_player, delta)
    else:
        _slow_down(delta)
        if attack_cooldown <= 0.0 and decision_timer <= decision_interval_min:
            _choose_close_action()

    _move_and_handle_bounces()

func _update_timers(delta: float) -> void:
    juggle_timer = maxf(juggle_timer - delta, 0.0)
    if juggle_timer <= 0.0:
        juggle_hits = 0
    invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)
    substitution_cooldown = maxf(substitution_cooldown - delta, 0.0)
    guard_regen_delay = maxf(guard_regen_delay - delta, 0.0)
    if guard_regen_delay <= 0.0 and not guarding:
        guard_meter = minf(100.0, guard_meter + delta * 20.0)
    if substitutions < 4:
        substitution_regen += delta
        if substitution_regen >= 8.0:
            substitutions += 1
            substitution_regen = 0.0
    if reaction_timer > 0.0:
        reaction_timer -= delta
        if reaction_timer <= 0.0 and stagger_timer > 0.0:
            _substitute()
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    guard_timer = maxf(guard_timer - delta, 0.0)
    stagger_timer = maxf(stagger_timer - delta, 0.0)
    dodge_timer = maxf(dodge_timer - delta, 0.0)

    if not targetable:
        respawn_timer = maxf(respawn_timer - delta, 0.0)

    if stagger_timer <= 0.0 and is_on_floor():
        wall_bounce_pending = false
        if velocity.y >= -0.1:
            ground_bounce_pending = false

func _update_attack_timeline(delta: float) -> void:
    if not attack_active:
        return

    attack_elapsed += delta

    var startup: float = float(attack_timing.get("startup", 0.12))
    var duration: float = float(attack_timing.get("duration", 0.28))
    if not attack_hit_triggered and attack_elapsed >= startup:
        attack_hit_triggered = true
        rig_adapter.call("snap_attack_hitbox", combo_step, attack_airborne)
        attack_hitbox.call("activate", self, selected_attack.damage * attack_damage / 10.0,
            selected_attack.knockback, selected_attack.launch_force, selected_attack.hitstun,
            float(attack_timing.get("active", 0.09)))

    # Continue only after an actual unblocked collision, inside the manifest window.
    var cancel_open: float = float(attack_timing.get("cancel_open", duration))
    var cancel_close: float = float(attack_timing.get("cancel_close", duration))
    if attack_confirmed and combo_step < 4 and attack_elapsed >= cancel_open and attack_elapsed <= cancel_close:
        combo_step += 1
        _begin_strike()
    elif attack_elapsed >= duration:
        attack_active = false
        attack_hitbox.call("deactivate")

func on_hitbox_contact(_hitbox: Area3D, _victim: Node, damage: float, blocked: bool) -> void:
    if attack_active and not blocked and damage > 0.0:
        attack_confirmed = true

func get_animation_state() -> String:
    if not targetable:
        return "defeat"
    if stagger_timer > 0.0:
        return "knockback" if velocity.length() > 6.0 and guard_meter > 0.0 else "hit"
    if dodge_timer > 0.0:
        return "dodge"
    if guarding:
        return "guard"
    if attack_active:
        return "air_attack" if attack_airborne else "attack"
    if not is_on_floor():
        return "air"
    return "run" if Vector2(velocity.x, velocity.z).length() > 0.2 else "idle"

func get_attack_animation() -> String:
    return selected_attack.animation_name if selected_attack != null else "attack_1"

func get_combo_step() -> int:
    return combo_step

func get_animation_action_id() -> int:
    return animation_action_id

func _slow_down(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
    velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

func _chase_player(to_player: Vector3, delta: float) -> void:
    if to_player.length_squared() <= 0.001:
        return

    var direction: Vector3 = to_player.normalized()
    velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)

func _decide_neutral(distance: float) -> void:
    decision_timer = decision_rng.randf_range(decision_interval_min, decision_interval_max)
    if guard_meter < 25.0 and distance < 6.0:
        neutral_motion = "retreat"
    elif distance > attack_range and distance < 5.0 and decision_rng.randf() < 0.30:
        neutral_motion = "strafe"
        orbit_side = -1.0 if decision_rng.randf() < 0.5 else 1.0
    else:
        neutral_motion = "approach"

func get_cpu_state() -> String:
    if not targetable:
        return "ko"
    if is_instance_valid(cinematic_owner):
        return "cinematic"
    if stagger_timer > 0.0:
        return "recover"
    if dodge_timer > 0.0:
        return "dodge"
    if guarding:
        return "guard"
    if attack_active:
        return "combo" if combo_step > 1 else "attack"
    return neutral_motion

func _choose_close_action() -> void:
    attack_cycle += 1

    if guard_meter > 25.0 and decision_rng.randf() < 0.25:
        guarding = true
        guard_timer = guard_duration
        attack_cooldown = attack_cooldown_time * 0.80
        _update_labels()
        return

    _start_attack()

func _start_attack() -> void:
    attack_cooldown = attack_cooldown_time
    attack_active = true
    attack_elapsed = 0.0
    attack_hit_triggered = false

    combo_step = 1
    attack_airborne = not is_on_floor()
    combo_branch = ["neutral", "up", "down", "side"][decision_rng.randi_range(0, 3)]
    _begin_strike()

func _begin_strike() -> void:
    attack_hitbox.call("deactivate")
    attack_elapsed = 0.0
    attack_hit_triggered = false
    attack_confirmed = false
    animation_action_id += 1
    selected_attack = moveset.attack(combo_step, attack_airborne, combo_branch)
    attack_timing = selected_attack.animation_timing(rig_adapter.manifest)

func _face_direction(direction: Vector3, delta: float) -> void:
    var flat: Vector3 = direction
    flat.y = 0.0

    if flat.length_squared() <= 0.001:
        return

    var target_yaw: float = atan2(flat.x, flat.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, 10.0 * delta)

func _move_and_handle_bounces() -> void:
    var was_on_floor: bool = is_on_floor()
    var pre_move_velocity: Vector3 = velocity
    move_and_slide()

    if (
        ground_bounce_pending
        and not was_on_floor
        and is_on_floor()
        and pre_move_velocity.y < -5.0
    ):
        ground_bounce_pending = false
        velocity.y = ground_bounce_velocity
        stagger_timer = maxf(stagger_timer, 0.34)
        _trigger_bounce_feedback("ground")

    if wall_bounce_pending and is_on_wall():
        var horizontal_speed: float = Vector2(pre_move_velocity.x, pre_move_velocity.z).length()
        if horizontal_speed >= 4.0:
            _apply_wall_bounce(pre_move_velocity)

func _apply_wall_bounce(pre_move_velocity: Vector3) -> void:
    var collision_count: int = get_slide_collision_count()

    for index: int in range(collision_count):
        var collision: KinematicCollision3D = get_slide_collision(index)
        var normal: Vector3 = collision.get_normal()

        if absf(normal.y) > 0.55:
            continue

        var reflected: Vector3 = pre_move_velocity.bounce(normal) * wall_bounce_strength
        velocity.x = reflected.x
        velocity.z = reflected.z
        velocity.y = maxf(velocity.y, 2.2)
        wall_bounce_pending = false
        stagger_timer = maxf(stagger_timer, 0.38)
        _trigger_bounce_feedback("wall")
        return

func _trigger_bounce_feedback(_bounce_kind: String) -> void:
    if is_instance_valid(combat_feedback):
        if combat_feedback.has_method("spawn_impact"):
            combat_feedback.call(
                "spawn_impact",
                global_position + Vector3.UP * 0.45,
                "bounce"
            )
        if combat_feedback.has_method("hit_stop"):
            combat_feedback.call("hit_stop", 0.045, 0.14)

    if is_instance_valid(player) and player.has_method("extend_combo_feedback"):
        player.call("extend_combo_feedback", 0.85)

func is_targetable() -> bool:
    return targetable

func set_locked(value: bool) -> void:
    lock_label.visible = value and targetable

func receive_combat_hit(
    damage: float,
    direction: Vector3,
    knockback: float,
    launch_velocity: float,
    hitstun: float
) -> float:
    if not targetable or invulnerable_timer > 0.0:
        return 0.0

    if not guarding:
        juggle_timer = 1.5
        juggle_hits += 1
        if juggle_hits > 12:
            juggle_hits = 0
            invulnerable_timer = 0.65
            stagger_timer = 0.0
            velocity.y = -5.0
            return 0.0
    var applied_damage: float = damage
    var applied_knockback: float = knockback

    if guarding:
        guard_meter = maxf(guard_meter - damage * 1.8 - knockback, 0.0)
        guard_regen_delay = 1.2
        guard_timer = maxf(guard_timer, 0.14)
        if guard_meter <= 0.0:
            guarding = false
            guard_timer = 0.0
            stagger_timer = 1.0
        applied_damage *= 0.22
        applied_knockback *= 0.18
        launch_velocity *= 0.15
        ground_bounce_pending = false
        wall_bounce_pending = false
    else:
        attack_active = false
        attack_hitbox.call("deactivate")
        stagger_timer = hitstun
        if reactive_substitution and reaction_timer <= 0.0 and substitutions > 0 and substitution_cooldown <= 0.0 and randf() < 0.18:
            reaction_timer = randf_range(0.10, 0.18)
        wall_bounce_pending = applied_knockback >= 4.0
        ground_bounce_pending = launch_velocity < -2.0

    health = maxf(health - applied_damage, 0.0)

    var push: Vector3 = direction
    push.y = 0.0
    if push.length_squared() > 0.001:
        velocity.x = push.normalized().x * applied_knockback
        velocity.z = push.normalized().z * applied_knockback

    if absf(launch_velocity) > 0.01:
        velocity.y = launch_velocity

    hit_cycle += 1
    if false and hit_cycle % 4 == 0 and health > 0.0 and not guarding and is_on_floor():
        _start_reaction_dodge(direction)

    animation_action_id += 1
    _update_labels()

    if health <= 0.0:
        _knock_out()

    return applied_damage

func on_attack_connected(target: Node, _actual_damage: float, _launch_velocity: float) -> void:
    var impact_kind: String = "normal"
    if target.has_method("get_is_guarding") and bool(target.call("get_is_guarding")):
        impact_kind = "guard"

    if is_instance_valid(combat_feedback):
        if combat_feedback.has_method("spawn_impact") and target is Node3D:
            var target_3d: Node3D = target as Node3D
            combat_feedback.call(
                "spawn_impact",
                target_3d.global_position + Vector3.UP * 0.75,
                impact_kind
            )
        if combat_feedback.has_method("hit_stop"):
            combat_feedback.call("hit_stop", 0.030, 0.14)

func take_hit(damage: float, knockback: float, direction: Vector3, combo_step: int) -> void:
    var launch_velocity: float = 0.0
    if combo_step >= 4:
        launch_velocity = 8.5
    receive_combat_hit(damage, direction, knockback, launch_velocity, 0.28)

func _start_reaction_dodge(incoming_direction: Vector3) -> void:
    var side: Vector3 = Vector3(-incoming_direction.z, 0.0, incoming_direction.x)
    if side.length_squared() <= 0.001:
        side = global_basis.x

    dodge_direction = side.normalized()
    dodge_timer = 0.22
    stagger_timer = 0.0

func _update_labels() -> void:
    var state: String = ""
    if guarding:
        state = "  [DEF]"
    elif not is_on_floor():
        state = "  [AR]"

    health_label.text = "ENEMY  %d / %d%s" % [int(health), int(max_health), state]

func _knock_out() -> void:
    targetable = false
    guarding = false
    attack_active = false
    attack_hitbox.call("deactivate")
    ground_bounce_pending = false
    wall_bounce_pending = false
    lock_label.visible = false
    health_label.text = "K.O."
    respawn_timer = recovery_delay

func _respawn() -> void:
    cinematic_owner = null
    global_position = spawn_position
    velocity = Vector3.ZERO
    health = max_health
    guard_meter = 100.0
    substitutions = 4
    invulnerable_timer = 0.0
    reaction_timer = 0.0
    targetable = true
    guarding = false
    ground_bounce_pending = false
    wall_bounce_pending = false
    attack_active = false
    attack_hitbox.call("deactivate")
    stagger_timer = 0.0
    dodge_timer = 0.0
    guard_timer = 0.0
    attack_cooldown = 0.8
    neutral_motion = "approach"
    decision_timer = 0.20
    _update_labels()

func get_is_guarding() -> bool:
    return guarding

func is_airborne() -> bool:
    return not is_on_floor()

func _substitute() -> void:
    if not targetable or substitutions <= 0 or substitution_cooldown > 0.0:
        return
    combat_feedback.call("spawn_substitution", global_position)
    substitutions -= 1
    substitution_cooldown = 0.65
    substitution_regen = 0.0
    invulnerable_timer = 0.4
    stagger_timer = 0.0
    attack_active = false
    attack_hitbox.call("deactivate")
    velocity = Vector3.ZERO
    global_position = player.global_position - player.global_basis.z * 2.3
    global_position.x = clampf(global_position.x, -27.5, 27.5)
    global_position.z = clampf(global_position.z, -27.5, 27.5)
    combat_feedback.call("spawn_substitution", global_position)

func begin_cinematic_lock(requester: Node) -> bool:
    if not targetable or (is_instance_valid(cinematic_owner) and cinematic_owner != requester):
        return false
    cinematic_owner = requester
    cinematic_watchdog = 0.5
    attack_active = false
    attack_hitbox.call("deactivate")
    guarding = false
    guard_timer = 0.0
    velocity = Vector3.ZERO
    return true

func refresh_cinematic_lock(requester: Node) -> bool:
    if cinematic_owner != requester or not targetable:
        return false
    cinematic_watchdog = 0.5
    return true

func end_cinematic_lock(requester: Node) -> void:
    if cinematic_owner == requester:
        cinematic_owner = null
        cinematic_watchdog = 0.0
