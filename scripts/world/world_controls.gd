extends Control
## Independent exploration touch surface: no hidden combat hit areas.
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
    _layout()

func _layout() -> void:
    radius = clampf(size.y * 0.13, 52.0, 92.0)
    button_radius = clampf(size.y * 0.072, 32.0, 50.0)
    joystick_center = Vector2(radius + 40, size.y - radius - 35)
    sprint_center = Vector2(size.x - button_radius - 28, size.y - button_radius - 32)
    jump_center = sprint_center + Vector2(-button_radius * 2.3, -button_radius * 0.4)
    interact_center = sprint_center + Vector2(-button_radius * 0.1, -button_radius * 2.5)
    map_center = Vector2(size.x - button_radius - 28, button_radius + 25)
    queue_redraw()

func _inside(point: Vector2, center: Vector2, reach: float) -> bool:
    return point.distance_squared_to(center) <= reach * reach

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if joystick_touch == -1 and _inside(event.position, joystick_center, radius * 1.3):
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
            elif event.position.y < 110.0:
                # Let header Buttons receive GUI touch before reserving a camera finger.
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
    var fill: Color = Color(0.04, 0.09, 0.10, 0.65)
    draw_circle(joystick_center, radius, fill)
    draw_arc(joystick_center, radius, 0, TAU, 36, Color("dccdb2"), 2.0, true)
    draw_circle(joystick_center + move_vector * radius, radius * 0.4, Color(0.9, 0.85, 0.7, 0.7))
    for entry: Array in [[jump_center, "PULO"], [sprint_center, "CORRER"], [interact_center, context_label], [map_center, "MAPA"]]:
        var center: Vector2 = entry[0]
        draw_circle(center, button_radius, fill)
        draw_arc(center, button_radius, 0, TAU, 36, Color("dccdb2"), 2.0, true)
        draw_string(ThemeDB.fallback_font, center + Vector2(-button_radius, 6), entry[1], HORIZONTAL_ALIGNMENT_CENTER, button_radius * 2, 14, Color("fff2d5"))
