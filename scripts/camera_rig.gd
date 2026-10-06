extends Node3D

@export var mouse_sensitivity: float = 0.003
@export var touch_sensitivity: float = 0.006
@export var min_pitch: float = deg_to_rad(-45.0)
@export var max_pitch: float = deg_to_rad(55.0)
@export var height: float = 1.45
@export var lock_pitch: float = deg_to_rad(-9.0)
@export var lock_smoothing: float = 9.0

var yaw: float = 0.0
var pitch: float = deg_to_rad(-10.0)
var mobile_controls: Node = null
var shake_strength: float = 0.0
var fov_kick: float = 0.0
var base_fov: float = 68.0
var smoothed_focus: Vector3 = Vector3.ZERO
var cinematic_target: Node3D = null
var cinematic_remaining: float = 0.0
var sequence_shot: String = ""
var dash_roll: float = 0.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var player: CharacterBody3D = get_parent() as CharacterBody3D

func _ready() -> void:
    mobile_controls = get_node_or_null("../../HUD/MobileControls")
    base_fov = camera.fov
    smoothed_focus = player.global_position + Vector3.UP * height
    var camera_shape: SphereShape3D = SphereShape3D.new()
    camera_shape.radius = 0.28
    spring_arm.shape = camera_shape
    spring_arm.margin = 0.15
    spring_arm.collision_mask = 33
    spring_arm.add_excluded_object(player.get_rid())
    if not _is_mobile_runtime():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    var locked_target: Node3D = player.call("get_locked_target") as Node3D

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if not is_instance_valid(locked_target):
            yaw -= event.relative.x * mouse_sensitivity
            pitch = clampf(pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed and not _is_mobile_runtime():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
    var locked_target: Node3D = player.call("get_locked_target") as Node3D

    if not is_instance_valid(locked_target) and is_instance_valid(mobile_controls):
        var touch_value: Variant = mobile_controls.call("consume_camera_delta")
        if typeof(touch_value) == TYPE_VECTOR2:
            var touch_delta: Vector2 = touch_value
            if touch_delta.length_squared() > 0.0:
                yaw -= touch_delta.x * touch_sensitivity
                pitch = clampf(pitch - touch_delta.y * touch_sensitivity, min_pitch, max_pitch)

    var follow_position: Vector3 = player.global_position + Vector3.UP * height

    if is_instance_valid(locked_target):
        var to_target: Vector3 = locked_target.global_position - player.global_position
        var flat: Vector3 = to_target
        flat.y = 0.0

        if flat.length_squared() > 0.001:
            var desired_yaw: float = atan2(-flat.x, -flat.z)
            yaw = lerp_angle(yaw, desired_yaw, 1.0 - exp(-lock_smoothing * delta))

        pitch = lerp(pitch, lock_pitch, 1.0 - exp(-lock_smoothing * delta))
        follow_position = follow_position.lerp(
            locked_target.global_position + Vector3.UP * 1.0,
            0.42
        )

        var desired_length: float = clampf(5.6 + flat.length() * 0.48 + absf(to_target.y) * 0.25, 5.6, 18.0)
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

    shake_strength = move_toward(shake_strength, 0.0, delta * 0.85)
    fov_kick = move_toward(fov_kick, 0.0, delta * 18.0)
    var separation: float = player.global_position.distance_to(locked_target.global_position) if is_instance_valid(locked_target) else 0.0
    var dash_active: bool = float(player.call("get_chakra_dash_timer")) > 0.0
    var dash_fov: float = 5.0 if dash_active else 0.0
    var desired_fov: float = clampf(base_fov + separation * 0.35 + dash_fov + fov_kick, 56.0, 82.0)
    camera.fov = lerpf(camera.fov, desired_fov, 1.0 - exp(-8.0 * delta))
    cinematic_remaining = maxf(cinematic_remaining - delta, 0.0)
    if cinematic_remaining > 0.0 and is_instance_valid(cinematic_target):
        follow_position = (player.global_position + cinematic_target.global_position) * 0.5 + Vector3.UP
        var shot_distance: float = 8.0 if sequence_shot == "chain" else 5.2 if sequence_shot == "clash" else 5.8 if sequence_shot == "jutsu" else 6.4
        spring_arm.spring_length = lerpf(spring_arm.spring_length, shot_distance, 1.0 - exp(-6.0 * delta))
        if not sequence_shot.is_empty():
            var axis: Vector3 = cinematic_target.global_position - player.global_position
            var side_angle: float = 0.34 if sequence_shot == "jutsu" else 0.55
            var shot_yaw: float = atan2(-axis.x, -axis.z) + side_angle
            yaw = lerp_angle(yaw, shot_yaw, 1.0 - exp(-5.0 * delta))
            var sequence_fov: float = 63.0 if sequence_shot == "jutsu" else 60.0
            camera.fov = lerpf(camera.fov, sequence_fov, 1.0 - exp(-6.0 * delta))
    else:
        cinematic_target = null
        sequence_shot = ""

    var ticks: float = float(Time.get_ticks_msec()) * 0.001
    spring_arm.position = Vector3(
        sin(ticks * 47.0),
        cos(ticks * 61.0),
        0.0
    ) * shake_strength

    smoothed_focus = smoothed_focus.lerp(follow_position, 1.0 - exp(-12.0 * delta))
    var desired_roll: float = deg_to_rad(-1.15) if dash_active else 0.0
    dash_roll = lerpf(dash_roll, desired_roll, 1.0 - exp(-10.0 * delta))
    global_position = smoothed_focus
    global_rotation = Vector3(pitch, yaw, dash_roll)

func add_combat_impact(strength: float, zoom_amount: float) -> void:
    shake_strength = maxf(shake_strength, strength)
    fov_kick = minf(fov_kick, -absf(zoom_amount))

func begin_dash_impulse(amount: float = 3.0) -> void:
    fov_kick = maxf(fov_kick, absf(amount))
    shake_strength = maxf(shake_strength, 0.028)

func add_impact_shake(strength: float) -> void:
    shake_strength = maxf(shake_strength, strength)

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )

func begin_sequence(target: Node3D, duration: float) -> void:
    cinematic_target = target
    cinematic_remaining = duration

func set_sequence_shot(shot: String) -> void:
    sequence_shot = shot

func end_sequence() -> void:
    sequence_shot = ""
    cinematic_remaining = 0.0
    cinematic_target = null
