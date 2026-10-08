extends CanvasLayer
## Always-processing UI owns only the pause it opened. No combat cancel or save reset.
var overlay: Control
var panel: PanelContainer
var summary: Label
var owns_pause: bool = false
var previous_mouse_mode: Input.MouseMode
var continue_button: Button
var pause_button: Button
func _ready() -> void:
    layer = 80
    process_mode = Node.PROCESS_MODE_ALWAYS
    pause_button = Button.new()
    pause_button.text = "PAUSA"
    pause_button.position = Vector2(958,8)
    pause_button.custom_minimum_size = Vector2(82,30)
    pause_button.pressed.connect(toggle)
    add_child(pause_button)
    overlay = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(overlay)
    var backdrop: ColorRect = ColorRect.new()
    backdrop.color = Color(.01,.025,.04,.87)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(backdrop)
    var center: CenterContainer = CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center)
    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(500,0)
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("0c2433")
    style.border_color = Color("6ab7c8")
    style.set_border_width_all(2)
    style.set_corner_radius_all(16)
    style.content_margin_left = 22
    style.content_margin_right = 22
    style.content_margin_top = 16
    style.content_margin_bottom = 16
    panel.add_theme_stylebox_override("panel",style)
    center.add_child(panel)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation",8)
    panel.add_child(column)
    var title: Label = Label.new()
    title.text = "SHINOBI CLASH • PAUSA"
    title.add_theme_font_size_override("font_size",24)
    title.add_theme_color_override("font_color",Color("ffd07a"))
    column.add_child(title)
    summary = Label.new()
    summary.add_theme_font_size_override("font_size",14)
    column.add_child(summary)
    preload("res://scripts/camera_preferences_ui.gd").build(column)
    var volume: HSlider = HSlider.new()
    var label: Label = Label.new()
    label.text = "Volume geral"
    column.add_child(label)
    volume.max_value = 1.0
    volume.step = .05
    volume.value = CombatSettings.master_volume
    volume.custom_minimum_size.y = 32
    volume.value_changed.connect(func(value: float) -> void:
        CombatSettings.master_volume = value
        CombatSettings.apply_audio()
        CombatSettings.save_preferences())
    column.add_child(volume)
    continue_button = _button(column,"CONTINUAR",resume)
    _button(column,"REINICIAR BATALHA",func() -> void:
        resume()
        GameFlow.retry_battle())
    _button(column,"SELEÇÃO DE PERSONAGENS",func() -> void:
        resume()
        GameFlow.enter_selection())
    overlay.visible = false
func _input(event: InputEvent) -> void:
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START and Input.is_action_pressed("pad_guard"):
        toggle()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE,KEY_P]:
        toggle()
        get_viewport().set_input_as_handled()
func _button(column: VBoxContainer, text: String, callback: Callable) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.custom_minimum_size.y = 40
    button.pressed.connect(callback)
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("195264")
    style.border_color = Color("498696")
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    button.add_theme_stylebox_override("normal",style)
    var hover: StyleBoxFlat = style.duplicate()
    hover.bg_color = Color("24687d")
    button.add_theme_stylebox_override("hover",hover)
    var focus: StyleBoxFlat = style.duplicate()
    focus.border_color = Color("ffd07a")
    focus.set_border_width_all(2)
    button.add_theme_stylebox_override("focus",focus)
    column.add_child(button)
    return button
func toggle() -> void:
    if owns_pause:
        resume()
        return
    if GameFlow.busy or GameFlow.battle_finished or get_tree().paused: return
    previous_mouse_mode = Input.mouse_mode
    var controls: Node = get_parent().get_node_or_null("HUD/MobileControls")
    if controls != null: controls.reset_interaction()
    summary.text = get_parent().get_node("BattleMetrics").summary()
    continue_button.grab_focus()
    owns_pause = true
    overlay.visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func resume() -> void:
    if not owns_pause: return
    owns_pause = false
    overlay.visible = false
    get_tree().paused = false
    Input.mouse_mode = previous_mouse_mode
func _exit_tree() -> void:
    if owns_pause: get_tree().paused = false
