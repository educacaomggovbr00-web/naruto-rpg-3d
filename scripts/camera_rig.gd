extends Node3D

@export var mouse_sensitivity := 0.003
@export var min_pitch := deg_to_rad(-45.0)
@export var max_pitch := deg_to_rad(55.0)
@export var height := 1.4

var yaw := 0.0
var pitch := deg_to_rad(-10.0)

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * mouse_sensitivity
        pitch = clamp(pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
    var player := get_parent() as Node3D
    if not player:
        return
    global_position = player.global_position + Vector3.UP * height
    global_rotation = Vector3(pitch, yaw, 0.0)
