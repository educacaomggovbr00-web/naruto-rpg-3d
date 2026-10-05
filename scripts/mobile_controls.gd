extends Control

@export var joystick_radius: float = 92.0
@export var joystick_deadzone: float = 0.12

var move_vector: Vector2 = Vector2.ZERO
var joystick_touch: int = -1
var camera_touch: int = -1
var charge_touch: int = -1
var guard_touch: int = -1

var camera_last_position: Vector2 = Vector2.ZERO
var camera_delta: Vector2 = Vector2.ZERO

var quality_queue: int = 0
var quality_center: Vector2 = Vector2.ZERO
var quality_label: String = "MED"
var tool_select_queue: int = 0
var tool_use_queue: int = 0
var tool_select_center: Vector2 = Vector2.ZERO
var tool_use_center: Vector2 = Vector2.ZERO
var tool_label: String = "SHUR"
var ultimate_enabled: bool = true
var awakening_enabled: bool = true
var clones_enabled: bool = true
var ultimate_queue: int = 0
var awakening_queue: int = 0
var ultimate_center: Vector2 = Vector2.ZERO
var awakening_center: Vector2 = Vector2.ZERO
var special_queue: int = 0
var clone_queue: int = 0
var barrage_queue: int = 0
var special_center: Vector2 = Vector2.ZERO
var clone_center: Vector2 = Vector2.ZERO
var barrage_center: Vector2 = Vector2.ZERO
var special_label: String = "DWB"
var jutsu_enabled: bool = true
var attack_queue: int = 0
var jump_queue: int = 0
var chakra_dash_queue: int = 0
var lock_queue: int = 0
var jutsu_queue: int = 0
var substitution_queue: int = 0
var dodge_queue: int = 0

var joystick_center: Vector2 = Vector2.ZERO
var joystick_knob: Vector2 = Vector2.ZERO
var attack_center: Vector2 = Vector2.ZERO
var jump_center: Vector2 = Vector2.ZERO
var dash_center: Vector2 = Vector2.ZERO
var lock_center: Vector2 = Vector2.ZERO
var jutsu_center: Vector2 = Vector2.ZERO
var substitution_center: Vector2 = Vector2.ZERO
var dodge_center: Vector2 = Vector2.ZERO
var charge_center: Vector2 = Vector2.ZERO
var guard_center: Vector2 = Vector2.ZERO

var attack_radius: float = 62.0
var jump_radius: float = 44.0
var dash_radius: float = 48.0
var lock_radius: float = 42.0
var jutsu_radius: float = 50.0
var substitution_radius: float = 43.0
var dodge_radius: float = 43.0
var charge_radius: float = 46.0
var guard_radius: float = 40.0
var advanced_radius: float = 34.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(_update_layout)
    _update_layout()
    set_process_input(true)

func _update_layout() -> void:
    var w: float = size.x
    var h: float = size.y

    joystick_center = Vector2(145.0, h - 140.0)
    if joystick_touch == -1:
        joystick_knob = joystick_center

    attack_center = Vector2(w - 98.0, h - 102.0)
    jump_center = Vector2(w - 98.0, h - 225.0)
    jutsu_center = Vector2(w - 222.0, h - 105.0)
    dash_center = Vector2(w - 222.0, h - 225.0)
    dodge_center = Vector2(w - 338.0, h - 100.0)
    substitution_center = Vector2(w - 338.0, h - 190.0)
    charge_center = Vector2(w - 444.0, h - 100.0)
    guard_center = Vector2(w - 444.0, h - 190.0)
    quality_center = Vector2(w - 190.0, 72.0)
    lock_center = Vector2(w - 72.0, 72.0)
    special_center = Vector2(w - 530.0, 150.0)
    clone_center = Vector2(w - 450.0, 150.0)
    barrage_center = Vector2(w - 370.0, 150.0)
    tool_select_center = Vector2(w - 690.0, 150.0)
    tool_use_center = Vector2(w - 610.0, 150.0)
    ultimate_center = Vector2(w - 290.0, 150.0)
    awakening_center = Vector2(w - 210.0, 150.0)

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
    if _inside_circle(position, quality_center, 43.0):
        quality_queue += 1
        return
    if _inside_circle(position, tool_select_center, advanced_radius):
        tool_select_queue += 1
        return
    if _inside_circle(position, tool_use_center, advanced_radius):
        tool_use_queue += 1
        return
    if _inside_circle(position, ultimate_center, advanced_radius):
        if ultimate_enabled:
            ultimate_queue += 1
        return
    if _inside_circle(position, awakening_center, advanced_radius):
        if awakening_enabled:
            awakening_queue += 1
        return
    if _inside_circle(position, special_center, advanced_radius):
        if jutsu_enabled:
            special_queue += 1
        return
    if _inside_circle(position, clone_center, advanced_radius):
        if clones_enabled:
            clone_queue += 1
        return
    if _inside_circle(position, barrage_center, advanced_radius):
        if clones_enabled:
            barrage_queue += 1
        return
    if _inside_circle(position, attack_center, attack_radius):
        attack_queue += 1
        return
    if _inside_circle(position, jump_center, jump_radius):
        jump_queue += 1
        return
    if _inside_circle(position, dash_center, dash_radius):
        chakra_dash_queue += 1
        return
    if _inside_circle(position, lock_center, lock_radius):
        lock_queue += 1
        return
    if _inside_circle(position, jutsu_center, jutsu_radius):
        if jutsu_enabled:
            jutsu_queue += 1
        return
    if _inside_circle(position, substitution_center, substitution_radius):
        substitution_queue += 1
        return
    if _inside_circle(position, dodge_center, dodge_radius):
        dodge_queue += 1
        return
    if _inside_circle(position, charge_center, charge_radius) and charge_touch == -1:
        charge_touch = touch_id
        queue_redraw()
        return
    if _inside_circle(position, guard_center, guard_radius) and guard_touch == -1:
        guard_touch = touch_id
        queue_redraw()
        return

    if joystick_touch == -1 and position.x < size.x * 0.40 and position.y > size.y * 0.40:
        joystick_touch = touch_id
        _update_joystick(position)
        return

    if camera_touch == -1 and position.x >= size.x * 0.38:
        camera_touch = touch_id
        camera_last_position = position

func _touch_released(touch_id: int) -> void:
    if touch_id == joystick_touch:
        joystick_touch = -1
        move_vector = Vector2.ZERO
        joystick_knob = joystick_center

    if touch_id == camera_touch:
        camera_touch = -1
        camera_delta = Vector2.ZERO

    if touch_id == charge_touch:
        charge_touch = -1

    if touch_id == guard_touch:
        guard_touch = -1

    queue_redraw()

func _touch_dragged(touch_id: int, position: Vector2) -> void:
    if touch_id == joystick_touch:
        _update_joystick(position)
        return

    if touch_id == camera_touch:
        camera_delta += position - camera_last_position
        camera_last_position = position

func _update_joystick(position: Vector2) -> void:
    var offset: Vector2 = position - joystick_center
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

func is_charge_held() -> bool:
    return charge_touch != -1

func is_guard_held() -> bool:
    return guard_touch != -1

func consume_camera_delta() -> Vector2:
    var result: Vector2 = camera_delta
    camera_delta = Vector2.ZERO
    return result

func consume_attack() -> bool:
    return _consume_queue("attack")

func consume_jump() -> bool:
    return _consume_queue("jump")

func consume_chakra_dash() -> bool:
    return _consume_queue("dash")

func consume_lock() -> bool:
    return _consume_queue("lock")

func consume_jutsu() -> bool:
    return _consume_queue("jutsu")

func consume_substitution() -> bool:
    return _consume_queue("substitution")

func consume_dodge() -> bool:
    return _consume_queue("dodge")

func _consume_queue(queue_name: String) -> bool:
    match queue_name:
        "attack":
            if attack_queue > 0:
                attack_queue -= 1
                return true
        "jump":
            if jump_queue > 0:
                jump_queue -= 1
                return true
        "dash":
            if chakra_dash_queue > 0:
                chakra_dash_queue -= 1
                return true
        "lock":
            if lock_queue > 0:
                lock_queue -= 1
                return true
        "jutsu":
            if jutsu_queue > 0:
                jutsu_queue -= 1
                return true
        "substitution":
            if substitution_queue > 0:
                substitution_queue -= 1
                return true
        "dodge":
            if dodge_queue > 0:
                dodge_queue -= 1
                return true

    return false

func _draw() -> void:
    var base_fill: Color = Color(0.015, 0.035, 0.055, 0.52)
    var base_line: Color = Color(0.82, 0.93, 0.98, 0.42)
    var blue_fill: Color = Color(0.05, 0.43, 0.70, 0.58)
    var attack_fill: Color = Color(0.90, 0.29, 0.10, 0.64)
    var jutsu_fill: Color = Color(0.38, 0.20, 0.76, 0.62)
    var defense_fill: Color = Color(0.06, 0.52, 0.46, 0.58)
    var text_color: Color = Color(1.0, 1.0, 1.0, 0.94)

    draw_circle(joystick_center, joystick_radius, base_fill)
    draw_arc(joystick_center, joystick_radius, 0.0, TAU, 48, base_line, 3.0, true)
    draw_circle(joystick_knob, 38.0, Color(1.0, 1.0, 1.0, 0.34))

    _draw_button(quality_center, 34.0, base_fill, quality_label, 12, text_color)
    _draw_button(tool_select_center, advanced_radius, base_fill, "ITEM", 11, text_color)
    _draw_button(tool_use_center, advanced_radius, blue_fill, tool_label, 10, text_color)
    _draw_button(ultimate_center, advanced_radius, jutsu_fill if ultimate_enabled else Color(0.2, 0.2, 0.2, 0.30), "ULT" if ultimate_enabled else "—", 12, text_color)
    _draw_button(awakening_center, advanced_radius, attack_fill if awakening_enabled else Color(0.2, 0.2, 0.2, 0.30), "AWK" if awakening_enabled else "—", 12, text_color)
    _draw_button(special_center, advanced_radius, blue_fill, special_label, 11, text_color)
    _draw_button(clone_center, advanced_radius, blue_fill if clones_enabled else Color(0.2, 0.2, 0.2, 0.30), "CLONE" if clones_enabled else "—", 10, text_color)
    _draw_button(barrage_center, advanced_radius, attack_fill if clones_enabled else Color(0.2, 0.2, 0.2, 0.30), "BARR" if clones_enabled else "—", 11, text_color)
    _draw_button(attack_center, attack_radius, attack_fill, "ATK", 25, text_color)
    _draw_button(jutsu_center, jutsu_radius, jutsu_fill, "JUTSU", 16, text_color)
    _draw_button(dash_center, dash_radius, blue_fill, "DASH", 17, text_color)
    _draw_button(jump_center, jump_radius, base_fill, "PULO", 16, text_color)
    _draw_button(dodge_center, dodge_radius, base_fill, "ESQ", 16, text_color)
    _draw_button(substitution_center, substitution_radius, defense_fill, "SUB", 16, text_color)
    _draw_button(charge_center, charge_radius, blue_fill, "CHK", 16, text_color)
    _draw_button(guard_center, guard_radius, defense_fill, "DEF", 16, text_color)
    _draw_button(lock_center, 34.0, base_fill, "LOCK", 12, text_color)

    if charge_touch != -1:
        draw_arc(charge_center, charge_radius + 7.0, 0.0, TAU, 40, text_color, 4.0, true)
    if guard_touch != -1:
        draw_arc(guard_center, guard_radius + 7.0, 0.0, TAU, 40, text_color, 4.0, true)

func _draw_button(center: Vector2, radius: float, fill: Color, label: String, font_size: int, text_color: Color) -> void:
    draw_circle(center, radius, fill)
    draw_arc(center, radius, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.48), 3.0, true)

    var width: float = radius * 1.8
    var baseline: Vector2 = center + Vector2(-width * 0.5, float(font_size) * 0.34)
    draw_string(
        ThemeDB.fallback_font,
        baseline,
        label,
        HORIZONTAL_ALIGNMENT_CENTER,
        width,
        font_size,
        text_color
    )

func _notification(what: int) -> void:
    if what not in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
        return
    joystick_touch = -1
    camera_touch = -1
    charge_touch = -1
    guard_touch = -1
    move_vector = Vector2.ZERO
    camera_delta = Vector2.ZERO
    joystick_knob = joystick_center
    attack_queue = 0
    jump_queue = 0
    chakra_dash_queue = 0
    lock_queue = 0
    jutsu_queue = 0
    substitution_queue = 0
    dodge_queue = 0
    special_queue = 0
    clone_queue = 0
    barrage_queue = 0
    ultimate_queue = 0
    awakening_queue = 0
    tool_select_queue = 0
    tool_use_queue = 0
    quality_queue = 0
    queue_redraw()

func configure_character(definition: CharacterDefinition) -> void:
    jutsu_enabled = not definition.jutsus.is_empty()
    ultimate_enabled = definition.has_ultimate
    awakening_enabled = definition.has_awakening
    clones_enabled = "clones" in definition.jutsus
    if definition.jutsus.is_empty():
        special_label = "—"
    else:
        var compact_id: String = String(definition.jutsus[0]).replace("_", "").to_upper()
        special_label = compact_id.substr(0, mini(compact_id.length(), 5))
    queue_redraw()
