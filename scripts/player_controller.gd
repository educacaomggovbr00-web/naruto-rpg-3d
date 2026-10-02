extends CharacterBody3D

@export var move_speed := 7.5
@export var run_speed := 12.0
@export var acceleration := 28.0
@export var air_control := 8.0
@export var jump_velocity := 7.0
@export var turn_speed := 14.0

@export_group("Combat")
@export var lock_range := 28.0
@export var attack_range := 2.8
@export var combo_reset_time := 0.75
@export var attack_lunge_speed := 5.5

@export_group("Chakra")
@export var max_chakra := 100.0
@export var chakra_regen_per_second := 12.0
@export var chakra_dash_cost := 20.0
@export var chakra_dash_speed := 24.0
@export var chakra_dash_duration := 0.30

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var locked_target: Node3D = null
var chakra := 100.0
var combo_step := 0

var combo_timer := 0.0
var attack_cooldown := 0.0
var attack_lunge_timer := 0.0
var attack_lunge_direction := Vector3.ZERO
var chakra_dash_timer := 0.0
var chakra_dash_direction := Vector3.ZERO
var jump_requested := false
var mobile_controls: Node = null

@onready var camera_rig: Node3D = $CameraRig

func _ready() -> void:
    chakra = max_chakra
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

func _physics_process(delta: float) -> void:
    _consume_mobile_actions()
    _update_timers(delta)
    _validate_locked_target()

    if chakra_dash_timer <= 0.0:
        chakra = min(max_chakra, chakra + chakra_regen_per_second * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta

    if jump_requested and is_on_floor() and chakra_dash_timer <= 0.0:
        velocity.y = jump_velocity
    jump_requested = false

    if chakra_dash_timer > 0.0:
        velocity.x = chakra_dash_direction.x * chakra_dash_speed
        velocity.z = chakra_dash_direction.z * chakra_dash_speed
        _face_direction(chakra_dash_direction, delta, 24.0)
        move_and_slide()
        return

    if attack_lunge_timer > 0.0:
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

    if mobile_controls.consume_attack():
        _try_attack()
    if mobile_controls.consume_lock():
        _toggle_lock_on()
    if mobile_controls.consume_chakra_dash():
        _start_chakra_dash()
    if mobile_controls.consume_jump():
        jump_requested = true

func _update_timers(delta: float) -> void:
    combo_timer = max(combo_timer - delta, 0.0)
    attack_cooldown = max(attack_cooldown - delta, 0.0)
    attack_lunge_timer = max(attack_lunge_timer - delta, 0.0)
    chakra_dash_timer = max(chakra_dash_timer - delta, 0.0)

    if combo_timer <= 0.0:
        combo_step = 0

func _apply_movement(delta: float) -> void:
    var input: Vector2 = Vector2.ZERO

    if is_instance_valid(mobile_controls):
        input = mobile_controls.get_move_vector()

    if input.length() <= 0.001:
        input = Vector2(
            float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
            float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
        )

    if input.length() > 1.0:
        input = input.normalized()

    var camera: Camera3D = get_viewport().get_camera_3d()
    var direction: Vector3 = Vector3.ZERO

    if camera and input.length() > 0.0:
        var forward: Vector3 = -camera.global_basis.z
        var right: Vector3 = camera.global_basis.x
        forward.y = 0.0
        right.y = 0.0
        direction = (right.normalized() * input.x + forward.normalized() * -input.y).normalized()

    var wants_run := Input.is_physical_key_pressed(KEY_SHIFT)
    if is_instance_valid(mobile_controls):
        wants_run = wants_run or mobile_controls.is_run_requested()

    var target_speed: float = run_speed if wants_run else move_speed
    var target_velocity: Vector3 = direction * target_speed
    var accel: float = acceleration if is_on_floor() else air_control

    velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

    if not is_instance_valid(locked_target) and direction.length_squared() > 0.01:
        _face_direction(direction, delta, turn_speed)

func _face_direction(direction: Vector3, delta: float, speed: float) -> void:
    var flat: Vector3 = direction
    flat.y = 0.0
    if flat.length_squared() <= 0.001:
        return
    var target_yaw: float = atan2(flat.x, flat.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, speed * delta)

func _toggle_lock_on() -> void:
    if is_instance_valid(locked_target):
        _set_locked_target(null)
        return

    var best_target: Node3D = null
    var best_distance: float = lock_range

    for candidate_node: Node in get_tree().get_nodes_in_group("lock_targets"):
        var candidate: Node3D = candidate_node as Node3D
        if candidate == null:
            continue
        if candidate.has_method("is_targetable") and not candidate.is_targetable():
            continue

        var distance: float = global_position.distance_to(candidate.global_position)
        if distance < best_distance:
            best_distance = distance
            best_target = candidate

    _set_locked_target(best_target)

func _set_locked_target(target: Node3D) -> void:
    if is_instance_valid(locked_target) and locked_target.has_method("set_locked"):
        locked_target.set_locked(false)

    locked_target = target

    if is_instance_valid(locked_target) and locked_target.has_method("set_locked"):
        locked_target.set_locked(true)

func _validate_locked_target() -> void:
    if not is_instance_valid(locked_target):
        locked_target = null
        return

    if global_position.distance_to(locked_target.global_position) > lock_range * 1.35:
        _set_locked_target(null)
        return

    if locked_target.has_method("is_targetable") and not locked_target.is_targetable():
        _set_locked_target(null)

func _start_chakra_dash() -> void:
    if chakra_dash_timer > 0.0 or chakra < chakra_dash_cost:
        return

    var direction: Vector3 = Vector3.ZERO
    if is_instance_valid(locked_target):
        direction = locked_target.global_position - global_position
    else:
        var camera: Camera3D = get_viewport().get_camera_3d()
        if camera:
            direction = -camera.global_basis.z
        else:
            direction = global_basis.z

    direction.y = 0.0
    if direction.length_squared() <= 0.001:
        return

    chakra -= chakra_dash_cost
    chakra_dash_direction = direction.normalized()
    chakra_dash_timer = chakra_dash_duration

func _try_attack() -> void:
    if attack_cooldown > 0.0 or chakra_dash_timer > 0.0:
        return

    combo_step = combo_step + 1 if combo_timer > 0.0 else 1
    if combo_step > 4:
        combo_step = 1

    combo_timer = combo_reset_time
    attack_cooldown = 0.22 if combo_step < 4 else 0.38

    var target: Node3D = _find_attack_target()
    if is_instance_valid(target):
        var direction: Vector3 = target.global_position - global_position
        direction.y = 0.0

        if direction.length_squared() > 0.001:
            attack_lunge_direction = direction.normalized()
            attack_lunge_timer = 0.10

        var damage_by_step: Array[float] = [8.0, 8.0, 11.0, 18.0]
        var knockback_by_step: Array[float] = [2.0, 2.5, 3.2, 8.5]
        target.take_hit(
            damage_by_step[combo_step - 1],
            knockback_by_step[combo_step - 1],
            direction,
            combo_step
        )

        if camera_rig.has_method("add_impact_shake"):
            camera_rig.add_impact_shake(0.07 if combo_step < 4 else 0.15)

func _find_attack_target() -> Node3D:
    if is_instance_valid(locked_target):
        if global_position.distance_to(locked_target.global_position) <= attack_range:
            return locked_target

    var forward: Vector3 = global_basis.z
    var best_target: Node3D = null
    var best_distance: float = attack_range

    for candidate_node: Node in get_tree().get_nodes_in_group("lock_targets"):
        var candidate: Node3D = candidate_node as Node3D
        if candidate == null:
            continue
        if candidate.has_method("is_targetable") and not candidate.is_targetable():
            continue

        var to_target: Vector3 = candidate.global_position - global_position
        to_target.y = 0.0
        var distance: float = to_target.length()

        if distance <= 0.001 or distance > best_distance:
            continue

        if forward.normalized().dot(to_target.normalized()) > 0.15:
            best_distance = distance
            best_target = candidate

    return best_target

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )
