extends RefCounted
## Compact shared rows; battle preferences live inside a bounded scroll area.
static func build(column: VBoxContainer) -> void:
    for entry: Array in [["camera_sensitivity","Sensibilidade da câmera",.5,2.0,.05], ["touch_deadzone","Zona morta do analógico touch",.05,.3,.01], ["music_volume","Música",0.0,1.0,.05], ["sfx_volume","Efeitos sonoros",0.0,1.0,.05]]:
        var key: String = entry[0]
        var row: HBoxContainer = HBoxContainer.new()
        row.custom_minimum_size.y = 40
        column.add_child(row)
        var label: Label = Label.new()
        label.text = entry[1]
        label.custom_minimum_size.x = 250
        label.add_theme_font_size_override("font_size",14)
        row.add_child(label)
        var slider: HSlider = HSlider.new()
        slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slider.min_value = entry[2]
        slider.max_value = entry[3]
        slider.step = entry[4]
        slider.value = CombatSettings.get(key)
        row.add_child(slider)
        var value_label: Label = Label.new()
        value_label.custom_minimum_size.x = 44
        value_label.text = "%.2f" % slider.value
        row.add_child(value_label)
        slider.value_changed.connect(func(value: float) -> void:
            value_label.text = "%.2f" % value
            CombatSettings.set(key,value)
            CombatSettings.save_preferences())
    for entry: Array in [["controls_scale","Tamanho dos controles",.8,1.15], ["controls_opacity","Opacidade dos controles",.4,1.0]]:
        var key: String = entry[0]
        var label: Label = Label.new()
        label.text = entry[1]
        column.add_child(label)
        var slider: HSlider = HSlider.new()
        slider.min_value = entry[2]
        slider.max_value = entry[3]
        slider.step = .05
        slider.value = GamePreferences.get(key)
        slider.custom_minimum_size.y = 32
        column.add_child(slider)
        slider.value_changed.connect(func(value: float) -> void:
            GamePreferences.set(key,value)
            # Save touch preferences without overriding the canonical camera/difficulty.
            GamePreferences.camera_sensitivity = CombatSettings.camera_sensitivity
            GamePreferences.camera_shake = CombatSettings.camera_shake > 0.0
            GamePreferences.difficulty = mini(CombatSettings.difficulty,2)
            GamePreferences.save_preferences())
