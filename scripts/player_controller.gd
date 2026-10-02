extends CharacterBody3D

@export var move_speed := 7.5
@export var dash_speed := 13.0
@export var acceleration := 28.0
@export var air_control := 8.0
@export var jump_velocity := 7.0
@export var turn_speed := 14.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var camera := get_viewport().get_camera_3d()
    var direction := Vector3.ZERO

    if camera and input.length() > 0.0:
        var forward := -camera.global_basis.z
        var right := camera.global_basis.x
        forward.y = 0.0
        right.y = 0.0
        direction = (right.normalized() * input.x + forward.normalized() * -input.y).normalized()

    var target_speed := dash_speed if Input.is_action_pressed("dash") else move_speed
    var target := direction * target_speed
    var accel := acceleration if is_on_floor() else air_control

    velocity.x = move_toward(velocity.x, target.x, accel * delta)
    velocity.z = move_toward(velocity.z, target.z, accel * delta)

    if direction.length_squared() > 0.01:
        var target_yaw := atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

    move_and_slide()
