extends CanvasLayer
## Non-blocking training objectives; only instantiated in the dummy mode.
const TASKS: PackedStringArray = [
    "Movimente-se com o analógico ou WASD.",
    "Aproxime-se e conecte três golpes. ATK aceita o próximo toque durante a preparação; direcione o analógico para variar o golpe.",
    "Segure DEF por meio segundo. DEF + ATK tenta agarrar um alvo próximo.",
    "Use DASH para se aproximar do alvo. No controle: B.",
    "Use SUB para escapar com substituição. No controle: direcional baixo.",
    "Use um JUTSU. NINJA permite trocar o poder selecionado; recarregue com CHK.",
    "Prepare o despertar e use AWK em NINJA. Henrique pode alternar as quatro formas pelo botão FORMA."
]
var fighter: Node3D
var step: int = 0
var guard_hold: float = 0.0
var origin: Vector3
var title: Label
var instruction: Label
var prepare: Button
var panel: PanelContainer
var toggle: Button

func _ready() -> void:
    layer = 26
    origin = fighter.global_position
    panel = PanelContainer.new()
    panel.position = Vector2(14, 225)
    panel.custom_minimum_size = Vector2(310, 0)
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.07, 0.11, 0.92)
    style.border_color = Color("68becb")
    style.set_border_width_all(1)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    var column: VBoxContainer = VBoxContainer.new()
    panel.add_child(column)
    title = Label.new()
    title.add_theme_color_override("font_color", Color("ffcf7d"))
    column.add_child(title)
    instruction = Label.new()
    instruction.custom_minimum_size.x = 286
    instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    instruction.add_theme_font_size_override("font_size", 15)
    column.add_child(instruction)
    prepare = Button.new()
    prepare.text = "PREPARAR DESPERTAR"
    prepare.custom_minimum_size.y = 42
    prepare.pressed.connect(prepare_awakening)
    column.add_child(prepare)
    toggle = Button.new()
    toggle.position = Vector2(14, 390)
    toggle.custom_minimum_size = Vector2(160, 38)
    toggle.text = "OCULTAR GUIA"
    toggle.pressed.connect(func() -> void:
        if step >= TASKS.size():
            step = 0
            origin = fighter.global_position
            guard_hold = 0
            panel.visible = true
            _refresh()
        else:
            panel.visible = not panel.visible
            toggle.text = "OCULTAR GUIA" if panel.visible else "MOSTRAR GUIA")
    add_child(toggle)
    _refresh()

func _process(delta: float) -> void:
    toggle.position.y = panel.position.y + panel.size.y + 8.0 if panel.visible else panel.position.y
    if not is_instance_valid(fighter) or step >= TASKS.size() or fighter.is_defeated():
        return
    var done: bool = false
    match step:
        0: done = fighter.global_position.distance_to(origin) >= 1.5
        1: done = fighter.combo_hits >= 3
        2:
            guard_hold = guard_hold + delta if fighter.is_guarding else 0.0
            done = guard_hold >= 0.5
        3: done = fighter.chakra_dash_timer > 0.0
        4: done = fighter.substitution_cooldown > 0.0
        5: done = not fighter.specials.current.is_empty()
        6: done = fighter.awakening.active or not fighter.character_definition.has_awakening
    if done:
        step += 1
        _refresh()

func prepare_awakening() -> void:
    if step != 6 or fighter.is_defeated() or fighter.awakening.definition == null:
        return
    fighter.health = minf(fighter.health, fighter.max_health * fighter.awakening.definition.health_threshold)
    fighter.chakra = fighter.max_chakra
    fighter.awakening.cooldown = 0.0

func _refresh() -> void:
    prepare.visible = step == 6 and fighter.character_definition.has_awakening
    title.text = "TREINO GUIADO • %d/%d" % [mini(step + 1, TASKS.size()), TASKS.size()]
    instruction.text = TASKS[step] if step < TASKS.size() else "Treino concluído. Pratique os combos e poderes à vontade; RECOMEÇAR repete o guia."
    if step >= TASKS.size():
        toggle.text = "RECOMEÇAR GUIA"
