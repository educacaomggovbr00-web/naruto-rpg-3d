extends Control

var player_pick: OptionButton
var cpu_pick: OptionButton
var arena_pick: OptionButton
var description: Label
var start_button: Button
var preview: SubViewportContainer
var player_name: Label
var cpu_name: Label
var player_accent: ColorRect
var cpu_accent: ColorRect
var arena_badge: Label

func _ready() -> void:
    CharacterCatalog.initialize()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    set_process(false)

    var margin: MarginContainer = MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 22)
    add_child(margin)

    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    margin.add_child(column)

    var header: HBoxContainer = HBoxContainer.new()
    header.custom_minimum_size.y = 54.0
    column.add_child(header)

    var title_stack: VBoxContainer = VBoxContainer.new()
    title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_stack.add_theme_constant_override("separation", -2)
    header.add_child(title_stack)

    var title: Label = Label.new()
    title.text = "SHINOBI CLASH"
    title.add_theme_font_size_override("font_size", 31)
    title.add_theme_color_override("font_color", Color("ffe19a"))
    title.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.05, 0.95))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 2)
    title_stack.add_child(title)

    var subtitle: Label = Label.new()
    subtitle.text = "ESCOLHA OS LUTADORES E ENTRE NA ARENA"
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("8faac2"))
    title_stack.add_child(subtitle)

    arena_badge = Label.new()
    arena_badge.text = "CAMPO DE TREINO"
    arena_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    arena_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    arena_badge.custom_minimum_size = Vector2(210, 40)
    arena_badge.add_theme_font_size_override("font_size", 13)
    arena_badge.add_theme_color_override("font_color", Color("f6ead2"))
    arena_badge.add_theme_stylebox_override("normal", _box(Color("132a3a"), Color("3b7080"), 1, 18))
    header.add_child(arena_badge)

    var choices_panel: PanelContainer = PanelContainer.new()
    choices_panel.custom_minimum_size.y = 62.0
    choices_panel.add_theme_stylebox_override("panel", _box(Color(0.035, 0.075, 0.12, 0.92), Color(0.20, 0.36, 0.48, 0.65), 1, 12))
    column.add_child(choices_panel)

    var choice_margin: MarginContainer = MarginContainer.new()
    choice_margin.add_theme_constant_override("margin_left", 12)
    choice_margin.add_theme_constant_override("margin_right", 12)
    choice_margin.add_theme_constant_override("margin_top", 7)
    choice_margin.add_theme_constant_override("margin_bottom", 7)
    choices_panel.add_child(choice_margin)

    var choices: HBoxContainer = HBoxContainer.new()
    choices.add_theme_constant_override("separation", 12)
    choice_margin.add_child(choices)

    player_pick = _fighter_choice(choices, "SEU LUTADOR")
    cpu_pick = _fighter_choice(choices, "CPU")
    arena_pick = _arena_choice(choices)

    var versus: HBoxContainer = HBoxContainer.new()
    versus.custom_minimum_size.y = 42.0
    versus.add_theme_constant_override("separation", 16)
    column.add_child(versus)

    var player_card: PanelContainer = _name_card(versus, true)
    player_name = player_card.get_node("Margin/Name") as Label

    var vs: Label = Label.new()
    vs.text = "VS"
    vs.custom_minimum_size.x = 70.0
    vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    vs.add_theme_font_size_override("font_size", 24)
    vs.add_theme_color_override("font_color", Color("ffb653"))
    versus.add_child(vs)

    var cpu_card: PanelContainer = _name_card(versus, false)
    cpu_name = cpu_card.get_node("Margin/Name") as Label

    var preview_panel: PanelContainer = PanelContainer.new()
    preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview_panel.custom_minimum_size.y = 250.0
    preview_panel.add_theme_stylebox_override("panel", _box(Color("0d2031"), Color("345a72"), 1, 14))
    column.add_child(preview_panel)

    var preview_margin: MarginContainer = MarginContainer.new()
    preview_margin.add_theme_constant_override("margin_left", 4)
    preview_margin.add_theme_constant_override("margin_right", 4)
    preview_margin.add_theme_constant_override("margin_top", 4)
    preview_margin.add_theme_constant_override("margin_bottom", 4)
    preview_panel.add_child(preview_margin)

    preview = SubViewportContainer.new()
    preview.set_script(preload("res://scripts/ui/fighter_preview.gd"))
    preview_margin.add_child(preview)

    description = Label.new()
    description.custom_minimum_size.y = 58.0
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    description.add_theme_font_size_override("font_size", 15)
    description.add_theme_color_override("font_color", Color("d5e2eb"))
    description.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
    description.add_theme_constant_override("shadow_offset_y", 1)
    column.add_child(description)

    var actions: HBoxContainer = HBoxContainer.new()
    actions.custom_minimum_size.y = 64.0
    actions.add_theme_constant_override("separation", 14)
    column.add_child(actions)

    start_button = Button.new()
    start_button.text = "⚔  LUTAR"
    start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    start_button.custom_minimum_size = Vector2(0, 64)
    start_button.pressed.connect(_start)
    _style_action(start_button, Color("e47b25"))
    actions.add_child(start_button)

    var world: Button = Button.new()
    world.text = "✦  EXPLORAR ALDEIA"
    world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    world.custom_minimum_size = Vector2(0, 64)
    world.pressed.connect(GameFlow.enter_world)
    _style_action(world, Color("24778b"))
    actions.add_child(world)

    player_pick.item_selected.connect(_describe)
    cpu_pick.item_selected.connect(_describe)
    arena_pick.item_selected.connect(_arena_changed)
    _describe(0)
    _arena_changed(0)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("050d19"))

    var horizon_y: float = size.y * 0.62
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, horizon_y - 70),
        Vector2(size.x, horizon_y - 135),
        Vector2(size.x, size.y),
        Vector2(0, size.y)
    ]), Color("0b1f31"))

    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 0),
        Vector2(size.x * 0.38, 0),
        Vector2(size.x * 0.25, size.y),
        Vector2(0, size.y)
    ]), Color(0.08, 0.27, 0.38, 0.22))

    draw_colored_polygon(PackedVector2Array([
        Vector2(size.x * 0.72, 0),
        Vector2(size.x, 0),
        Vector2(size.x, size.y),
        Vector2(size.x * 0.84, size.y)
    ]), Color(0.50, 0.15, 0.07, 0.14))

    draw_line(Vector2(0, 4), Vector2(size.x, 4), Color("e77d27"), 4.0)
    draw_line(Vector2(34, size.y - 90), Vector2(size.x - 34, size.y - 90), Color(0.95, 0.66, 0.25, 0.12), 1.0)

func _fighter_choice(row: HBoxContainer, title_text: String) -> OptionButton:
    var group: VBoxContainer = VBoxContainer.new()
    group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    group.add_theme_constant_override("separation", 2)
    row.add_child(group)

    var label: Label = Label.new()
    label.text = title_text
    _style_caption(label)
    group.add_child(label)

    var choice: OptionButton = OptionButton.new()
    choice.custom_minimum_size = Vector2(0, 38)
    choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        var suffix: String = " · BASE" if fighter.visual_status == "STORM1_ROSTER_SLOT_SHARED_PLACEHOLDER_RIG" else ""
        choice.add_item(fighter.display_name + suffix)
    _style_option(choice)
    group.add_child(choice)
    return choice

func _arena_choice(row: HBoxContainer) -> OptionButton:
    var group: VBoxContainer = VBoxContainer.new()
    group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    group.add_theme_constant_override("separation", 2)
    row.add_child(group)

    var label: Label = Label.new()
    label.text = "ARENA"
    _style_caption(label)
    group.add_child(label)

    var choice: OptionButton = OptionButton.new()
    choice.custom_minimum_size = Vector2(0, 38)
    choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choice.add_item("Campo de treino")
    choice.add_item("Pátio ao entardecer")
    _style_option(choice)
    group.add_child(choice)
    return choice

func _name_card(row: HBoxContainer, left_side: bool) -> PanelContainer:
    var card: PanelContainer = PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel", _box(Color(0.03, 0.08, 0.13, 0.92), Color(0.20, 0.36, 0.48, 0.65), 1, 10))
    row.add_child(card)

    var margin: MarginContainer = MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    card.add_child(margin)

    var name_label: Label = Label.new()
    name_label.name = "Name"
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left_side else HORIZONTAL_ALIGNMENT_RIGHT
    name_label.add_theme_font_size_override("font_size", 19)
    name_label.add_theme_color_override("font_color", Color.WHITE)
    margin.add_child(name_label)
    return card

func _style_caption(label: Label) -> void:
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Color("8fa8bb"))

func _style_option(button: OptionButton) -> void:
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_color_override("font_color", Color("f4f0e8"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _box(Color("102438"), Color("31536b"), 1, 8))
    button.add_theme_stylebox_override("hover", _box(Color("17344a"), Color("d9933f"), 2, 8))
    button.add_theme_stylebox_override("pressed", _box(Color("0a1827"), Color("d9933f"), 2, 8))
    button.add_theme_stylebox_override("focus", _box(Color("102438"), Color("f3c66e"), 2, 8))

func _style_action(button: Button, accent: Color) -> void:
    button.add_theme_font_size_override("font_size", 19)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _box(accent.darkened(0.30), accent, 2, 12))
    button.add_theme_stylebox_override("hover", _box(accent.darkened(0.12), accent.lightened(0.18), 3, 12))
    button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.42), accent, 2, 12))
    button.add_theme_stylebox_override("focus", _box(accent.darkened(0.30), Color("fff0bd"), 2, 12))

func _box(background: Color, border: Color, width: int, radius: int = 10) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 12.0
    style.content_margin_right = 12.0
    style.content_margin_top = 6.0
    style.content_margin_bottom = 6.0
    return style

func _describe(_index: int) -> void:
    var character: CharacterDefinition = CharacterCatalog.READY[player_pick.selected]
    var opponent: CharacterDefinition = CharacterCatalog.READY[cpu_pick.selected]

    player_name.text = "VOCÊ   " + character.display_name.to_upper()
    cpu_name.text = opponent.display_name.to_upper() + "   CPU"

    player_name.add_theme_color_override("font_color", character.energy_color.lightened(0.30))
    cpu_name.add_theme_color_override("font_color", opponent.energy_color.lightened(0.30))

    var status: String = "VISUAL PRÓPRIO"
    if character.visual_status == "STORM1_ROSTER_SLOT_SHARED_PLACEHOLDER_RIG":
        status = "BASE COMPARTILHADA"

    description.text = "%s  •  %s\n%s" % [
        character.display_name.to_upper(),
        status,
        character.summary
    ]

    if is_instance_valid(preview):
        preview.call("show_fighters", character, opponent)

func _arena_changed(_index: int) -> void:
    arena_badge.text = "CAMPO DE TREINO" if arena_pick.selected == 0 else "PÁTIO AO ENTARDECER"

func _start() -> void:
    if GameFlow.busy:
        return
    var result: Error = GameFlow.start_versus(
        CharacterCatalog.READY[player_pick.selected].character_id,
        CharacterCatalog.READY[cpu_pick.selected].character_id,
        "training" if arena_pick.selected == 0 else "courtyard"
    )
    if result != OK:
        description.text = "Não foi possível iniciar a batalha: " + error_string(result)
