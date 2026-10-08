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
var advanced_open: bool = false
var advanced_toggle_center: Vector2 = Vector2.ZERO
var tool_select_queue: int = 0
var tool_use_queue: int = 0
var tool_select_center: Vector2 = Vector2.ZERO
var tool_use_center: Vector2 = Vector2.ZERO
var tool_label: String = "SHUR"
var ultimate_enabled: bool = true
var awakening_enabled: bool = true
var awakening_label: String = "AWK"
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
var character_accent: Color = Color(0.08, 0.55, 1.0)
var ui_scale: float = 1.0
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
var layout_editing: bool = false
var layout_touch: int = -1
var layout_key: String = ""
var layout_center: Vector2
var reset_layout_center: Vector2
var owns_pause: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(_update_layout)
    _update_layout()
    set_process_input(true)

func _update_layout() -> void:
    var w: float = size.x
    var h: float = size.y
    ui_scale = clampf(h / 720.0, 0.78, 1.12)

    joystick_radius = 92.0 * ui_scale
    attack_radius = 62.0 * ui_scale
    jump_radius = 44.0 * ui_scale
    dash_radius = 48.0 * ui_scale
    lock_radius = 42.0 * ui_scale
    jutsu_radius = 50.0 * ui_scale
    substitution_radius = 43.0 * ui_scale
    dodge_radius = 43.0 * ui_scale
    charge_radius = 46.0 * ui_scale
    guard_radius = 40.0 * ui_scale
    advanced_radius = 34.0 * ui_scale

    joystick_center = Vector2(145.0 * ui_scale, h - 140.0 * ui_scale)
    if joystick_touch == -1:
        joystick_knob = joystick_center

    attack_center = Vector2(w - 98.0 * ui_scale, h - 102.0 * ui_scale)
    jump_center = Vector2(w - 98.0 * ui_scale, h - 225.0 * ui_scale)
    jutsu_center = Vector2(w - 222.0 * ui_scale, h - 105.0 * ui_scale)
    dash_center = Vector2(w - 222.0 * ui_scale, h - 225.0 * ui_scale)
    dodge_center = Vector2(w - 338.0 * ui_scale, h - 100.0 * ui_scale)
    substitution_center = Vector2(w - 338.0 * ui_scale, h - 190.0 * ui_scale)
    charge_center = Vector2(w - 444.0 * ui_scale, h - 100.0 * ui_scale)
    guard_center = Vector2(w - 444.0 * ui_scale, h - 190.0 * ui_scale)
    quality_center = Vector2(w - 190.0 * ui_scale, 72.0 * ui_scale)
    advanced_toggle_center = Vector2(w - 310.0 * ui_scale, 72.0 * ui_scale)
    lock_center = Vector2(w - 72.0 * ui_scale, 72.0 * ui_scale)

    var advanced_y: float = minf(150.0 * ui_scale, h * 0.29)
    if clones_enabled:
        tool_select_center = Vector2(w - 690.0 * ui_scale, advanced_y)
        tool_use_center = Vector2(w - 610.0 * ui_scale, advanced_y)
        special_center = Vector2(w - 530.0 * ui_scale, advanced_y)
        clone_center = Vector2(w - 450.0 * ui_scale, advanced_y)
        barrage_center = Vector2(w - 370.0 * ui_scale, advanced_y)
        ultimate_center = Vector2(w - 290.0 * ui_scale, advanced_y)
        awakening_center = Vector2(w - 210.0 * ui_scale, advanced_y)
    else:
        tool_select_center = Vector2(w - 530.0 * ui_scale, advanced_y)
        tool_use_center = Vector2(w - 450.0 * ui_scale, advanced_y)
        special_center = Vector2(w - 370.0 * ui_scale, advanced_y)
        ultimate_center = Vector2(w - 290.0 * ui_scale, advanced_y)
        awakening_center = Vector2(w - 210.0 * ui_scale, advanced_y)
        clone_center = Vector2(-1000.0, -1000.0)
        barrage_center = Vector2(-1000.0, -1000.0)

    layout_center = Vector2(w - 430.0 * ui_scale, 72.0 * ui_scale)
    reset_layout_center = Vector2(w - 550.0 * ui_scale, 72.0 * ui_scale)
    for key: String in CombatSettings.touch_layout:
        var point: Array = CombatSettings.touch_layout[key]
        var radius: float = float(get(key + "_radius"))
        set(key + "_center", Vector2(clampf(float(point[0]) * w, radius, maxf(radius, w - radius)), clampf(float(point[1]) * h, 170.0 * ui_scale, maxf(170.0 * ui_scale, h - radius))))
    if joystick_touch == -1:
        joystick_knob = joystick_center
    queue_redraw()

func _input(event: InputEvent) -> void:
    if not layout_editing and event is InputEventScreenTouch and event.pressed and _expansion_overlay_contains(event.position):
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_pressed(event.index, event.position)
        else:
            _touch_released(event.index)
    elif event is InputEventScreenDrag:
        _touch_dragged(event.index, event.position)

func _expansion_overlay_contains(point: Vector2) -> bool:
    var arena: Node = get_parent().get_parent()
    var overlay: Node = arena.get_node_or_null("TeamHUD")
    if overlay != null and overlay.panel.is_visible_in_tree() and overlay.panel.get_global_rect().has_point(point):
        return true
    var coach: Node = arena.get_node_or_null("BattleBridge/TrainingCoach")
    if coach != null:
        for control: Control in [coach.panel, coach.toggle]:
            if control.is_visible_in_tree() and control.get_global_rect().has_point(point):
                return true
    var encounter: Node = arena.get_node_or_null("BattleBridge/BossEncounter")
    return encounter != null and encounter.panel.is_visible_in_tree() and encounter.panel.get_global_rect().has_point(point)

func _touch_pressed(touch_id: int, screen_position: Vector2) -> void:
    if _inside_circle(screen_position, layout_center, 43.0 * ui_scale):
        set_layout_editing(not layout_editing)
        return
    if layout_editing:
        if _inside_circle(screen_position, reset_layout_center, 43.0 * ui_scale):
            CombatSettings.touch_layout.clear()
            _update_layout()
            return
        if layout_touch == -1:
            for key: String in CombatSettings.TOUCH_KEYS:
                if _inside_circle(screen_position, get(key + "_center"), float(get(key + "_radius"))):
                    layout_touch = touch_id
                    layout_key = key
                    return
        return
    if _inside_circle(screen_position, quality_center, 43.0 * ui_scale):
        quality_queue += 1
        return
    if _inside_circle(screen_position, advanced_toggle_center, 43.0 * ui_scale):
        advanced_open = not advanced_open
        queue_redraw()
        return
    if advanced_open and _inside_circle(screen_position, tool_select_center, advanced_radius):
        tool_select_queue += 1
        return
    if advanced_open and _inside_circle(screen_position, tool_use_center, advanced_radius):
        tool_use_queue += 1
        return
    if advanced_open and _inside_circle(screen_position, ultimate_center, advanced_radius):
        if ultimate_enabled:
            ultimate_queue += 1
        return
    if advanced_open and _inside_circle(screen_position, awakening_center, advanced_radius):
        if awakening_enabled:
            awakening_queue += 1
        return
    if advanced_open and _inside_circle(screen_position, special_center, advanced_radius):
        if jutsu_enabled:
            special_queue += 1
        return
    if advanced_open and _inside_circle(screen_position, clone_center, advanced_radius):
        if clones_enabled:
            clone_queue += 1
        return
    if advanced_open and _inside_circle(screen_position, barrage_center, advanced_radius):
        if clones_enabled:
            barrage_queue += 1
        return
    if _inside_circle(screen_position, attack_center, attack_radius):
        attack_queue += 1
        return
    if _inside_circle(screen_position, jump_center, jump_radius):
        jump_queue += 1
        return
    if _inside_circle(screen_position, dash_center, dash_radius):
        chakra_dash_queue += 1
        return
    if _inside_circle(screen_position, lock_center, lock_radius):
        lock_queue += 1
        return
    if _inside_circle(screen_position, jutsu_center, jutsu_radius):
        if jutsu_enabled:
            jutsu_queue += 1
        return
    if _inside_circle(screen_position, substitution_center, substitution_radius):
        substitution_queue += 1
        return
    if _inside_circle(screen_position, dodge_center, dodge_radius):
        dodge_queue += 1
        return
    if _inside_circle(screen_position, charge_center, charge_radius) and charge_touch == -1:
        charge_touch = touch_id
        queue_redraw()
        return
    if _inside_circle(screen_position, guard_center, guard_radius) and guard_touch == -1:
        guard_touch = touch_id
        queue_redraw()
        return

    if joystick_touch == -1 and screen_position.x < size.x * 0.40 and screen_position.y > size.y * 0.40:
        joystick_touch = touch_id
        _update_joystick(screen_position)
        return

    if camera_touch == -1 and screen_position.x >= size.x * 0.38:
        camera_touch = touch_id
        camera_last_position = screen_position

func _touch_released(touch_id: int) -> void:
    if touch_id == layout_touch:
        layout_touch = -1
        layout_key = ""
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

func _touch_dragged(touch_id: int, screen_position: Vector2) -> void:
    if layout_editing:
        if touch_id == layout_touch and not layout_key.is_empty():
            var radius: float = float(get(layout_key + "_radius"))
            var point: Vector2 = Vector2(clampf(screen_position.x, radius, maxf(radius, size.x - radius)), clampf(screen_position.y, 170.0 * ui_scale, maxf(170.0 * ui_scale, size.y - radius)))
            set(layout_key + "_center", point)
            CombatSettings.touch_layout[layout_key] = [point.x / maxf(size.x, 1.0), point.y / maxf(size.y, 1.0)]
            joystick_knob = joystick_center
            queue_redraw()
        return
    if touch_id == joystick_touch:
        _update_joystick(screen_position)
        return

    if touch_id == camera_touch:
        camera_delta += screen_position - camera_last_position
        camera_last_position = screen_position

func _update_joystick(screen_position: Vector2) -> void:
    var offset: Vector2 = screen_position - joystick_center
    if offset.length() > joystick_radius:
        offset = offset.normalized() * joystick_radius

    joystick_knob = joystick_center + offset
    move_vector = offset / joystick_radius

    move_vector = CombatSettings.touch_movement(move_vector)

    queue_redraw()

func _inside_circle(screen_position: Vector2, center: Vector2, radius: float) -> bool:
    return screen_position.distance_squared_to(center) <= radius * radius

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
    var blue_fill: Color = Color(character_accent.r, character_accent.g, character_accent.b, 0.58)
    var attack_fill: Color = Color(0.90, 0.29, 0.10, 0.64)
    var jutsu_color: Color = character_accent.lerp(Color(0.60, 0.24, 0.88), 0.34)
    var jutsu_fill: Color = Color(jutsu_color.r, jutsu_color.g, jutsu_color.b, 0.62)
    var defense_fill: Color = Color(0.06, 0.52, 0.46, 0.58)
    var text_color: Color = Color(1.0, 1.0, 1.0, 0.94)

    draw_circle(joystick_center, joystick_radius, base_fill)
    draw_arc(joystick_center, joystick_radius, 0.0, TAU, 48, base_line, 3.0, true)
    draw_circle(joystick_knob, 38.0, Color(1.0, 1.0, 1.0, 0.34))

    _draw_button(layout_center, advanced_radius, blue_fill, "SALVAR" if layout_editing else "AJUSTAR", 9, text_color)
    if layout_editing:
        _draw_button(reset_layout_center, advanced_radius, attack_fill, "RESET", 9, text_color)
        draw_string(ThemeDB.fallback_font, Vector2(28, 150 * ui_scale), "Arraste os controles. SALVAR retorna à luta.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, text_color)
    _draw_button(quality_center, advanced_radius, base_fill, quality_label, maxi(10, int(12.0 * ui_scale)), text_color)
    _draw_button(advanced_toggle_center, advanced_radius, blue_fill if advanced_open else base_fill, "NINJA", 9, text_color)
    if advanced_open:
        _draw_button(tool_select_center, advanced_radius, base_fill, "ITEM", 11, text_color)
        _draw_button(tool_use_center, advanced_radius, blue_fill, tool_label, 10, text_color)
        _draw_button(ultimate_center, advanced_radius, jutsu_fill if ultimate_enabled else Color(0.2, 0.2, 0.2, 0.30), "ULT" if ultimate_enabled else "—", 12, text_color)
        _draw_button(awakening_center, advanced_radius, attack_fill if awakening_enabled else Color(0.2, 0.2, 0.2, 0.30), awakening_label if awakening_enabled else "—", 12, text_color)
        _draw_button(special_center, advanced_radius, blue_fill, special_label, 11, text_color)
        if clones_enabled:
            _draw_button(clone_center, advanced_radius, blue_fill, "CLONE", 10, text_color)
            _draw_button(barrage_center, advanced_radius, attack_fill, "BARR", 11, text_color)
    _draw_button(attack_center, attack_radius, attack_fill, "ATK", 25, text_color)
    _draw_button(jutsu_center, jutsu_radius, jutsu_fill, "JUTSU", 16, text_color)
    _draw_button(dash_center, dash_radius, blue_fill, "DASH", 17, text_color)
    _draw_button(jump_center, jump_radius, base_fill, "PULO", 16, text_color)
    _draw_button(dodge_center, dodge_radius, base_fill, "ESQ", 16, text_color)
    _draw_button(substitution_center, substitution_radius, defense_fill, "SUB", 16, text_color)
    _draw_button(charge_center, charge_radius, blue_fill, "CHK", 16, text_color)
    _draw_button(guard_center, guard_radius, defense_fill, "DEF", 16, text_color)
    _draw_button(lock_center, advanced_radius, base_fill, "LOCK", maxi(10, int(12.0 * ui_scale)), text_color)

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
    layout_touch = -1
    layout_key = ""
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
    character_accent = definition.energy_color
    advanced_open = false
    jutsu_enabled = not definition.jutsus.is_empty()
    ultimate_enabled = definition.has_ultimate
    awakening_enabled = definition.has_awakening
    clones_enabled = "clones" in definition.jutsus
    if definition.jutsus.is_empty():
        special_label = "—"
    else:
        var first_id: String = String(definition.jutsus[0])
        var known_labels: Dictionary = {
            "rasengan": "RAS",
            "demon": "DWB",
            "fireball": "FIRE",
            "chidori": "CHID",
            "raikiri": "RAI",
            "booby_trap": "TRAP",
            "clones": "CLONE",
            "whirlwind": "AIR",
            "barrage": "BARR"
        }
        var compact_id: String = first_id.replace("_", "").to_upper()
        var fallback_label: String = compact_id.substr(0, mini(compact_id.length(), 5))
        special_label = String(known_labels.get(first_id, fallback_label))
    _update_layout()
    queue_redraw()

func set_layout_editing(enabled: bool) -> void:
    layout_editing = enabled
    layout_touch = -1
    layout_key = ""
    _notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
    if enabled:
        owns_pause = not get_tree().paused
        get_tree().paused = true
    else:
        CombatSettings.save_preferences()
        if owns_pause:
            get_tree().paused = false
        owns_pause = false
    queue_redraw()

func _exit_tree() -> void:
    if owns_pause:
        get_tree().paused = false

func reset_interaction() -> void:
    for touch_id: int in [joystick_touch,camera_touch,charge_touch,guard_touch,layout_touch]:
        _touch_released(touch_id)
    for key: String in ["attack_queue","jump_queue","chakra_dash_queue","lock_queue","jutsu_queue","substitution_queue","dodge_queue","ultimate_queue","awakening_queue","special_queue","clone_queue","barrage_queue","tool_select_queue","tool_use_queue","quality_queue"]:
        set(key,0)
    camera_delta = Vector2.ZERO
    move_vector = Vector2.ZERO
