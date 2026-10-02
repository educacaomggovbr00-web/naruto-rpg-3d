extends Control

@export var joystick_radius := 92.0
@export var joystick_deadzone := 0.12
@export var camera_sensitivity := 0.006

var move_vector := Vector2.ZERO
var joystick_touch := -1
var camera_touch := -1
var camera_last_position := Vector2.ZERO
var camera_delta := Vector2.ZERO

var attack_queue := 0
var jump_queue := 0
var chakra_dash_queue := 0
var lock_queue := 0

var joystick_center := Vector2.ZERO
var joystick_knob := Vector2.ZERO
var attack_center := Vector2.ZERO
var jump_center := Vector2.ZERO
var chakra_center := Vector2.ZERO
var lock_center := Vector2.ZERO

var attack_radius := 70.0
var jump_radius := 54.0
var chakra_radius := 60.0
var lock_radius := 48.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(_update_layout)
    _update_layout()
    set_process_input(true)

func _update_layout() -> void:
    var w := size.x
    var h := size.y

    joystick_center = Vector2(145.0, h - 140.0)
    if joystick_touch == -1:
        joystick_knob = joystick_center

    attack_center = Vector2(w - 125.0, h - 140.0)
    jump_center = Vector2(w - 285.0, h - 92.0)
    chakra_center = Vector2(w - 270.0, h - 225.0)
    lock_center = Vector2(w - 92.0, 92.0)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_pressed(event.index, event.position)
        else:
            _touch_released(event.index)
    elif event is InputEventScreenDrag:
        _touch_dragged(event.index, event.position)

func _touch_pressed(touch_id: int, position: Vector2) -> void:
    if _inside_circle(position, attack_center, attack_radius):
        attack_queue += 1
        return

    if _inside_circle(position, jump_center, jump_radius):
        jump_queue += 1
        return

    if _inside_circle(position, chakra_center, chakra_radius):
        chakra_dash_queue += 1
        return

    if _inside_circle(position, lock_center, lock_radius):
        lock_queue += 1
        return

    if joystick_touch == -1 and position.x < size.x * 0.46 and position.y > size.y * 0.42:
        joystick_touch = touch_id
        _update_joystick(position)
        return

    if camera_touch == -1 and position.x >= size.x * 0.40:
        camera_touch = touch_id
        camera_last_position = position

func _touch_released(touch_id: int) -> void:
    if touch_id == joystick_touch:
        joystick_touch = -1
        move_vector = Vector2.ZERO
        joystick_knob = joystick_center
        queue_redraw()

    if touch_id == camera_touch:
        camera_touch = -1
        camera_delta = Vector2.ZERO

func _touch_dragged(touch_id: int, position: Vector2) -> void:
    if touch_id == joystick_touch:
        _update_joystick(position)
        return

    if touch_id == camera_touch:
        camera_delta += position - camera_last_position
        camera_last_position = position

func _update_joystick(position: Vector2) -> void:
    var offset := position - joystick_center
    if offset.length() > joystick_radius:
        offset = offset.normalized() * joystick_radius

    joystick_knob = joystick_center + offset
    move_vector = offset / joystick_radius

    if move_vector.length() < joystick_deadzone:
        move_vector = Vector2.ZERO

    queue_redraw()

func _inside_circle(position: Vector2, center: Vector2, radius: float) -> bool:
    return position.distance_squared_to(center) <= radius * radius

func get_move_vector() -> Vector2:
    return move_vector

func is_run_requested() -> bool:
    return move_vector.length() >= 0.82

func consume_camera_delta() -> Vector2:
    var result := camera_delta
    camera_delta = Vector2.ZERO
    return result

func consume_attack() -> bool:
    if attack_queue <= 0:
        return false
    attack_queue -= 1
    return true

func consume_jump() -> bool:
    if jump_queue <= 0:
        return false
    jump_queue -= 1
    return true

func consume_chakra_dash() -> bool:
    if chakra_dash_queue <= 0:
        return false
    chakra_dash_queue -= 1
    return true

func consume_lock() -> bool:
    if lock_queue <= 0:
        return false
    lock_queue -= 1
    return true

func is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )

func _draw() -> void:
    var base_fill := Color(0.03, 0.06, 0.10, 0.34)
    var base_line := Color(1.0, 1.0, 1.0, 0.44)
    var accent_fill := Color(0.08, 0.42, 0.95, 0.44)
    var attack_fill := Color(0.92, 0.20, 0.14, 0.46)
    var text_color := Color(1.0, 1.0, 1.0, 0.92)

    draw_circle(joystick_center, joystick_radius, base_fill)
    draw_arc(joystick_center, joystick_radius, 0.0, TAU, 48, base_line, 3.0, true)
    draw_circle(joystick_knob, 38.0, Color(1.0, 1.0, 1.0, 0.34))

    _draw_button(attack_center, attack_radius, attack_fill, "ATK", 27, text_color)
    _draw_button(chakra_center, chakra_radius, accent_fill, "DASH", 21, text_color)
    _draw_button(jump_center, jump_radius, base_fill, "PULO", 19, text_color)
    _draw_button(lock_center, lock_radius, base_fill, "LOCK", 17, text_color)

func _draw_button(center: Vector2, radius: float, fill: Color, label: String, font_size: int, text_color: Color) -> void:
    draw_circle(center, radius, fill)
    draw_arc(center, radius, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.48), 3.0, true)

    var width := radius * 1.7
    var baseline := center + Vector2(-width * 0.5, font_size * 0.34)
    draw_string(
        ThemeDB.fallback_font,
        baseline,
        label,
        HORIZONTAL_ALIGNMENT_CENTER,
        width,
        font_size,
        text_color
    )
