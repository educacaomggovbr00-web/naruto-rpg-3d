extends Node3D

@export var mouse_sensitivity := 0.003
@export var min_pitch := deg_to_rad(-45.0)
@export var max_pitch := deg_to_rad(55.0)
@export var height := 1.45
@export var lock_pitch := deg_to_rad(-9.0)
@export var lock_smoothing := 9.0

var yaw := 0.0
var pitch := deg_to_rad(-10.0)

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    var player = get_parent()

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if not is_instance_valid(player.locked_target):
            yaw -= event.relative.x * mouse_sensitivity
            pitch = clamp(pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
    var player := get_parent() as Node3D
    if not player:
        return

    var follow_position := player.global_position + Vector3.UP * height

    if is_instance_valid(player.locked_target):
        var target: Node3D = player.locked_target
        var to_target := target.global_position - player.global_position
        var flat := to_target
        flat.y = 0.0

        if flat.length_squared() > 0.001:
            var desired_yaw := atan2(-flat.x, -flat.z)
            yaw = lerp_angle(yaw, desired_yaw, 1.0 - exp(-lock_smoothing * delta))

        pitch = lerp(pitch, lock_pitch, 1.0 - exp(-lock_smoothing * delta))
        follow_position = follow_position.lerp(
            target.global_position + Vector3.UP * 1.0,
            0.16
        )

        var desired_length := clamp(5.6 + flat.length() * 0.18, 5.6, 8.0)
        spring_arm.spring_length = lerp(
            spring_arm.spring_length,
            desired_length,
            1.0 - exp(-6.0 * delta)
        )
    else:
        spring_arm.spring_length = lerp(
            spring_arm.spring_length,
            5.5,
            1.0 - exp(-6.0 * delta)
        )

    global_position = follow_position
    global_rotation = Vector3(pitch, yaw, 0.0)
