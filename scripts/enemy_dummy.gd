extends CharacterBody3D

@export var max_health: float = 120.0
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var attack_range: float = 2.25
@export var detection_range: float = 18.0
@export var attack_damage: float = 10.0
@export var attack_knockback: float = 5.5
@export var attack_cooldown_time: float = 1.05
@export var guard_duration: float = 0.65
@export var recovery_delay: float = 2.5
@export var knockback_friction: float = 12.0

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var health: float = 120.0
var targetable: bool = true
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

@onready var visual: MeshInstance3D = $Visual
@onready var lock_label: Label3D = $LockLabel
@onready var health_label: Label3D = $HealthLabel
@onready var player: CharacterBody3D = $"../Player"

func _ready() -> void:
    health = max_health
    spawn_position = global_position
    _update_labels()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    _update_timers(delta)

    if not targetable:
        velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
        velocity.z = move_toward(velocity.z, 0.0, knockback_friction * delta)
        move_and_slide()

        if respawn_timer <= 0.0:
            _respawn()
        return

    if not is_instance_valid(player) or bool(player.call("is_defeated")):
        _slow_down(delta)
        move_and_slide()
        return

    if stagger_timer > 0.0:
        _slow_down(delta)
        move_and_slide()
        return

    if dodge_timer > 0.0:
        velocity.x = dodge_direction.x * 8.5
        velocity.z = dodge_direction.z * 8.5
        move_and_slide()
        return

    var to_player: Vector3 = player.global_position - global_position
    to_player.y = 0.0
    var distance: float = to_player.length()

    if distance <= detection_range and to_player.length_squared() > 0.001:
        _face_direction(to_player, delta)

    if guard_timer > 0.0:
        guarding = true
        _slow_down(delta)
        move_and_slide()
        return

    guarding = false

    if distance > detection_range:
        _slow_down(delta)
    elif distance > attack_range:
        _chase_player(to_player, delta)
    else:
        _slow_down(delta)
        if attack_cooldown <= 0.0:
            _choose_close_action()

    move_and_slide()

func _update_timers(delta: float) -> void:
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    guard_timer = maxf(guard_timer - delta, 0.0)
    stagger_timer = maxf(stagger_timer - delta, 0.0)
    dodge_timer = maxf(dodge_timer - delta, 0.0)

    if not targetable:
        respawn_timer = maxf(respawn_timer - delta, 0.0)

func _slow_down(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
    velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

func _chase_player(to_player: Vector3, delta: float) -> void:
    if to_player.length_squared() <= 0.001:
        return

    var direction: Vector3 = to_player.normalized()
    velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)

func _choose_close_action() -> void:
    attack_cycle += 1

    if attack_cycle % 3 == 0:
        guarding = true
        guard_timer = guard_duration
        attack_cooldown = attack_cooldown_time * 0.80
        _update_labels()
        return

    _attack_player()

func _attack_player() -> void:
    if not is_instance_valid(player):
        return

    var direction: Vector3 = player.global_position - global_position
    direction.y = 0.0

    if direction.length_squared() <= 0.001:
        return

    attack_cooldown = attack_cooldown_time
    player.call("take_hit", attack_damage, direction.normalized(), attack_knockback)

    visual.scale = Vector3(1.05, 0.92, 1.15)
    var tween: Tween = create_tween()
    tween.tween_property(visual, "scale", Vector3.ONE, 0.16)

func _face_direction(direction: Vector3, delta: float) -> void:
    var flat: Vector3 = direction
    flat.y = 0.0

    if flat.length_squared() <= 0.001:
        return

    var target_yaw: float = atan2(flat.x, flat.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, 10.0 * delta)

func is_targetable() -> bool:
    return targetable

func set_locked(value: bool) -> void:
    lock_label.visible = value and targetable

func take_hit(damage: float, knockback: float, direction: Vector3, combo_step: int) -> void:
    if not targetable:
        return

    var applied_damage: float = damage
    var applied_knockback: float = knockback

    if guarding:
        applied_damage *= 0.22
        applied_knockback *= 0.18
    else:
        stagger_timer = 0.22

    health = maxf(health - applied_damage, 0.0)

    var push: Vector3 = direction
    push.y = 0.0
    if push.length_squared() > 0.001:
        velocity.x = push.normalized().x * applied_knockback
        velocity.z = push.normalized().z * applied_knockback

    if combo_step >= 4 and not guarding:
        velocity.y = 4.5

    hit_cycle += 1
    if hit_cycle % 4 == 0 and health > 0.0 and not guarding:
        _start_reaction_dodge(direction)

    _flash_hit()
    _update_labels()

    if health <= 0.0:
        _knock_out()

func _start_reaction_dodge(incoming_direction: Vector3) -> void:
    var side: Vector3 = Vector3(-incoming_direction.z, 0.0, incoming_direction.x)
    if side.length_squared() <= 0.001:
        side = global_basis.x

    dodge_direction = side.normalized()
    dodge_timer = 0.22
    stagger_timer = 0.0

func _flash_hit() -> void:
    visual.scale = Vector3(1.18, 0.82, 1.18)
    var tween: Tween = create_tween()
    tween.tween_property(visual, "scale", Vector3.ONE, 0.12)

func _update_labels() -> void:
    var state: String = ""
    if guarding:
        state = "  [DEF]"

    health_label.text = "ENEMY  %d / %d%s" % [int(health), int(max_health), state]

func _knock_out() -> void:
    targetable = false
    guarding = false
    lock_label.visible = false
    health_label.text = "K.O."
    respawn_timer = recovery_delay

func _respawn() -> void:
    global_position = spawn_position
    velocity = Vector3.ZERO
    health = max_health
    targetable = true
    guarding = false
    attack_cooldown = 0.8
    _update_labels()
