extends CanvasLayer

signal finished

var lines: Array = []
var index: int = 0
var active: bool = false
var title_label: Label
var speaker_label: Label
var body_label: Label
var next_button: Button
var shade: ColorRect
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
    panel.offset_top = -218
    panel.offset_bottom = -24
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.015, 0.045, 0.065, 0.96)
    style.border_color = Color(0.82, 0.48, 0.18, 0.82)
    style.set_border_width_all(2)
    style.set_corner_radius_all(16)
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
    box.add_child(speaker_label)

    body_label = Label.new()
    body_label.custom_minimum_size = Vector2(0, 66)
    body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body_label.add_theme_font_size_override("font_size", 18)
    body_label.add_theme_color_override("font_color", Color("fff4df"))
    box.add_child(body_label)

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
    if not active:
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
    var entry: Variant = lines[index]
    if not entry is Dictionary:
        speaker_label.text = ""
        body_label.text = String(entry)
    else:
        var line: Dictionary = entry
        speaker_label.text = String(line.get("speaker", ""))
        body_label.text = String(line.get("text", ""))
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
