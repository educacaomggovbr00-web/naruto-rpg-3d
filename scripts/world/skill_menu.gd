extends CanvasLayer

signal closed

var panel: PanelContainer
var points_label: Label
var skill_rows: Dictionary = {}

func _ready() -> void:
    layer = 65
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    visible = false
    GameFlow.progress_changed.connect(_refresh)

func _panel_style(background: Color, border: Color, radius: int = 16) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(radius)
    return style

func _build() -> void:
    var shade: ColorRect = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.01, 0.02, 0.035, 0.76)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(shade)

    panel = PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-310, -245)
    panel.size = Vector2(620, 490)
    panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.015, 0.045, 0.065, 0.98), Color(0.82, 0.48, 0.18, 0.86))
    )
    add_child(panel)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)

    var title: Label = Label.new()
    title.text = "TREINO NINJA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("ffd089"))
    box.add_child(title)

    points_label = Label.new()
    points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    points_label.add_theme_font_size_override("font_size", 17)
    points_label.add_theme_color_override("font_color", Color("e8f0ef"))
    box.add_child(points_label)

    for skill_id: String in GameFlow.SKILL_IDS:
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        box.add_child(row)

        var info: Label = Label.new()
        info.custom_minimum_size = Vector2(390, 58)
        info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        info.add_theme_font_size_override("font_size", 17)
        row.add_child(info)

        var button: Button = Button.new()
        button.text = "MELHORAR"
        button.custom_minimum_size = Vector2(170, 54)
        button.add_theme_font_size_override("font_size", 15)
        button.pressed.connect(_upgrade.bind(skill_id))
        row.add_child(button)

        skill_rows[skill_id] = {"label": info, "button": button}

    var close_button: Button = Button.new()
    close_button.text = "VOLTAR"
    close_button.custom_minimum_size = Vector2(240, 54)
    close_button.add_theme_font_size_override("font_size", 16)
    close_button.pressed.connect(close)
    box.add_child(close_button)

func open() -> void:
    GameFlow.ensure_rpg_progress()
    visible = true
    _refresh()

func close() -> void:
    if not visible:
        return
    visible = false
    closed.emit()

func _upgrade(skill_id: String) -> void:
    GameFlow.upgrade_skill(skill_id)
    _refresh()

func _refresh() -> void:
    if points_label == null:
        return
    GameFlow.ensure_rpg_progress()
    points_label.text = "Nível %d • %s • Pontos disponíveis: %d" % [
        int(GameFlow.progress.level),
        GameFlow.ninja_rank(),
        int(GameFlow.progress.skill_points)
    ]
    for skill_id: String in GameFlow.SKILL_IDS:
        if not skill_rows.has(skill_id):
            continue
        var row: Dictionary = skill_rows[skill_id]
        var rank: int = GameFlow.skill_rank(skill_id)
        var label: Label = row.label as Label
        var button: Button = row.button as Button
        label.text = "%s  %d/%d\n%s" % [
            GameFlow.skill_label(skill_id),
            rank,
            GameFlow.MAX_SKILL_RANK,
            GameFlow.skill_bonus_text(skill_id)
        ]
        button.disabled = rank >= GameFlow.MAX_SKILL_RANK or int(GameFlow.progress.skill_points) <= 0
        button.text = "MÁXIMO" if rank >= GameFlow.MAX_SKILL_RANK else "MELHORAR (1)"

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if (
        event.is_action_pressed("ui_cancel")
        or (
            event is InputEventKey
            and event.pressed
            and not event.echo
            and event.physical_keycode in [KEY_ESCAPE, KEY_M]
        )
    ):
        close()
        get_viewport().set_input_as_handled()
