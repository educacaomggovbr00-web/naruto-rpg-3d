extends Control
var player_pick: OptionButton
var cpu_pick: OptionButton
var arena_pick: OptionButton
var description: Label
var start_button: Button
var preview: SubViewportContainer

func _ready() -> void:
    CharacterCatalog.initialize()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var backdrop: ColorRect = ColorRect.new()
    backdrop.color = Color("07111f")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    var top_glow: ColorRect = ColorRect.new()
    top_glow.color = Color("d9792b")
    top_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top_glow.offset_bottom = 4.0
    top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(top_glow)

    var horizon: ColorRect = ColorRect.new()
    horizon.color = Color(0.20, 0.42, 0.62, 0.16)
    horizon.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    horizon.offset_top = -150.0
    horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(horizon)
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
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", Color("ffd27a"))
    title.add_theme_color_override("font_shadow_color", Color("1d0b05"))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 2)
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
    _style_option(arena_pick)
    _style_caption(caption)
    stage.add_child(arena_pick)
    preview = SubViewportContainer.new()
    preview.set_script(preload("res://scripts/ui/fighter_preview.gd"))
    column.add_child(preview)
    description = Label.new()
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.size_flags_vertical = Control.SIZE_EXPAND_FILL
    description.add_theme_font_size_override("font_size", 18)
    description.add_theme_color_override("font_color", Color("dbe7ef"))
    description.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
    description.add_theme_constant_override("shadow_offset_y", 1)
    column.add_child(description)
    player_pick.item_selected.connect(_describe)
    cpu_pick.item_selected.connect(_describe)
    _describe(0)
    var actions: HBoxContainer = HBoxContainer.new()
    actions.add_theme_constant_override("separation", 24)
    column.add_child(actions)
    start_button = Button.new()
    start_button.text = "LUTAR"
    start_button.custom_minimum_size = Vector2(320, 76)
    start_button.pressed.connect(_start)
    _style_action(start_button, Color("e6852c"))
    actions.add_child(start_button)
    var world: Button = Button.new()
    world.text = "EXPLORAR ALDEIA"
    world.custom_minimum_size = Vector2(320, 76)
    world.pressed.connect(GameFlow.enter_world)
    _style_action(world, Color("367e8f"))
    actions.add_child(world)


func _style_caption(label: Label) -> void:
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", Color("9fb5c8"))

func _style_option(button: OptionButton) -> void:
    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override("font_color", Color("f5f1e8"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _box(Color("13273a"), Color("45647d"), 1))
    button.add_theme_stylebox_override("hover", _box(Color("1c3950"), Color("e3a04b"), 2))
    button.add_theme_stylebox_override("pressed", _box(Color("0e1c2a"), Color("e3a04b"), 2))
    button.add_theme_stylebox_override("focus", _box(Color(0.0, 0.0, 0.0, 0.0), Color("ffd27a"), 2))

func _style_action(button: Button, accent: Color) -> void:
    button.add_theme_font_size_override("font_size", 21)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _box(accent.darkened(0.24), accent, 2))
    button.add_theme_stylebox_override("hover", _box(accent.darkened(0.08), accent.lightened(0.18), 3))
    button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.36), accent, 2))
    button.add_theme_stylebox_override("focus", _box(accent.darkened(0.24), Color("fff0bd"), 2))

func _box(background: Color, border: Color, width: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(width)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.content_margin_left = 14.0
    style.content_margin_right = 14.0
    style.content_margin_top = 8.0
    style.content_margin_bottom = 8.0
    return style

func _fighter_choice(row: HBoxContainer, title: String) -> OptionButton:
    var group: VBoxContainer = VBoxContainer.new()
    group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(group)
    var label: Label = Label.new()
    label.text = title
    _style_caption(label)
    group.add_child(label)
    var choice: OptionButton = OptionButton.new()
    choice.custom_minimum_size = Vector2(280, 64)
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        var suffix: String = " — base em desenvolvimento" if fighter.visual_status == "STORM1_ROSTER_SLOT_SHARED_PLACEHOLDER_RIG" else ""
        choice.add_item(fighter.display_name + suffix)
    _style_option(choice)
    group.add_child(choice)
    return choice

func _describe(_index: int) -> void:
    var character: CharacterDefinition = CharacterCatalog.READY[player_pick.selected]
    description.text = character.summary + "\n\nElenco jogável de Storm 1: %d personagens. Naruto, Sasuke, Sakura e Kakashi já têm perfis visuais próprios; os demais entram primeiro como slots jogáveis com rig/base compartilhados enquanto recebem implementação individual." % CharacterCatalog.READY.size()
    preview.call("show_fighters", character, CharacterCatalog.READY[cpu_pick.selected])

func _start() -> void:
    if GameFlow.busy:
        return
    var result: Error = GameFlow.start_versus(CharacterCatalog.READY[player_pick.selected].character_id, CharacterCatalog.READY[cpu_pick.selected].character_id, "training" if arena_pick.selected == 0 else "courtyard")
    if result != OK:
        description.text = "Não foi possível iniciar a batalha: " + error_string(result)
