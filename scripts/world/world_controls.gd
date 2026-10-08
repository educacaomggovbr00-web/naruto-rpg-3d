extends Control
## Exploration touch surface. Visual grouping keeps the world readable on small screens.
var move_vector: Vector2 = Vector2.ZERO
var camera_delta: Vector2 = Vector2.ZERO
var joystick_touch: int = -1
var camera_touch: int = -1
var sprint_touch: int = -1
var jump_queue: int = 0
var interact_queue: int = 0
var map_queue: int = 0
var joystick_center: Vector2
var jump_center: Vector2
var sprint_center: Vector2
var interact_center: Vector2
var map_center: Vector2
var radius: float = 86.0
var button_radius: float = 48.0
var context_label: String = "AÇÃO"

func _ready() -> void:
    resized.connect(_layout)
    GamePreferences.changed.connect(_layout)
    _layout()

func _layout() -> void:
    radius = clampf(size.y * 0.12, 50.0, 86.0)
    button_radius = clampf(size.y * 0.064, 30.0, 44.0)
    radius *= GamePreferences.controls_scale
    button_radius *= GamePreferences.controls_scale
    modulate.a = GamePreferences.controls_opacity
    joystick_center = Vector2(radius + 34.0, size.y - radius - 28.0)
    sprint_center = Vector2(size.x - button_radius - 26.0, size.y - button_radius - 26.0)
    jump_center = sprint_center + Vector2(-button_radius * 2.25, -button_radius * 0.45)
    interact_center = sprint_center + Vector2(-button_radius * 0.18, -button_radius * 2.45)
    map_center = Vector2(size.x - button_radius - 26.0, button_radius + 24.0)
    queue_redraw()

func _inside(point: Vector2, center: Vector2, reach: float) -> bool:
    return point.distance_squared_to(center) <= reach * reach

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pad_jutsu"):
        interact_queue = 1
    elif event.is_action_pressed("pad_lock"):
        map_queue = 1
    elif event is InputEventScreenTouch:
        if event.pressed:
            if joystick_touch == -1 and _inside(event.position, joystick_center, radius * 1.35):
                joystick_touch = event.index
                _move_stick(event.position)
            elif _inside(event.position, jump_center, button_radius):
                jump_queue += 1
            elif _inside(event.position, interact_center, button_radius):
                interact_queue += 1
            elif _inside(event.position, map_center, button_radius):
                map_queue += 1
            elif sprint_touch == -1 and _inside(event.position, sprint_center, button_radius):
                sprint_touch = event.index
            elif event.position.y < 112.0:
                return
            elif camera_touch == -1 and event.position.x > size.x * 0.38:
                camera_touch = event.index
            else:
                return
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                move_vector = Vector2.ZERO
            if event.index == sprint_touch:
                sprint_touch = -1
            if event.index == camera_touch:
                camera_touch = -1
        get_viewport().set_input_as_handled()
        queue_redraw()
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            _move_stick(event.position)
            get_viewport().set_input_as_handled()
        elif event.index == camera_touch:
            camera_delta += event.relative
            get_viewport().set_input_as_handled()

func _move_stick(point: Vector2) -> void:
    move_vector = ((point - joystick_center) / radius).limit_length(1.0)
    if move_vector.length() < 0.12:
        move_vector = Vector2.ZERO
    queue_redraw()

func consume_camera_delta() -> Vector2:
    var result: Vector2 = camera_delta
    camera_delta = Vector2.ZERO
    return result

func release_all() -> void:
    joystick_touch = -1
    camera_touch = -1
    sprint_touch = -1
    move_vector = Vector2.ZERO
    camera_delta = Vector2.ZERO
    jump_queue = 0
    interact_queue = 0
    map_queue = 0
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        release_all()

func _draw() -> void:
    var dark: Color = Color(0.015, 0.035, 0.055, 0.56)
    var line: Color = Color(0.78, 0.90, 0.94, 0.58)
    var orange: Color = Color(0.91, 0.36, 0.12, 0.66)
    var teal: Color = Color(0.09, 0.43, 0.52, 0.64)
    var text_color: Color = Color("fff4dc")

    draw_circle(joystick_center, radius, dark)
    draw_arc(joystick_center, radius, 0.0, TAU, 42, line, 2.0, true)
    draw_circle(joystick_center + move_vector * radius, radius * 0.38, Color(0.86, 0.93, 0.90, 0.56))
    draw_arc(joystick_center + move_vector * radius, radius * 0.38, 0.0, TAU, 30, Color(1, 1, 1, 0.28), 1.5, true)

    _button(jump_center, "PULO", teal, text_color)
    _button(sprint_center, "CORRER", orange if sprint_touch != -1 else dark, text_color)
    _button(interact_center, context_label, orange, text_color)
    _button(map_center, "MAPA", dark, text_color)

func _button(center: Vector2, label: String, fill: Color, text_color: Color) -> void:
    draw_circle(center, button_radius, fill)
    draw_arc(center, button_radius, 0.0, TAU, 34, Color(0.9, 0.95, 1.0, 0.44), 2.0, true)
    draw_string(
        ThemeDB.fallback_font,
        center + Vector2(-button_radius, 5.0),
        label,
        HORIZONTAL_ALIGNMENT_CENTER,
        button_radius * 2.0,
        13,
        text_color
    )
