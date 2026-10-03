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
@export var attack_range: float = 3.0
@export var combo_reset_time: float = 0.82
@export var attack_lunge_speed: float = 6.5
@export var guard_damage_multiplier: float = 0.25
@export var dodge_speed: float = 17.0
@export var dodge_duration: float = 0.24
@export var dodge_cooldown_time: float = 0.70
@export var max_substitutions: int = 4
@export var substitution_cooldown_time: float = 4.0
@export var substitution_distance: float = 2.3

@export_group("Combat Polish")
@export var combo_display_reset_time: float = 1.35

@export_group("Aerial Combat")
@export var launcher_velocity: float = 8.5
@export var air_chase_speed: float = 22.0
@export var air_float_time: float = 0.18
@export var air_slam_velocity: float = -13.0

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
var air_float_timer: float = 0.0

var attack_active: bool = false
var attack_elapsed: float = 0.0
var attack_hit_triggered: bool = false
var attack_is_airborne: bool = false
var animation_state: String = "idle"
var animation_action_id: int = 0
var attack_startup: float = 0.12
var attack_duration: float = 0.28
var jutsu_elapsed: float = 0.0
var jutsu_released: bool = false
var attack_buffer: float = 0.0
var attack_confirmed: bool = false
var combo_branch: String = "neutral"
var specials: Node3D = null
var dash_hitbox: Area3D = null
var dash_elapsed: float = 0.0
var dash_speed_now: float = 0.0
var air_dash_count: int = 0
var guard_meter: float = 100.0
var guard_stun: float = 0.0
var guard_regen_delay: float = 0.0
var sub_regen_timer: float = 0.0
var substitution_hidden: float = 0.0
var combo_hits: int = 0
var combo_damage: float = 0.0
var combo_display_timer: float = 0.0

var jump_requested: bool = false
var is_guarding: bool = false
var is_charging_chakra: bool = false
var defeated: bool = false
var mobile_controls: Node = null

@onready var camera_rig: Node3D = $CameraRig
@onready var attack_hitbox: Area3D = $AttackHitbox
@onready var rig_adapter: Node = get_node_or_null("RiggedCharacterAdapter")
@onready var combat_feedback: Node = get_node_or_null("../CombatFeedback")

func _ready() -> void:
    specials = Node3D.new()
    specials.name = "CombatSpecials"
    specials.set_script(preload("res://scripts/combat_specials.gd"))
    add_child(specials)
    spawn_position = global_position
    health = max_health
    chakra = max_chakra
    substitutions = max_substitutions
    mobile_controls = get_node_or_null("../HUD/MobileControls")
    dash_hitbox = Area3D.new()
    dash_hitbox.set_script(preload("res://scripts/combat_hitbox.gd"))
    dash_hitbox.collision_layer = 0
    dash_hitbox.collision_mask = 16
    var shape_node: CollisionShape3D = CollisionShape3D.new()
    var sphere: SphereShape3D = SphereShape3D.new()
    sphere.radius = 0.85
    shape_node.shape = sphere
    dash_hitbox.add_child(shape_node)
    add_child(dash_hitbox)
    dash_hitbox.position = Vector3(0, 0, 0.45)

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
        elif event.physical_keycode == KEY_1:
            specials.selected = "demon"
        elif event.physical_keycode == KEY_2:
            specials.selected = "rasengan"
        elif event.physical_keycode == KEY_F:
            _try_substitution()
        elif event.physical_keycode == KEY_ALT:
            _start_dodge()

func _physics_process(delta: float) -> void:
    _consume_mobile_actions()
    _update_timers(delta)
    _update_attack_timeline(delta)
    _update_jutsu_timeline(delta)
    if attack_buffer > 0.0 and not attack_active and attack_cooldown <= 0.0:
        attack_buffer = 0.0
        _try_attack()

    if defeated:
        _process_defeated(delta)
        _update_animation_state()
        return

    _validate_locked_target()
    _refresh_hold_states()

    if is_charging_chakra and stagger_timer <= 0.0 and dodge_timer <= 0.0 and chakra_dash_timer <= 0.0:
        chakra = minf(max_chakra, chakra + chakra_charge_rate * delta)
    elif chakra_dash_timer <= 0.0:
        chakra = minf(max_chakra, chakra + chakra_passive_regen * delta)

    if not is_on_floor() and air_float_timer <= 0.0:
        velocity.y -= gravity * delta
    elif air_float_timer > 0.0 and velocity.y < 0.0:
        velocity.y = move_toward(velocity.y, 0.0, gravity * delta)

    if jump_requested and is_on_floor() and _can_use_movement_action():
        velocity.y = jump_velocity
    jump_requested = false

    if stagger_timer > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
        move_and_slide()
        _update_animation_state()
        return

    if dodge_timer > 0.0:
        velocity.x = dodge_direction.x * dodge_speed
        velocity.z = dodge_direction.z * dodge_speed
        _face_direction(dodge_direction, delta, 24.0)
        move_and_slide()
        _update_animation_state()
        return

    if chakra_dash_timer > 0.0:
        dash_elapsed += delta
        if is_instance_valid(locked_target):
            var pursuit: Vector3 = locked_target.global_position - global_position
            if pursuit.length_squared() > 0.001:
                chakra_dash_direction = chakra_dash_direction.slerp(pursuit.normalized(), minf(delta * 9.0, 1.0)).normalized()
        if dash_elapsed >= 0.06 and dash_hitbox.remaining_time <= 0.0:
            dash_hitbox.call("activate", self, 0.0, 0.0, 0.0, 0.16, 0.5)
        dash_speed_now = move_toward(dash_speed_now, chakra_dash_speed, delta * 100.0) if dash_elapsed > 0.06 else 0.0
        velocity.x = chakra_dash_direction.x * dash_speed_now
        velocity.z = chakra_dash_direction.z * dash_speed_now
        velocity.y = chakra_dash_direction.y * minf(dash_speed_now, air_chase_speed)
        _face_direction(chakra_dash_direction, delta, 24.0)
        move_and_slide()
        _update_animation_state()
        return

    if jutsu_timer > 0.0:
        var special_velocity: Vector3 = specials.call("movement_velocity", delta)
        velocity.x = special_velocity.x
        velocity.z = special_velocity.z
    elif is_charging_chakra:
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
    _update_animation_state()

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

    is_guarding = (mobile_guard or keyboard_guard) and stagger_timer <= 0.0 and dodge_timer <= 0.0 and guard_meter > 0.0 and not attack_active and jutsu_timer <= 0.0 and chakra_dash_timer <= 0.0
    is_charging_chakra = (mobile_charge or keyboard_charge) and not is_guarding and not attack_active and attack_cooldown <= 0.0 and jutsu_timer <= 0.0 and stagger_timer <= 0.0 and dodge_timer <= 0.0 and chakra_dash_timer <= 0.0

func _update_timers(delta: float) -> void:
    attack_buffer = maxf(attack_buffer - delta, 0.0)
    guard_stun = maxf(guard_stun - delta, 0.0)
    guard_regen_delay = maxf(guard_regen_delay - delta, 0.0)
    if guard_regen_delay <= 0.0 and not is_guarding:
        guard_meter = minf(100.0, guard_meter + delta * 22.0)
    if substitutions < max_substitutions:
        sub_regen_timer += delta
        if sub_regen_timer >= 8.0:
            substitutions += 1
            sub_regen_timer = 0.0
    substitution_hidden = maxf(substitution_hidden - delta, 0.0)
    if is_instance_valid(rig_adapter):
        rig_adapter.visible = substitution_hidden <= 0.0
    if is_on_floor():
        air_dash_count = 0
    combo_timer = maxf(combo_timer - delta, 0.0)
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    attack_lunge_timer = maxf(attack_lunge_timer - delta, 0.0)
    chakra_dash_timer = maxf(chakra_dash_timer - delta, 0.0)
    if chakra_dash_timer <= 0.0 and dash_hitbox != null:
        dash_hitbox.call("deactivate")
    dodge_timer = maxf(dodge_timer - delta, 0.0)
    dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
    substitution_cooldown = maxf(substitution_cooldown - delta, 0.0)
    jutsu_cooldown = maxf(jutsu_cooldown - delta, 0.0)
    jutsu_timer = maxf(jutsu_timer - delta, 0.0)
    stagger_timer = maxf(stagger_timer - delta, 0.0)
    invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)
    air_float_timer = maxf(air_float_timer - delta, 0.0)
    combo_display_timer = maxf(combo_display_timer - delta, 0.0)

    if combo_timer <= 0.0 and not attack_active:
        combo_step = 0

    if combo_display_timer <= 0.0:
        combo_hits = 0
        combo_damage = 0.0

func _update_attack_timeline(delta: float) -> void:
    if not attack_active:
        return

    attack_elapsed += delta

    if not attack_hit_triggered and attack_elapsed >= attack_startup:
        attack_hit_triggered = true
        _open_attack_hitbox()
    if attack_elapsed >= attack_duration:
        attack_active = false
        attack_hitbox.call("deactivate")

func _cancel_attack() -> void:
    attack_active = false
    attack_lunge_timer = 0.0
    air_float_timer = 0.0
    attack_hitbox.call("deactivate")

func _cancel_jutsu() -> void:
    jutsu_timer = 0.0
    jutsu_released = true
    if is_instance_valid(specials):
        specials.call("cancel")

func _update_jutsu_timeline(delta: float) -> void:
    if jutsu_timer <= 0.0 or jutsu_released:
        return
    jutsu_elapsed += delta
    if jutsu_elapsed >= 0.24:
        jutsu_released = true
        _release_jutsu()

func _open_attack_hitbox() -> void:
    var damage_values: Array[float] = [7.0, 8.0, 10.0, 16.0]
    var knockback_values: Array[float] = [1.8, 2.4, 3.0, 5.0]
    var launch_velocity: float = 0.0
    var hitstun: float = 0.18

    if combo_step == 4:
        if attack_is_airborne:
            launch_velocity = air_slam_velocity
            hitstun = 0.42
        else:
            launch_velocity = launcher_velocity
            hitstun = 0.38
            if combo_branch == "down":
                launch_velocity = -4.0
                hitstun = 0.65
            elif combo_branch == "side":
                launch_velocity = 2.0
                knockback_values[3] = 10.0

    if is_instance_valid(rig_adapter) and rig_adapter.has_method("snap_attack_hitbox"):
        rig_adapter.call("snap_attack_hitbox", combo_step, attack_is_airborne)

    attack_hitbox.call(
        "activate",
        self,
        damage_values[combo_step - 1],
        knockback_values[combo_step - 1],
        launch_velocity,
        hitstun,
        float(rig_adapter.call("get_attack_timing", combo_step, attack_is_airborne).get("active", 0.09))
    )

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
    if is_instance_valid(locked_target):
        var radial: Vector3 = locked_target.global_position - global_position
        radial.y = 0.0
        if radial.length_squared() > 0.001:
            radial = radial.normalized()
            var tangent: Vector3 = Vector3(-radial.z, 0.0, radial.x)
            direction = (tangent * input_vector.x - radial * input_vector.y).limit_length(1.0)

    var wants_run: bool = Input.is_physical_key_pressed(KEY_SHIFT)
    if is_instance_valid(mobile_controls):
        wants_run = wants_run or bool(mobile_controls.call("is_run_requested"))

    var target_speed: float = run_speed if wants_run else move_speed
    if is_guarding:
        target_speed *= 0.50

    if guard_stun > 0.0 or attack_active or jutsu_timer > 0.0:
        target_speed = 0.0
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
        if typeof(mobile_value) == TYPE_VECTOR2:
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

    return (right.normalized() * input_vector.x + forward.normalized() * -input_vector.y).limit_length(1.0)

func _face_direction(direction: Vector3, delta: float, speed: float) -> void:
    var flat: Vector3 = direction
    flat.y = 0.0
    if flat.length_squared() <= 0.001:
        return

    var target_yaw: float = atan2(flat.x, flat.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-speed * delta))

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
    var can_cancel: bool = attack_active and attack_confirmed and attack_elapsed >= attack_startup + 0.09 and combo_step < 4
    if (not _can_use_movement_action() and not can_cancel) or chakra < chakra_dash_cost:
        return
    if not is_on_floor() and air_dash_count >= 2:
        return
    if can_cancel:
        _cancel_attack()
        combo_step = 0
        attack_cooldown = 0.0
    if not is_on_floor():
        air_dash_count += 1
    dash_elapsed = 0.0
    dash_speed_now = 0.0

    var direction: Vector3 = Vector3.ZERO
    var target_is_airborne: bool = false

    if is_instance_valid(locked_target):
        direction = locked_target.global_position - global_position
        if locked_target.has_method("is_airborne"):
            target_is_airborne = bool(locked_target.call("is_airborne"))
        if not target_is_airborne and absf(direction.y) < 1.2:
            direction.y = 0.0
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
    animation_action_id += 1
    chakra_dash_direction = direction.normalized()
    chakra_dash_timer = 0.55

    if is_instance_valid(combat_feedback) and combat_feedback.has_method("spawn_dash_burst"):
        combat_feedback.call("spawn_dash_burst", global_position)

func on_attack_contact(target: Node, _damage: float) -> void:
    if chakra_dash_timer <= 0.0:
        return
    chakra_dash_timer = 0.0
    dash_hitbox.call("deactivate")
    velocity = Vector3.ZERO
    if target.has_method("get_is_guarding") and bool(target.call("get_is_guarding")):
        stagger_timer = 0.22
        velocity = -chakra_dash_direction * 5.0
    else:
        attack_cooldown = 0.0
        if attack_buffer > 0.0:
            _try_attack()

func _start_dodge() -> void:
    if defeated or stagger_timer > 0.0 or dodge_cooldown > 0.0 or chakra_dash_timer > 0.0:
        return

    var direction: Vector3 = _camera_relative_direction(_get_move_input())
    if direction.length_squared() <= 0.001:
        direction = global_basis.x if is_instance_valid(locked_target) else -global_basis.z

    direction.y = 0.0
    if direction.length_squared() <= 0.001:
        return

    is_charging_chakra = false
    is_guarding = false
    _cancel_attack()
    _cancel_jutsu()
    animation_action_id += 1
    dodge_direction = direction.normalized()
    dodge_timer = dodge_duration
    dodge_cooldown = dodge_cooldown_time
    invulnerable_timer = maxf(invulnerable_timer, dodge_duration + 0.08)

func _try_substitution() -> void:
    if defeated or substitutions <= 0 or substitution_cooldown > 0.0:
        return

    _cancel_attack()
    _cancel_jutsu()
    dodge_timer = 0.0
    chakra_dash_timer = 0.0
    var substitution_origin: Vector3 = global_position

    substitutions -= 1
    substitution_cooldown = 0.65
    sub_regen_timer = 0.0
    substitution_hidden = 0.12
    invulnerable_timer = maxf(invulnerable_timer, 0.40)
    stagger_timer = 0.0
    velocity = Vector3.ZERO
    is_guarding = false
    is_charging_chakra = false

    if is_instance_valid(locked_target):
        var behind: Vector3 = -locked_target.global_basis.z
        behind.y = 0.0
        if behind.length_squared() <= 0.001:
            behind = Vector3.BACK

        var desired_position: Vector3 = locked_target.global_position + behind.normalized() * substitution_distance
        desired_position.x = clampf(desired_position.x, -27.5, 27.5)
        desired_position.z = clampf(desired_position.z, -27.5, 27.5)
        var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(locked_target.global_position, desired_position, 1)
        var obstruction: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
        if not obstruction.is_empty():
            desired_position = obstruction["position"] + obstruction["normal"] * 0.7
        global_position = desired_position
        var face: Vector3 = locked_target.global_position - global_position
        _face_direction(face, 1.0, 100.0)
    else:
        var escape: Vector3 = -global_basis.z
        escape.y = 0.0
        if escape.length_squared() > 0.001:
            global_position += escape.normalized() * substitution_distance

    if is_instance_valid(combat_feedback) and combat_feedback.has_method("spawn_substitution"):
        combat_feedback.call("spawn_substitution", substitution_origin)
        combat_feedback.call("spawn_substitution", global_position)

    if camera_rig.has_method("add_combat_impact"):
        camera_rig.call("add_combat_impact", 0.10, 1.4)
    elif camera_rig.has_method("add_impact_shake"):
        camera_rig.call("add_impact_shake", 0.10)

func _try_attack() -> void:
    if chakra_dash_timer > 0.0:
        attack_buffer = 0.25
        return
    if attack_active:
        if attack_elapsed >= attack_startup and combo_step < 4:
            attack_buffer = 0.22
        return
    if defeated or attack_active or jutsu_timer > 0.0 or attack_cooldown > 0.0 or chakra_dash_timer > 0.0 or dodge_timer > 0.0:
        return
    if stagger_timer > 0.0 or is_charging_chakra:
        return

    is_guarding = false
    attack_is_airborne = not is_on_floor()
    combo_step = combo_step + 1 if combo_timer > 0.0 else 1
    if combo_step > 4:
        combo_step = 1

    attack_confirmed = false
    if combo_step == 1:
        var stick: Vector2 = _get_move_input()
        combo_branch = "down" if stick.y > 0.45 else "up" if stick.y < -0.45 else "side" if absf(stick.x) > 0.45 else "neutral"
    combo_timer = combo_reset_time
    var timing: Dictionary = {}
    if is_instance_valid(rig_adapter) and rig_adapter.has_method("get_attack_timing"):
        timing = rig_adapter.call("get_attack_timing", combo_step, attack_is_airborne)
    attack_startup = float(timing.get("impact", 0.12 if combo_step < 4 else 0.18))
    attack_duration = float(timing.get("duration", 0.28 if combo_step < 4 else 0.40))
    attack_cooldown = attack_duration
    animation_action_id += 1
    attack_active = true
    attack_elapsed = 0.0
    attack_hit_triggered = false

    if attack_is_airborne:
        air_float_timer = maxf(air_float_time, attack_duration)
        velocity.y = maxf(velocity.y, 0.0)

    var target: Node3D = _find_attack_target(attack_range)
    if is_instance_valid(target):
        var direction: Vector3 = target.global_position - global_position
        var flat: Vector3 = direction
        flat.y = 0.0

        if flat.length_squared() > 0.001:
            attack_lunge_direction = flat.normalized()
            # Do not lunge through the opponent between chained strikes.
            var approach_distance: float = maxf(flat.length() - 1.15, 0.0)
            attack_lunge_timer = minf(0.12, approach_distance / maxf(attack_lunge_speed, 0.01))
            _face_direction(flat, 1.0, 100.0)

func _try_jutsu() -> void:
    specials.call("start")

func _release_jutsu() -> void:
    pass # Projectile/hand timelines are owned by CombatSpecials.

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
        var distance: float = to_target.length()
        var flat: Vector3 = to_target
        flat.y = 0.0

        if distance <= 0.001 or distance > best_distance:
            continue
        if flat.length_squared() > 0.001 and forward.normalized().dot(flat.normalized()) <= -0.15:
            continue

        best_distance = distance
        best_target = candidate

    return best_target

func receive_combat_hit(
    damage: float,
    direction: Vector3,
    knockback: float,
    launch_velocity: float,
    hitstun: float
) -> float:
    if defeated or invulnerable_timer > 0.0:
        return 0.0

    var applied_damage: float = damage
    var applied_knockback: float = knockback

    if is_guarding:
        guard_meter = maxf(guard_meter - damage * 1.8 - knockback, 0.0)
        guard_regen_delay = 1.2
        guard_stun = 0.14
        if guard_meter <= 0.0:
            is_guarding = false
            stagger_timer = 1.0
            animation_action_id += 1
            if is_instance_valid(combat_feedback):
                combat_feedback.call("spawn_impact", global_position, "launcher")
        applied_damage *= guard_damage_multiplier
        applied_knockback *= 0.25
        launch_velocity *= 0.15
    else:
        _cancel_attack()
        _cancel_jutsu()
        animation_action_id += 1
        stagger_timer = hitstun

    health = maxf(health - applied_damage, 0.0)

    var push: Vector3 = direction
    push.y = 0.0
    if push.length_squared() > 0.001:
        velocity.x = push.normalized().x * applied_knockback
        velocity.z = push.normalized().z * applied_knockback

    if absf(launch_velocity) > 0.01:
        velocity.y = launch_velocity

    if camera_rig.has_method("add_combat_impact"):
        camera_rig.call(
            "add_combat_impact",
            0.05 if is_guarding else 0.11,
            0.7 if is_guarding else 1.8
        )
    elif camera_rig.has_method("add_impact_shake"):
        camera_rig.call("add_impact_shake", 0.05 if is_guarding else 0.11)

    if health <= 0.0:
        _defeat()

    return applied_damage

func on_attack_connected(target: Node, actual_damage: float, launch_velocity: float) -> void:
    if actual_damage <= 0.001:
        return
    var target_guarding: bool = (
        target.has_method("get_is_guarding")
        and bool(target.call("get_is_guarding"))
    )

    if not target_guarding:
        attack_confirmed = true
        combo_hits += 1
        combo_damage += maxf(actual_damage, 0.0)
        combo_display_timer = combo_display_reset_time

    var impact_kind: String = "normal"
    var hit_stop_duration: float = 0.035
    var shake_strength: float = 0.07
    var zoom_kick: float = 1.2

    if target_guarding:
        impact_kind = "guard"
        hit_stop_duration = 0.025
        shake_strength = 0.045
        zoom_kick = 0.7
    elif launch_velocity > 1.0:
        impact_kind = "launcher"
        hit_stop_duration = 0.055
        shake_strength = 0.13
        zoom_kick = 2.6
    elif launch_velocity < -1.0:
        impact_kind = "slam"
        hit_stop_duration = 0.070
        shake_strength = 0.17
        zoom_kick = 3.8

    if is_instance_valid(combat_feedback):
        if combat_feedback.has_method("spawn_impact") and target is Node3D:
            var target_3d: Node3D = target as Node3D
            combat_feedback.call(
                "spawn_impact",
                target_3d.global_position + Vector3.UP * 0.75,
                impact_kind
            )
        if combat_feedback.has_method("hit_stop"):
            combat_feedback.call("hit_stop", hit_stop_duration, 0.10)

    if camera_rig.has_method("add_combat_impact"):
        camera_rig.call("add_combat_impact", shake_strength, zoom_kick)
    elif camera_rig.has_method("add_impact_shake"):
        camera_rig.call("add_impact_shake", shake_strength)

func take_hit(damage: float, direction: Vector3, knockback: float) -> void:
    receive_combat_hit(damage, direction, knockback, 0.0, 0.28)

func extend_combo_feedback(extra_time: float) -> void:
    if combo_hits <= 0:
        return
    combo_display_timer = maxf(combo_display_timer, extra_time)
    combo_timer = maxf(combo_timer, minf(extra_time, combo_reset_time))

func _update_animation_state() -> void:
    if defeated:
        animation_state = "defeat"
    elif stagger_timer > 0.0:
        animation_state = "hit"
    elif dodge_timer > 0.0:
        animation_state = "dodge"
    elif chakra_dash_timer > 0.0:
        animation_state = "chakra_dash"
    elif is_charging_chakra:
        animation_state = "chakra_charge"
    elif is_guarding:
        animation_state = "guard"
    elif jutsu_timer > 0.0:
        animation_state = "jutsu"
    elif attack_active:
        animation_state = "air_attack" if attack_is_airborne else "attack"
    elif not is_on_floor():
        animation_state = "air"
    elif Vector2(velocity.x, velocity.z).length() > 0.5:
        animation_state = "run"
    else:
        animation_state = "idle"

func _defeat() -> void:
    defeated = true
    respawn_timer = 2.5
    combo_hits = 0
    combo_damage = 0.0
    combo_display_timer = 0.0
    is_guarding = false
    is_charging_chakra = false
    _cancel_attack()
    _cancel_jutsu()
    dodge_timer = 0.0
    chakra_dash_timer = 0.0
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
    combo_hits = 0
    combo_damage = 0.0
    combo_display_timer = 0.0
    stagger_timer = 0.0
    combo_timer = 0.0
    combo_step = 0
    attack_cooldown = 0.0
    guard_meter = 100.0
    guard_stun = 0.0
    attack_buffer = 0.0
    defeated = false

func _can_use_movement_action() -> bool:
    return (
        not defeated
        and stagger_timer <= 0.0
        and dodge_timer <= 0.0
        and chakra_dash_timer <= 0.0
        and not is_charging_chakra
        and not attack_active
        and jutsu_timer <= 0.0
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

func get_combo_hits() -> int:
    return combo_hits

func get_combo_damage() -> float:
    return combo_damage

func get_animation_action_id() -> int:
    return animation_action_id

func get_animation_state() -> String:
    return animation_state

func is_defeated() -> bool:
    return defeated

func is_airborne() -> bool:
    return not is_on_floor()

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )

func get_special_animation() -> String:
    return "rasengan" if specials.current == "rasengan" else "jutsu"
