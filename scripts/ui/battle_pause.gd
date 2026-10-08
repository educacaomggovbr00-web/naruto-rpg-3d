extends CanvasLayer

var overlay: Control = null
var resume_button: Button = null

func _ready() -> void:
    layer = 70
    process_mode = Node.PROCESS_MODE_ALWAYS
    var button: Button = Button.new()
    button.text = "PAUSA"
    button.position = Vector2(950, 12)
    button.custom_minimum_size = Vector2(86, 46)
    button.pressed.connect(pause_battle)
    add_child(button)

func _input(event: InputEvent) -> void:
    var escape: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE
    if escape or event.is_action_pressed("pad_pause"):
        if overlay != null:
            resume_battle()
        else:
            pause_battle()
        get_viewport().set_input_as_handled()

func pause_battle() -> void:
    if overlay != null or GameFlow.battle_finished or GameFlow.busy:
        return
    overlay = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(overlay)
    var shade: ColorRect = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.015, 0.025, 0.045, 0.9)
    overlay.add_child(shade)
    var column: VBoxContainer = VBoxContainer.new()
    column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    column.position = Vector2(-260, -170)
    column.size = Vector2(520, 340)
    column.add_theme_constant_override("separation", 12)
    overlay.add_child(column)
    var title: Label = Label.new()
    title.text = "BATALHA PAUSADA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    column.add_child(title)
    for text: String in ["CONTINUAR", "CONTROLES E CÂMERA", "SELEÇÃO"]:
        var button: Button = Button.new()
        button.text = text
        button.custom_minimum_size = Vector2(520, 62)
        column.add_child(button)
        if text == "CONTINUAR":
            button.pressed.connect(resume_battle)
            resume_button = button
        elif text == "SELEÇÃO":
            button.pressed.connect(GameFlow.enter_selection)
        else:
            button.pressed.connect(_preferences)
    var hints: Label = Label.new()
    hints.text = "AGARRÃO: NINJA → AGARR / G / LB + X\nDefenda no início do impacto para abrir um contra-ataque.\nCombo aéreo: direcional cima + ATK → DASH → ATK"
    hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hints.add_theme_font_size_override("font_size", 15)
    column.add_child(hints)
    var battle: Node = get_parent().get_parent()
    var controls: Node = battle.get_node("HUD/MobileControls")
    controls.call("_notification", NOTIFICATION_APPLICATION_FOCUS_OUT)
    var fighter: Node = battle.get_node("Player")
    fighter.jump_requested = false
    fighter.jump_buffer = 0.0
    fighter.attack_buffer = 0.0
    fighter.is_guarding = false
    fighter.is_charging_chakra = false
    var audio: Node = battle.get_node_or_null("AudioManager")
    if audio != null:
        audio.call("stop_all")
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    resume_button.grab_focus()

func resume_battle() -> void:
    if overlay == null:
        return
    overlay.queue_free()
    overlay = null
    get_tree().paused = false
    if not OS.has_feature("mobile") and Input.get_connected_joypads().is_empty():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _preferences() -> void:
    var popup: AcceptDialog = AcceptDialog.new()
    popup.set_script(preload("res://scripts/ui/preferences_dialog.gd"))
    overlay.add_child(popup)
    popup.popup_centered()

func _notification(what: int) -> void:
    if is_inside_tree() and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_GO_BACK_REQUEST]:
        pause_battle()

func _exit_tree() -> void:
    if overlay != null:
        get_tree().paused = false
