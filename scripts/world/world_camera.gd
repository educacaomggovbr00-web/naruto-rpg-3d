extends Node3D

var yaw: float = 0.0
var pitch: float = 0.14
var focus: Vector3

@onready var actor: CharacterBody3D = get_parent() as CharacterBody3D
@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var controls: Control = get_node("../../HUD/WorldControls")

func _ready() -> void:
    top_level = true
    process_physics_priority = 20
    focus = actor.global_position + Vector3.UP * _focus_height()
    position = focus

    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = 0.25
    arm.shape = shape
    arm.margin = 0.18
    arm.spring_length = 5.25
    arm.add_excluded_object(actor.get_rid())
    camera.fov = 60.0

    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if not actor.input_enabled:
        return

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * 0.003
        pitch = clampf(pitch - event.relative.y * 0.003, -0.30, 0.52)
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    var touch: Vector2 = controls.consume_camera_delta()

    if actor.input_enabled:
        yaw -= touch.x * 0.0046
        pitch = clampf(pitch - touch.y * 0.0046, -0.30, 0.52)

    var desired_focus: Vector3 = actor.global_position + Vector3.UP * _focus_height()
    focus = focus.lerp(desired_focus, 1.0 - exp(-10.0 * delta))
    global_position = focus
    rotation = Vector3(pitch, yaw, 0.0)

    var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
    var speed_ratio: float = clampf(speed / 13.0, 0.0, 1.0)
    arm.spring_length = lerpf(arm.spring_length, 5.25 + speed_ratio * 0.45, 1.0 - exp(-4.5 * delta))
    camera.fov = lerpf(camera.fov, 60.0 + speed_ratio * 3.0, 1.0 - exp(-4.5 * delta))


func _focus_height() -> float:
    if actor != null and actor.has_method("get_character_definition"):
        var definition: CharacterDefinition = actor.call("get_character_definition") as CharacterDefinition
        if definition != null:
            return clampf(definition.model_target_height * 0.68, 1.02, 1.20)
    return 1.14
