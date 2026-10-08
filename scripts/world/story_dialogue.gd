extends CanvasLayer

signal finished

var lines: Array = []
var index: int = 0
var active: bool = false
var progress_label: Label
var portrait: TextureRect
var title_label: Label
var speaker_label: Label
var body_label: Label
var next_button: Button
var shade: ColorRect
var choice_box: HBoxContainer
var choice_pending: bool = false
var panel: PanelContainer

func _ready() -> void:
    layer = 70
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    visible = false

func _build() -> void:
    shade = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.01, 0.02, 0.035, 0.46)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(shade)

    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_left = 54
    panel.offset_right = -54
    panel.offset_top = -260
    panel.offset_bottom = -24
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.015, 0.045, 0.065, 0.96)
    style.border_color = Color(0.82, 0.48, 0.18, 0.82)
    style.set_border_width_all(2)
    style.set_corner_radius_all(16)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)

    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 15)
    title_label.add_theme_color_override("font_color", Color("d6e4e8"))
    box.add_child(title_label)

    speaker_label = Label.new()
    speaker_label.add_theme_font_size_override("font_size", 24)
    speaker_label.add_theme_color_override("font_color", Color("ffd089"))
    var speaker_row = HBoxContainer.new()
    box.add_child(speaker_row)
    portrait = TextureRect.new()
    portrait.custom_minimum_size = Vector2(42,42)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    speaker_row.add_child(portrait)
    speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    speaker_row.add_child(speaker_label)
    progress_label = Label.new()
    progress_label.add_theme_font_size_override("font_size",14)
    speaker_row.add_child(progress_label)

    body_label = Label.new()
    body_label.custom_minimum_size = Vector2(0, 66)
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 18)
    body_label.add_theme_color_override("font_color", Color("fff4df"))
    box.add_child(body_label)

    choice_box = HBoxContainer.new()
    box.add_child(choice_box)
    next_button = Button.new()
    next_button.text = "CONTINUAR"
    next_button.custom_minimum_size = Vector2(190, 44)
    next_button.pressed.connect(advance)
    box.add_child(next_button)

func play(dialogue_lines: Array, title: String = "HISTÓRIA") -> bool:
    if dialogue_lines.is_empty():
        return false
    lines = dialogue_lines.duplicate(true)
    index = 0
    active = true
    title_label.text = title
    visible = true
    get_tree().paused = true
    _show_line()
    return true

func advance() -> void:
    if not active or choice_pending:
        return
    index += 1
    if index >= lines.size():
        close()
        return
    _show_line()

func close() -> void:
    if not active:
        return
    active = false
    visible = false
    get_tree().paused = false
    finished.emit()

func _show_line() -> void:
    if index < 0 or index >= lines.size():
        close()
        return
    choice_pending = false
    next_button.visible = true
    for child: Node in choice_box.get_children():
        choice_box.remove_child(child)
        child.queue_free()
    var entry: Variant = lines[index]
    if not entry is Dictionary:
        speaker_label.text = ""
        body_label.text = String(entry)
    else:
        var line: Dictionary = entry
        speaker_label.text = String(line.get("speaker", ""))
        body_label.text = String(line.get("text", ""))
        var selected: String = ""
        var mission: Dictionary = GameFlow.current_story_mission()
        if GameFlow.campaign_id == "henrique" and not mission.is_empty():
            selected = String(GameFlow.progress.henrique_choices.get(String(mission.id), ""))
        for option: Dictionary in line.get("choices", []):
            if not selected.is_empty():
                if selected == String(option.id):
                    body_label.text = String(option.reply)
                continue
            choice_pending = true
            next_button.visible = false
            var button: Button = Button.new()
            button.text = String(option.label)
            button.custom_minimum_size = Vector2(260, 44)
            button.pressed.connect(_choose.bind(option))
            choice_box.add_child(button)
        if choice_pending:
            choice_box.get_child(0).grab_focus()
    portrait.visible = false
    for definition in CharacterCatalog.READY:
        if speaker_label.text in [definition.display_name,definition.display_name.split(" ")[0]]:
            portrait.texture = load("res://assets/ui/portraits/"+definition.character_id+".png")
            portrait.visible = true
            break
    progress_label.text = "%d / %d" % [index+1,lines.size()]
    next_button.text = "FECHAR" if index == lines.size() - 1 else "CONTINUAR"

func _unhandled_input(event: InputEvent) -> void:
    if not active:
        return
    if event.is_action_pressed("ui_accept") or (
        event is InputEventKey
        and event.pressed
        and not event.echo
        and event.physical_keycode in [KEY_E, KEY_SPACE, KEY_ENTER]
    ):
        advance()
        get_viewport().set_input_as_handled()

func _choose(option: Dictionary) -> void:
    if not choice_pending or not GameFlow.record_story_choice(String(option.id)):
        return
    choice_pending = false
    body_label.text = String(option.reply)
    for child: Node in choice_box.get_children():
        child.queue_free()
    next_button.visible = true
    next_button.grab_focus()
