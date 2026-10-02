extends CharacterBody3D

@export var max_health := 100.0
@export var recovery_delay := 2.0
@export var knockback_friction := 12.0

var health := 100.0
var targetable := true
var spawn_position := Vector3.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual: MeshInstance3D = $Visual
@onready var lock_label: Label3D = $LockLabel
@onready var health_label: Label3D = $HealthLabel

func _ready() -> void:
    health = max_health
    spawn_position = global_position
    _update_labels()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
    velocity.z = move_toward(velocity.z, 0.0, knockback_friction * delta)
    move_and_slide()

func is_targetable() -> bool:
    return targetable

func set_locked(value: bool) -> void:
    lock_label.visible = value and targetable

func take_hit(damage: float, knockback: float, direction: Vector3, combo_step: int) -> void:
    if not targetable:
        return

    health = max(health - damage, 0.0)
    var push := direction
    push.y = 0.0
    if push.length_squared() > 0.001:
        velocity.x = push.normalized().x * knockback
        velocity.z = push.normalized().z * knockback
    if combo_step >= 4:
        velocity.y = 4.5

    _flash_hit()
    _update_labels()

    if health <= 0.0:
        _knock_out()

func _flash_hit() -> void:
    visual.scale = Vector3(1.18, 0.82, 1.18)
    var tween := create_tween()
    tween.tween_property(visual, "scale", Vector3.ONE, 0.12)

func _update_labels() -> void:
    health_label.text = "DUMMY  %d / %d" % [int(health), int(max_health)]

func _knock_out() -> void:
    targetable = false
    lock_label.visible = false
    health_label.text = "K.O."
    await get_tree().create_timer(recovery_delay).timeout

    global_position = spawn_position
    velocity = Vector3.ZERO
    health = max_health
    targetable = true
    _update_labels()
