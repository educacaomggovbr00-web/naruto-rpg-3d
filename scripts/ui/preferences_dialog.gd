extends AcceptDialog

func _ready() -> void:
    title = "CONTROLES E CÂMERA"
    ok_button_text = "SALVAR"
    var grid: GridContainer = GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 24)
    grid.add_theme_constant_override("v_separation", 16)
    add_child(grid)
    _slider(grid, "Sensibilidade da câmera", 0.5, 2.0, GamePreferences.camera_sensitivity, "camera_sensitivity")
    _slider(grid, "Tamanho dos botões", 0.8, 1.15, GamePreferences.controls_scale, "controls_scale")
    _slider(grid, "Opacidade dos botões", 0.4, 1.0, GamePreferences.controls_opacity, "controls_opacity")
    var shake: CheckButton = CheckButton.new()
    shake.text = "Tremor da câmera"
    shake.button_pressed = GamePreferences.camera_shake
    shake.toggled.connect(func(value: bool) -> void: GamePreferences.camera_shake = value)
    grid.add_child(shake)
    var behavior: OptionButton = OptionButton.new()
    for text: String in ["Treino: parado", "Treino: defender", "Treino: lutar"]:
        behavior.add_item(text)
    behavior.select(GamePreferences.training_behavior)
    behavior.item_selected.connect(func(index: int) -> void: GamePreferences.training_behavior = index)
    grid.add_child(behavior)
    var help: Label = Label.new()
    help.text = "Controle: X ataque • Y jutsu • A pulo • B esquiva\nLB defesa • RB dash • LT chakra • RT correr\nR3 lock • direcional: jutsu / ult / despertar / sub • Start pausa"
    help.add_theme_font_size_override("font_size", 14)
    grid.add_child(help)
    confirmed.connect(_save)
    canceled.connect(_save)

func _slider(grid: GridContainer, text: String, low: float, high: float, value: float, property: String) -> void:
    var label: Label = Label.new()
    label.text = text
    grid.add_child(label)
    var slider: HSlider = HSlider.new()
    slider.custom_minimum_size = Vector2(250, 44)
    slider.min_value = low
    slider.max_value = high
    slider.step = 0.05
    slider.value = value
    slider.value_changed.connect(func(next: float) -> void: GamePreferences.set(property, next))
    grid.add_child(slider)

func _save() -> void:
    var result: Error = GamePreferences.save_preferences()
    if result != OK:
        push_warning("Não foi possível salvar controles: " + error_string(result))
    queue_free()
