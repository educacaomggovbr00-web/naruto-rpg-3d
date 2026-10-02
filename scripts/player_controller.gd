extends CharacterBody3D

@export var move_speed: float = 7.5
@export var run_speed: float = 12.0
@export var acceleration: float = 28.0
@export var air_control: float = 8.0
@export var jump_velocity: float = 7.0
@export var turn_speed: float = 14.0

@export_group("Combat")
@export var max_health: float = 100.0
@export var lock_range: float = 28.0
@export var attack_range: float = 2.8
@export var combo_reset_time: float = 0.75
@export var attack_lunge_speed: float = 5.5
@export var guard_damage_multiplier: float = 0.25
@export var dodge_speed: float = 17.0
@export var dodge_duration: float = 0.24
@export var dodge_cooldown_time: float = 0.70
@export var max_substitutions: int = 4
@export var substitution_cooldown_time: float = 4.0
@export var substitution_distance: float = 2.3

@export_group("Chakra")
@export var max_chakra: float = 100.0
@export var chakra_passive_regen: float = 4.0
@export var chakra_charge_rate: float = 38.0
@export var chakra_dash_cost: float = 18.0
@export var chakra_dash_speed: float = 24.0
@export var chakra_dash_duration: float = 0.30

@export_group("Jutsu")
@export var jutsu_cost: float = 32.0
@export var jutsu_damage: float = 26.0
@export var jutsu_range: float = 10.0
@export var jutsu_knockback: float = 9.0
@export var jutsu_cooldown_time: float = 1.25

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var spawn_position: Vector3 = Vector3.ZERO
var locked_target: Node3D = null

var health: float = 100.0
var chakra: float = 100.0
var substitutions: int = 4
var combo_step: int = 0

var combo_timer: float = 0.0
var attack_cooldown: float = 0.0
var attack_lunge_timer: float = 0.0
var attack_lunge_direction: Vector3 = Vector3.ZERO
var chakra_dash_timer: float = 0.0
var chakra_dash_direction: Vector3 = Vector3.ZERO
var dodge_timer: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var substitution_cooldown: float = 0.0
var jutsu_cooldown: float = 0.0
var jutsu_timer: float = 0.0
var stagger_timer: float = 0.0
var invulnerable_timer: float = 0.0
var respawn_timer: float = 0.0

var jump_requested: bool = false
var is_guarding: bool = false
var is_charging_chakra: bool = false
var defeated: bool = false
var mobile_controls: Node = null

@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
    spawn_position = global_position
    health = max_health
    chakra = max_chakra
    substitutions = max_substitutions
    mobile_controls = get_node_or_null("../HUD/MobileControls")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and not _is_mobile_runtime():
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _try_attack()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_TAB:
            _toggle_lock_on()
        elif event.physical_keycode == KEY_Q:
            _start_chakra_dash()
        elif event.physical_keycode == KEY_SPACE:
            jump_requested = true
        elif event.physical_keycode == KEY_E:
            _try_jutsu()
        elif event.physical_keycode == KEY_F:
            _try_substitution()
        elif event.physical_keycode == KEY_ALT:
            _start_dodge()

func _physics_process(delta: float) -> void:
    _consume_mobile_actions()
    _update_timers(delta)

    if defeated:
        _process_defeated(delta)
        return

    _validate_locked_target()
    _refresh_hold_states()

    if is_charging_chakra and stagger_timer <= 0.0 and dodge_timer <= 0.0 and chakra_dash_timer <= 0.0:
        chakra = minf(max_chakra, chakra + chakra_charge_rate * delta)
    elif chakra_dash_timer <= 0.0:
        chakra = minf(max_chakra, chakra + chakra_passive_regen * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta

    if jump_requested and is_on_floor() and _can_use_movement_action():
        velocity.y = jump_velocity
    jump_requested = false

    if stagger_timer > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
        move_and_slide()
        return

    if dodge_timer > 0.0:
        velocity.x = dodge_direction.x * dodge_speed
        velocity.z = dodge_direction.z * dodge_speed
        _face_direction(dodge_direction, delta, 24.0)
        move_and_slide()
        return

    if chakra_dash_timer > 0.0:
        velocity.x = chakra_dash_direction.x * chakra_dash_speed
        velocity.z = chakra_dash_direction.z * chakra_dash_speed
        _face_direction(chakra_dash_direction, delta, 24.0)
        move_and_slide()
        return

    if is_charging_chakra:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
    elif attack_lunge_timer > 0.0:
        velocity.x = attack_lunge_direction.x * attack_lunge_speed
        velocity.z = attack_lunge_direction.z * attack_lunge_speed
    else:
        _apply_movement(delta)

    if is_instance_valid(locked_target):
        var face: Vector3 = locked_target.global_position - global_position
        face.y = 0.0
        _face_direction(face, delta, turn_speed)

    move_and_slide()

func _consume_mobile_actions() -> void:
    if not is_instance_valid(mobile_controls):
        return

    if bool(mobile_controls.call("consume_attack")):
        _try_attack()
    if bool(mobile_controls.call("consume_lock")):
        _toggle_lock_on()
    if bool(mobile_controls.call("consume_chakra_dash")):
        _start_chakra_dash()
    if bool(mobile_controls.call("consume_jump")):
        jump_requested = true
    if bool(mobile_controls.call("consume_jutsu")):
        _try_jutsu()
    if bool(mobile_controls.call("consume_substitution")):
        _try_substitution()
    if bool(mobile_controls.call("consume_dodge")):
        _start_dodge()

func _refresh_hold_states() -> void:
    var mobile_guard: bool = false
    var mobile_charge: bool = false

    if is_instance_valid(mobile_controls):
        mobile_guard = bool(mobile_controls.call("is_guard_held"))
        mobile_charge = bool(mobile_controls.call("is_charge_held"))

    var keyboard_guard: bool = Input.is_physical_key_pressed(KEY_R)
    var keyboard_charge: bool = Input.is_physical_key_pressed(KEY_C)

    is_guarding = (mobile_guard or keyboard_guard) and stagger_timer <= 0.0 and dodge_timer <= 0.0
    is_charging_chakra = (mobile_charge or keyboard_charge) and not is_guarding and attack_cooldown <= 0.0

func _update_timers(delta: float) -> void:
    combo_timer = maxf(combo_timer - delta, 0.0)
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    attack_lunge_timer = maxf(attack_lunge_timer - delta, 0.0)
    chakra_dash_timer = maxf(chakra_dash_timer - delta, 0.0)
    dodge_timer = maxf(dodge_timer - delta, 0.0)
    dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
    substitution_cooldown = maxf(substitution_cooldown - delta, 0.0)
    jutsu_cooldown = maxf(jutsu_cooldown - delta, 0.0)
    jutsu_timer = maxf(jutsu_timer - delta, 0.0)
    stagger_timer = maxf(stagger_timer - delta, 0.0)
    invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)

    if combo_timer <= 0.0:
        combo_step = 0

func _process_defeated(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
    velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
    move_and_slide()

    respawn_timer = maxf(respawn_timer - delta, 0.0)
    if respawn_timer <= 0.0:
        _respawn()

func _apply_movement(delta: float) -> void:
    var input_vector: Vector2 = _get_move_input()
    var direction: Vector3 = _camera_relative_direction(input_vector)

    var wants_run: bool = Input.is_physical_key_pressed(KEY_SHIFT)
    if is_instance_valid(mobile_controls):
        wants_run = wants_run or bool(mobile_controls.call("is_run_requested"))

    var target_speed: float = run_speed if wants_run else move_speed
    if is_guarding:
        target_speed *= 0.50

    var target_velocity: Vector3 = direction * target_speed
    var accel: float = acceleration if is_on_floor() else air_control

    velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

    if not is_instance_valid(locked_target) and direction.length_squared() > 0.01:
        _face_direction(direction, delta, turn_speed)

func _get_move_input() -> Vector2:
    var input_vector: Vector2 = Vector2.ZERO

    if is_instance_valid(mobile_controls):
        var mobile_value: Variant = mobile_controls.call("get_move_vector")
        if mobile_value is Vector2:
            input_vector = mobile_value

    if input_vector.length() <= 0.001:
        input_vector = Vector2(
            float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
            float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
        )

    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    return input_vector

func _camera_relative_direction(input_vector: Vector2) -> Vector3:
    if input_vector.length() <= 0.001:
        return Vector3.ZERO

    var camera: Camera3D = get_viewport().get_camera_3d()
    if camera == null:
        return Vector3(input_vector.x, 0.0, -input_vector.y).normalized()

    var forward: Vector3 = -camera.global_basis.z
    var right: Vector3 = camera.global_basis.x
    forward.y = 0.0
    right.y = 0.0

    return (right.normalized() * input_vector.x + forward.normalized() * -input_vector.y).normalized()

func _face_direction(direction: Vector3, delta: float, speed: float) -> void:
    var flat: Vector3 = direction
    flat.y = 0.0
    if flat.length_squared() <= 0.001:
        return

    var target_yaw: float = atan2(flat.x, flat.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, speed * delta)

func _toggle_lock_on() -> void:
    if defeated:
        return

    if is_instance_valid(locked_target):
        _set_locked_target(null)
        return

    var best_target: Node3D = null
    var best_distance: float = lock_range

    for candidate_node: Node in get_tree().get_nodes_in_group("lock_targets"):
        var candidate: Node3D = candidate_node as Node3D
        if candidate == null:
            continue
        if candidate.has_method("is_targetable") and not bool(candidate.call("is_targetable")):
            continue

        var distance: float = global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best_distance = distance
            best_target = candidate

    _set_locked_target(best_target)

func _set_locked_target(target: Node3D) -> void:
    if is_instance_valid(locked_target) and locked_target.has_method("set_locked"):
        locked_target.call("set_locked", false)

    locked_target = target

    if is_instance_valid(locked_target) and locked_target.has_method("set_locked"):
        locked_target.call("set_locked", true)

func _validate_locked_target() -> void:
    if not is_instance_valid(locked_target):
        locked_target = null
        return

    if global_position.distance_to(locked_target.global_position) > lock_range * 1.35:
        _set_locked_target(null)
        return

    if locked_target.has_method("is_targetable") and not bool(locked_target.call("is_targetable")):
        _set_locked_target(null)

func _start_chakra_dash() -> void:
    if not _can_use_movement_action() or chakra < chakra_dash_cost:
        return

    var direction: Vector3 = Vector3.ZERO
    if is_instance_valid(locked_target):
        direction = locked_target.global_position - global_position
    else:
        var camera: Camera3D = get_viewport().get_camera_3d()
        if camera != null:
            direction = -camera.global_basis.z
        else:
            direction = global_basis.z

    direction.y = 0.0
    if direction.length_squared() <= 0.001:
        return

    is_charging_chakra = false
    is_guarding = false
    chakra -= chakra_dash_cost
    chakra_dash_direction = direction.normalized()
    chakra_dash_timer = chakra_dash_duration

func _start_dodge() -> void:
    if defeated or stagger_timer > 0.0 or dodge_cooldown > 0.0 or chakra_dash_timer > 0.0:
        return

    var direction: Vector3 = _camera_relative_direction(_get_move_input())
    if direction.length_squared() <= 0.001:
        if is_instance_valid(locked_target):
            direction = global_basis.x
        else:
            direction = -global_basis.z

    direction.y = 0.0
    if direction.length_squared() <= 0.001:
        return

    is_charging_chakra = false
    is_guarding = false
    dodge_direction = direction.normalized()
    dodge_timer = dodge_duration
    dodge_cooldown = dodge_cooldown_time
    invulnerable_timer = maxf(invulnerable_timer, dodge_duration + 0.08)

func _try_substitution() -> void:
    if defeated or substitutions <= 0 or substitution_cooldown > 0.0:
        return

    substitutions -= 1
    substitution_cooldown = substitution_cooldown_time
    invulnerable_timer = maxf(invulnerable_timer, 0.80)
    stagger_timer = 0.0
    velocity = Vector3.ZERO
    is_guarding = false
    is_charging_chakra = false

    if is_instance_valid(locked_target):
        var behind: Vector3 = locked_target.global_basis.z
        behind.y = 0.0
        if behind.length_squared() <= 0.001:
            behind = Vector3.BACK
        global_position = locked_target.global_position + behind.normalized() * substitution_distance
        var face: Vector3 = locked_target.global_position - global_position
        _face_direction(face, 1.0, 100.0)
    else:
        var escape: Vector3 = -global_basis.z
        escape.y = 0.0
        if escape.length_squared() > 0.001:
            global_position += escape.normalized() * substitution_distance

    if camera_rig.has_method("add_impact_shake"):
        camera_rig.call("add_impact_shake", 0.10)

func _try_attack() -> void:
    if defeated or attack_cooldown > 0.0 or chakra_dash_timer > 0.0 or dodge_timer > 0.0:
        return
    if stagger_timer > 0.0 or is_charging_chakra:
        return

    is_guarding = false
    combo_step = combo_step + 1 if combo_timer > 0.0 else 1
    if combo_step > 4:
        combo_step = 1

    combo_timer = combo_reset_time
    attack_cooldown = 0.22 if combo_step < 4 else 0.38

    var target: Node3D = _find_attack_target(attack_range)
    if is_instance_valid(target):
        var direction: Vector3 = target.global_position - global_position
        direction.y = 0.0

        if direction.length_squared() > 0.001:
            attack_lunge_direction = direction.normalized()
            attack_lunge_timer = 0.10

        var damage_by_step: Array[float] = [8.0, 8.0, 11.0, 18.0]
        var knockback_by_step: Array[float] = [2.0, 2.5, 3.2, 8.5]

        if target.has_method("take_hit"):
            target.call(
                "take_hit",
                damage_by_step[combo_step - 1],
                knockback_by_step[combo_step - 1],
                direction,
                combo_step
            )

        if camera_rig.has_method("add_impact_shake"):
            camera_rig.call("add_impact_shake", 0.07 if combo_step < 4 else 0.15)

func _try_jutsu() -> void:
    if defeated or stagger_timer > 0.0 or jutsu_cooldown > 0.0:
        return
    if chakra < jutsu_cost or dodge_timer > 0.0 or chakra_dash_timer > 0.0:
        return

    is_guarding = false
    is_charging_chakra = false
    chakra -= jutsu_cost
    jutsu_cooldown = jutsu_cooldown_time
    jutsu_timer = 0.48
    attack_cooldown = maxf(attack_cooldown, 0.42)

    var target: Node3D = _find_attack_target(jutsu_range)
    if is_instance_valid(target):
        var direction: Vector3 = target.global_position - global_position
        direction.y = 0.0
        _face_direction(direction, 1.0, 100.0)

        if target.has_method("take_hit"):
            target.call("take_hit", jutsu_damage, jutsu_knockback, direction, 4)

    if camera_rig.has_method("add_impact_shake"):
        camera_rig.call("add_impact_shake", 0.16)

func _find_attack_target(range_limit: float) -> Node3D:
    if is_instance_valid(locked_target):
        if global_position.distance_to(locked_target.global_position) <= range_limit:
            return locked_target

    var forward: Vector3 = global_basis.z
    var best_target: Node3D = null
    var best_distance: float = range_limit

    for candidate_node: Node in get_tree().get_nodes_in_group("lock_targets"):
        var candidate: Node3D = candidate_node as Node3D
        if candidate == null:
            continue
        if candidate.has_method("is_targetable") and not bool(candidate.call("is_targetable")):
            continue

        var to_target: Vector3 = candidate.global_position - global_position
        to_target.y = 0.0
        var distance: float = to_target.length()

        if distance <= 0.001 or distance > best_distance:
            continue

        if forward.normalized().dot(to_target.normalized()) > -0.15:
            best_distance = distance
            best_target = candidate

    return best_target

func take_hit(damage: float, direction: Vector3, knockback: float) -> void:
    if defeated or invulnerable_timer > 0.0:
        return

    var applied_damage: float = damage
    var applied_knockback: float = knockback

    if is_guarding:
        applied_damage *= guard_damage_multiplier
        applied_knockback *= 0.25
    else:
        stagger_timer = 0.28

    health = maxf(health - applied_damage, 0.0)

    var push: Vector3 = direction
    push.y = 0.0
    if push.length_squared() > 0.001:
        velocity.x = push.normalized().x * applied_knockback
        velocity.z = push.normalized().z * applied_knockback

    if camera_rig.has_method("add_impact_shake"):
        camera_rig.call("add_impact_shake", 0.05 if is_guarding else 0.11)

    if health <= 0.0:
        _defeat()

func _defeat() -> void:
    defeated = true
    respawn_timer = 2.5
    is_guarding = false
    is_charging_chakra = false
    combo_step = 0
    _set_locked_target(null)

func _respawn() -> void:
    global_position = spawn_position
    velocity = Vector3.ZERO
    health = max_health
    chakra = max_chakra * 0.65
    substitutions = max_substitutions
    substitution_cooldown = 0.0
    dodge_cooldown = 0.0
    jutsu_cooldown = 0.0
    invulnerable_timer = 1.0
    defeated = false

func _can_use_movement_action() -> bool:
    return (
        not defeated
        and stagger_timer <= 0.0
        and dodge_timer <= 0.0
        and chakra_dash_timer <= 0.0
        and not is_charging_chakra
    )

func get_locked_target() -> Node3D:
    return locked_target

func get_max_health() -> float:
    return max_health

func get_health() -> float:
    return health

func get_max_chakra() -> float:
    return max_chakra

func get_chakra() -> float:
    return chakra

func get_substitutions() -> int:
    return substitutions

func get_combo_step() -> int:
    return combo_step

func get_attack_cooldown() -> float:
    return attack_cooldown

func get_chakra_dash_timer() -> float:
    return chakra_dash_timer

func get_jutsu_timer() -> float:
    return jutsu_timer

func get_is_guarding() -> bool:
    return is_guarding

func get_is_charging() -> bool:
    return is_charging_chakra

func get_substitution_cooldown() -> float:
    return substitution_cooldown

func get_jutsu_cooldown() -> float:
    return jutsu_cooldown

func is_defeated() -> bool:
    return defeated

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )
