extends RefCounted
static func build(column: VBoxContainer) -> void:
    _slider(column,"Campo de visão",52,72,CombatSettings.camera_fov,func(value: float) -> void:
        CombatSettings.camera_fov = value
        CombatSettings.save_preferences())
    _slider(column,"Tremor da câmera",0,1,CombatSettings.camera_shake,func(value: float) -> void:
        CombatSettings.camera_shake = value
        CombatSettings.save_preferences())
    var motion: CheckButton = CheckButton.new()
    motion.text = "Zoom e inclinação de impacto"
    motion.button_pressed = CombatSettings.camera_motion
    motion.toggled.connect(func(enabled: bool) -> void:
        CombatSettings.camera_motion = enabled
        CombatSettings.save_preferences())
    column.add_child(motion)
static func _slider(column: VBoxContainer, text: String, minimum: float, maximum: float, current: float, callback: Callable) -> void:
    var label: Label = Label.new()
    label.text = text
    column.add_child(label)
    var slider: HSlider = HSlider.new()
    slider.min_value = minimum
    slider.max_value = maximum
    slider.step = 1.0 if maximum > 1 else .05
    slider.value = current
    slider.custom_minimum_size.y = 32
    slider.value_changed.connect(callback)
    column.add_child(slider)
