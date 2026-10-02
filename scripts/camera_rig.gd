extends Node3D

@export var mouse_sensitivity := 0.003
@export var touch_sensitivity := 0.006
@export var min_pitch := deg_to_rad(-45.0)
@export var max_pitch := deg_to_rad(55.0)
@export var height := 1.45
@export var lock_pitch := deg_to_rad(-9.0)
@export var lock_smoothing := 9.0

var yaw := 0.0
var pitch := deg_to_rad(-10.0)
var mobile_controls: Node = null
var shake_strength := 0.0

@onready var spring_arm: SpringArm3D = $SpringArm3D

func _ready() -> void:
    mobile_controls = get_node_or_null("../../HUD/MobileControls")
    if not _is_mobile_runtime():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    var player: Node = get_parent()

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if not is_instance_valid(player.locked_target):
            yaw -= event.relative.x * mouse_sensitivity
            pitch = clamp(pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed and not _is_mobile_runtime():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
    var player := get_parent() as Node3D
    if not player:
        return

    if not is_instance_valid(player.locked_target) and is_instance_valid(mobile_controls):
        var touch_delta: Vector2 = mobile_controls.consume_camera_delta()
        if touch_delta.length_squared() > 0.0:
            yaw -= touch_delta.x * touch_sensitivity
            pitch = clamp(pitch - touch_delta.y * touch_sensitivity, min_pitch, max_pitch)

    var follow_position: Vector3 = player.global_position + Vector3.UP * height

    if is_instance_valid(player.locked_target):
        var target: Node3D = player.locked_target
        var to_target: Vector3 = target.global_position - player.global_position
        var flat: Vector3 = to_target
        flat.y = 0.0

        if flat.length_squared() > 0.001:
            var desired_yaw: float = atan2(-flat.x, -flat.z)
            yaw = lerp_angle(yaw, desired_yaw, 1.0 - exp(-lock_smoothing * delta))

        pitch = lerp(pitch, lock_pitch, 1.0 - exp(-lock_smoothing * delta))
        follow_position = follow_position.lerp(
            target.global_position + Vector3.UP * 1.0,
            0.16
        )

        var desired_length: float = clampf(5.6 + flat.length() * 0.18, 5.6, 8.0)
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

    shake_strength = move_toward(shake_strength, 0.0, delta * 0.75)
    var ticks: float = Time.get_ticks_msec() * 0.001
    spring_arm.position = Vector3(
        sin(ticks * 47.0),
        cos(ticks * 61.0),
        0.0
    ) * shake_strength

    global_position = follow_position
    global_rotation = Vector3(pitch, yaw, 0.0)

func add_impact_shake(strength: float) -> void:
    shake_strength = max(shake_strength, strength)

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )
