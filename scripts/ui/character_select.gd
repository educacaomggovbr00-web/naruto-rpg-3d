extends Control
var player_pick: OptionButton
var cpu_pick: OptionButton
var arena_pick: OptionButton
var description: Label
var start_button: Button

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var backdrop: ColorRect = ColorRect.new()
    backdrop.color = Color(0.035, 0.055, 0.09)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)
    var margin: MarginContainer = MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 80)
    margin.add_theme_constant_override("margin_right", 80)
    margin.add_theme_constant_override("margin_top", 40)
    margin.add_theme_constant_override("margin_bottom", 40)
    add_child(margin)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 20)
    margin.add_child(column)
    var title: Label = Label.new()
    title.text = "SHINOBI — VERSUS CPU"
    title.add_theme_font_size_override("font_size", 34)
    column.add_child(title)
    var choices: HBoxContainer = HBoxContainer.new()
    choices.add_theme_constant_override("separation", 24)
    column.add_child(choices)
    player_pick = _fighter_choice(choices, "SEU LUTADOR")
    cpu_pick = _fighter_choice(choices, "CPU")
    var stage: VBoxContainer = VBoxContainer.new()
    stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choices.add_child(stage)
    var caption: Label = Label.new()
    caption.text = "ARENA"
    stage.add_child(caption)
    arena_pick = OptionButton.new()
    arena_pick.custom_minimum_size = Vector2(280, 64)
    arena_pick.add_item("Campo de treino")
    arena_pick.add_item("Pátio ao entardecer")
    stage.add_child(arena_pick)
    description = Label.new()
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.size_flags_vertical = Control.SIZE_EXPAND_FILL
    description.add_theme_font_size_override("font_size", 22)
    column.add_child(description)
    player_pick.item_selected.connect(_describe)
    _describe(0)
    var actions: HBoxContainer = HBoxContainer.new()
    actions.add_theme_constant_override("separation", 24)
    column.add_child(actions)
    start_button = Button.new()
    start_button.text = "LUTAR"
    start_button.custom_minimum_size = Vector2(320, 76)
    start_button.pressed.connect(_start)
    actions.add_child(start_button)
    var world: Button = Button.new()
    world.text = "EXPLORAR ALDEIA"
    world.custom_minimum_size = Vector2(320, 76)
    world.pressed.connect(GameFlow.enter_world)
    actions.add_child(world)

func _fighter_choice(row: HBoxContainer, title: String) -> OptionButton:
    var group: VBoxContainer = VBoxContainer.new()
    group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(group)
    var label: Label = Label.new()
    label.text = title
    group.add_child(label)
    var choice: OptionButton = OptionButton.new()
    choice.custom_minimum_size = Vector2(280, 64)
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        choice.add_item(fighter.display_name)
    for name: String in CharacterCatalog.PENDING:
        choice.add_item(name + " — em desenvolvimento")
        choice.set_item_disabled(choice.item_count - 1, true)
    group.add_child(choice)
    return choice

func _describe(_index: int) -> void:
    var character: CharacterDefinition = CharacterCatalog.READY[player_pick.selected]
    description.text = ("Naruto: Rasengan, Demon Wind, clones, Barrage, Ultimate e base Nine-Tails." if character.character_id == "naruto" else "Sasuke: Chidori e Fireball. Ultimate e transformação ainda em desenvolvimento.") + "\n\nOs dois usam o visual rigado de desenvolvimento; modelos finais e coreografias próprias estão pendentes."

func _start() -> void:
    if GameFlow.busy:
        return
    var result: Error = GameFlow.start_versus(CharacterCatalog.READY[player_pick.selected].character_id, CharacterCatalog.READY[cpu_pick.selected].character_id, "training" if arena_pick.selected == 0 else "courtyard")
    if result != OK:
        description.text = "Não foi possível iniciar a batalha: " + error_string(result)
