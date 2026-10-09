extends HBoxContainer
## Touch-accessible inspection of all 100 clips without gameplay side effects.
signal clip_selected(clip: String)

const FORMS: Dictionary = {
    "jab": "Jab", "cross": "Direto", "hook": "Gancho", "uppercut": "Uppercut",
    "slash": "Corte", "overhead": "Golpe vertical", "thrust": "Investida",
    "cast": "Jutsu", "evade": "Esquiva", "recoil": "Reação ao impacto"
}
const VARIANTS: Dictionary = {
    "center": "Frontal", "left": "Esquerda", "right": "Direita", "low": "Baixo",
    "high": "Alto", "mirror": "Espelhado", "mirror_left": "Espelhado à esquerda",
    "mirror_right": "Espelhado à direita", "aerial": "Aéreo", "aerial_mirror": "Aéreo espelhado"
}
var family: OptionButton
var variant: OptionButton

func _ready() -> void:
    custom_minimum_size.y = 44
    var title: Label = Label.new()
    title.text = "100 MOVIMENTOS"
    title.add_theme_font_size_override("font_size", 13)
    add_child(title)
    family = _choice(FORMS)
    variant = _choice(VARIANTS)
    family.item_selected.connect(_selected)
    variant.item_selected.connect(_selected)
    var replay: Button = Button.new()
    replay.text = "REPETIR"
    replay.custom_minimum_size = Vector2(100, 44)
    replay.pressed.connect(func() -> void: _selected(0))
    add_child(replay)
    var rest: Button = Button.new()
    rest.text = "POSE NEUTRA"
    rest.custom_minimum_size = Vector2(120, 44)
    rest.pressed.connect(func() -> void: clip_selected.emit("idle"))
    add_child(rest)

func _choice(labels: Dictionary) -> OptionButton:
    var choice: OptionButton = OptionButton.new()
    choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choice.custom_minimum_size.y = 44
    for key: String in labels:
        choice.add_item(labels[key])
        choice.set_item_metadata(choice.item_count - 1, key)
    add_child(choice)
    return choice

func selected_clip() -> String:
    return "combat_%s_%s" % [family.get_item_metadata(family.selected), variant.get_item_metadata(variant.selected)]

func _selected(_index: int) -> void:
    clip_selected.emit(selected_clip())
