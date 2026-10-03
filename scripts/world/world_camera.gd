extends Node3D
var yaw: float = 0.0
var pitch: float = -0.22
var focus: Vector3
@onready var actor: CharacterBody3D = get_parent() as CharacterBody3D
@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var controls: Control = get_node("../../HUD/WorldControls")

func _ready() -> void:
    top_level = true
    process_physics_priority = 20
    focus = actor.global_position + Vector3.UP * 0.8
    position = focus
    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = 0.25
    arm.shape = shape
    arm.margin = 0.18
    arm.add_excluded_object(actor.get_rid())
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if not actor.input_enabled:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * 0.003
        pitch = clampf(pitch - event.relative.y * 0.003, -0.7, 0.45)
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    var touch: Vector2 = controls.consume_camera_delta()
    if actor.input_enabled:
        yaw -= touch.x * 0.005
        pitch = clampf(pitch - touch.y * 0.005, -0.7, 0.45)
    focus = focus.lerp(actor.global_position + Vector3.UP * 0.8, 1.0 - exp(-12.0 * delta))
    global_position = focus
    rotation = Vector3(pitch, yaw, 0)
    var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
    arm.spring_length = lerpf(arm.spring_length, 5.8 + clampf(speed / 13.0, 0, 1) * 0.7, 1.0 - exp(-5.0 * delta))
    camera.fov = lerpf(camera.fov, 66.0 + clampf(speed / 13.0, 0, 1) * 4.0, 1.0 - exp(-5.0 * delta))
