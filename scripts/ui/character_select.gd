extends Control

var player_pick: OptionButton
var cpu_pick: OptionButton
var difficulty_pick: OptionButton
var mode_pick: OptionButton
var arena_pick: OptionButton
var description: Label
var start_button: Button
var preview: SubViewportContainer
var player_name: Label
var cpu_name: Label
var arena_badge: Label
var roster_buttons: Array[Button] = []
var roster_side: String = "player"
var roster_scroll: ScrollContainer
var technique_pick: OptionButton
var animation_toggle: Button
var animation_gallery: HBoxContainer
var team_toggle: CheckBox
var rules_enabled: bool = true

func _ready() -> void:
    CharacterCatalog.initialize()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    set_process(false)

    var margin: MarginContainer = MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    add_child(margin)

    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 6)
    margin.add_child(column)

    var header: HBoxContainer = HBoxContainer.new()
    header.custom_minimum_size.y = 48.0
    column.add_child(header)

    var title_stack: VBoxContainer = VBoxContainer.new()
    title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_stack.add_theme_constant_override("separation", -3)
    header.add_child(title_stack)

    var title: Label = Label.new()
    title.text = "SHINOBI CLASH"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("ffd27a"))
    title.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.04, 0.95))
    title.add_theme_constant_override("shadow_offset_x", 3)
    title.add_theme_constant_override("shadow_offset_y", 3)
    title_stack.add_child(title)

    var subtitle: Label = Label.new()
    subtitle.text = "0.16.0 • RESPOSTA, TÉCNICAS E APRESENTAÇÃO"
    if RuntimeStability.recovered_session:
        subtitle.text = "0.16.0 • MODO LEVE ATIVADO APÓS INTERRUPÇÃO"
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("8fb8cc"))
    title_stack.add_child(subtitle)

    arena_badge = Label.new()
    arena_badge.text = "CAMPO DE TREINO"
    arena_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    arena_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    arena_badge.custom_minimum_size = Vector2(210, 42)
    arena_badge.add_theme_font_size_override("font_size", 13)
    arena_badge.add_theme_color_override("font_color", Color("fff1d2"))
    arena_badge.add_theme_stylebox_override("normal", _box(Color(0.04, 0.11, 0.16, 0.94), Color("d08a38"), 2, 20))
    header.add_child(arena_badge)

    var choices_panel: PanelContainer = PanelContainer.new()
    choices_panel.custom_minimum_size.y = 62.0
    choices_panel.add_theme_stylebox_override("panel", _box(Color(0.025, 0.055, 0.09, 0.93), Color(0.16, 0.33, 0.44, 0.80), 1, 14))
    column.add_child(choices_panel)

    var choice_margin: MarginContainer = MarginContainer.new()
    choice_margin.add_theme_constant_override("margin_left", 12)
    choice_margin.add_theme_constant_override("margin_right", 12)
    choice_margin.add_theme_constant_override("margin_top", 8)
    choice_margin.add_theme_constant_override("margin_bottom", 8)
    choices_panel.add_child(choice_margin)

    var choices: HBoxContainer = HBoxContainer.new()
    choices.add_theme_constant_override("separation", 12)
    choice_margin.add_child(choices)
    player_pick = _fighter_choice(choices, "SEU LUTADOR")
    player_pick.select(maxi(CharacterCatalog.READY.find(GameFlow.player_character), 0))
    cpu_pick = _fighter_choice(choices, "CPU")
    cpu_pick.select(maxi(CharacterCatalog.READY.find(GameFlow.cpu_character), 0))
    arena_pick = _arena_choice(choices)
    arena_pick.select(maxi(ArenaCatalog.IDS.find(GameFlow.arena_id), 0))
    var mode_group: VBoxContainer = VBoxContainer.new()
    mode_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choices.add_child(mode_group)
    var mode_label: Label = Label.new()
    mode_label.text = "MODO"
    _style_caption(mode_label)
    mode_group.add_child(mode_label)
    mode_pick = OptionButton.new()
    for mode_title: String in ["Batalha livre", "Treinamento", "Torneio solo", "Sobrevivência", "Chefes", "Esquadrão inimigo"]:
        mode_pick.add_item(mode_title)
    _style_option(mode_pick)
    mode_pick.custom_minimum_size.y = 40
    mode_group.add_child(mode_pick)

    var difficulty_group = VBoxContainer.new()
    difficulty_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choices.add_child(difficulty_group)
    var difficulty_label = Label.new()
    difficulty_label.text = "DIFICULDADE"
    _style_caption(difficulty_label)
    difficulty_group.add_child(difficulty_label)
    difficulty_pick = OptionButton.new()
    for label in CombatSettings.DIFFICULTIES: difficulty_pick.add_item(label)
    difficulty_pick.select(CombatSettings.difficulty)
    _style_option(difficulty_pick)
    difficulty_pick.custom_minimum_size.y = 40
    difficulty_group.add_child(difficulty_pick)
    difficulty_pick.item_selected.connect(func(index: int):
        CombatSettings.difficulty = index
        CombatSettings.save_preferences())

    _build_roster_strip(column)

    var versus: HBoxContainer = HBoxContainer.new()
    versus.custom_minimum_size.y = 34.0
    versus.add_theme_constant_override("separation", 14)
    column.add_child(versus)

    var player_card: PanelContainer = _name_card(versus, true)
    player_name = player_card.get_node("Margin/Name") as Label

    var vs: Label = Label.new()
    vs.text = "VS"
    vs.custom_minimum_size.x = 76.0
    vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    vs.add_theme_font_size_override("font_size", 28)
    vs.add_theme_color_override("font_color", Color("ff9f43"))
    vs.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.95))
    vs.add_theme_constant_override("shadow_offset_x", 2)
    vs.add_theme_constant_override("shadow_offset_y", 2)
    versus.add_child(vs)

    var cpu_card: PanelContainer = _name_card(versus, false)
    cpu_name = cpu_card.get_node("Margin/Name") as Label

    var preview_panel: PanelContainer = PanelContainer.new()
    preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview_panel.custom_minimum_size.y = 220.0
    preview_panel.add_theme_stylebox_override("panel", _box(Color(0.02, 0.07, 0.11, 0.96), Color(0.22, 0.46, 0.58, 0.95), 2, 18))
    column.add_child(preview_panel)

    var preview_margin: MarginContainer = MarginContainer.new()
    preview_margin.add_theme_constant_override("margin_left", 5)
    preview_margin.add_theme_constant_override("margin_right", 5)
    preview_margin.add_theme_constant_override("margin_top", 5)
    preview_margin.add_theme_constant_override("margin_bottom", 5)
    preview_panel.add_child(preview_margin)

    preview = SubViewportContainer.new()
    preview.set_script(preload("res://scripts/ui/fighter_preview.gd"))
    preview_margin.add_child(preview)

    var technique_row = HBoxContainer.new()
    column.add_child(technique_row)
    var technique_caption = Label.new()
    technique_caption.text = "TÉCNICAS"
    _style_caption(technique_caption)
    technique_row.add_child(technique_caption)
    technique_pick = OptionButton.new()
    technique_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    technique_pick.custom_minimum_size.y = 38
    _style_option(technique_pick)
    technique_row.add_child(technique_pick)
    technique_pick.item_selected.connect(_describe_technique)
    var watch = Button.new()
    watch.text = "VER TÉCNICA"
    watch.pressed.connect(_preview_technique)
    technique_row.add_child(watch)
    animation_toggle = Button.new()
    animation_toggle.text = "ANIMAÇÕES"
    animation_toggle.pressed.connect(func():
        animation_gallery.visible = not animation_gallery.visible
        preview_panel.custom_minimum_size.y = 175.0 if animation_gallery.visible else 220.0
        preview.custom_minimum_size.y = 175.0 if animation_gallery.visible else 220.0)
    technique_row.add_child(animation_toggle)
    team_toggle = CheckBox.new()
    team_toggle.name = "TeamEnabled"
    team_toggle.text = "EQUIPE"
    team_toggle.button_pressed = GameFlow.team_enabled if GameFlow.team_preferences_set else true
    rules_enabled = GameFlow.battle_rules_enabled if GameFlow.team_preferences_set else true
    technique_row.add_child(team_toggle)
    var team_button: Button = Button.new()
    team_button.text = "PARCEIROS"
    team_button.pressed.connect(_show_team_options)
    technique_row.add_child(team_button)
    animation_gallery = HBoxContainer.new()
    animation_gallery.set_script(preload("res://scripts/ui/combat_animation_gallery.gd"))
    column.add_child(animation_gallery)
    animation_gallery.clip_selected.connect(preview.preview_animation)
    animation_gallery.visible = false

    description = Label.new()
    description.custom_minimum_size.y = 32.0
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    description.add_theme_font_size_override("font_size", 14)
    description.add_theme_color_override("font_color", Color("d8e5eb"))
    description.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
    description.add_theme_constant_override("shadow_offset_y", 1)
    column.add_child(description)

    var actions: HBoxContainer = HBoxContainer.new()
    actions.custom_minimum_size.y = 56.0
    actions.add_theme_constant_override("separation", 14)
    column.add_child(actions)

    start_button = Button.new()
    start_button.text = "LUTAR"
    start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    start_button.custom_minimum_size = Vector2(0, 56)
    start_button.pressed.connect(_start)
    _style_action(start_button, Color("e77422"))
    actions.add_child(start_button)

    var world: Button = Button.new()
    world.text = "EXPLORAR ALDEIA"
    world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    world.custom_minimum_size = Vector2(0, 56)
    world.pressed.connect(_enter_world)
    _style_action(world, Color("1f7184"))
    actions.add_child(world)

    var campaign: Button = Button.new()
    campaign.text = "HISTÓRIA HENRIQUE"
    campaign.custom_minimum_size = Vector2(175, 56)
    campaign.pressed.connect(GameFlow.enter_henrique_campaign)
    _style_action(campaign, Color("603082"))
    actions.add_child(campaign)

    var options: Button = Button.new()
    options.text = "OPÇÕES"
    options.custom_minimum_size = Vector2(120, 56)
    options.pressed.connect(_show_options)
    _style_action(options, Color("285b68"))
    actions.add_child(options)

    var credits: Button = Button.new()
    credits.text = "CRÉDITOS"
    credits.custom_minimum_size = Vector2(150, 56)
    credits.pressed.connect(_show_credits)
    _style_action(credits, Color("58407a"))
    actions.add_child(credits)

    player_pick.item_selected.connect(_describe)
    cpu_pick.item_selected.connect(_describe)
    arena_pick.item_selected.connect(_arena_changed)
    _describe(0)
    _arena_changed(0)
    queue_redraw()

func _show_credits() -> void:
    var popup: AcceptDialog = AcceptDialog.new()
    popup.title = "Créditos do Susanoo"
    popup.ok_button_text = "VOLTAR"
    var text: RichTextLabel = RichTextLabel.new()
    text.bbcode_enabled = true
    text.custom_minimum_size = Vector2(760, 210)
    text.add_theme_font_size_override("normal_font_size", 18)
    text.text = "[b]Perfect susanoo[/b] — wahidinesport\n[url=https://sketchfab.com/3d-models/perfect-susanoo-c1ef38744eb64891b26a6f41aac1b199]Modelo original no Sketchfab[/url]\n[url=https://creativecommons.org/licenses/by/4.0/]Licença Creative Commons Attribution 4.0[/url]\n\nAlterações: malha reduzida, conversão para GLB, escala, materiais de chakra violeta e asas opcionais.\nModelo do Henrique enviado pelo jogador; rig e integração pelo projeto. Animações CC0 de Quaternius."
    text.meta_clicked.connect(func(url: Variant) -> void: OS.shell_open(String(url)))
    popup.add_child(text)
    add_child(popup)
    popup.confirmed.connect(popup.queue_free)
    popup.canceled.connect(popup.queue_free)
    popup.popup_centered()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("040a12"))

    var horizon: float = size.y * 0.62
    draw_circle(Vector2(size.x * 0.82, size.y * 0.18), size.y * 0.15, Color(0.95, 0.36, 0.11, 0.14))
    draw_circle(Vector2(size.x * 0.82, size.y * 0.18), size.y * 0.095, Color(1.0, 0.66, 0.24, 0.12))

    draw_colored_polygon(PackedVector2Array([
        Vector2(0, horizon - 72),
        Vector2(size.x * 0.18, horizon - 118),
        Vector2(size.x * 0.36, horizon - 78),
        Vector2(size.x * 0.54, horizon - 140),
        Vector2(size.x * 0.74, horizon - 92),
        Vector2(size.x, horizon - 128),
        Vector2(size.x, size.y),
        Vector2(0, size.y)
    ]), Color("081a29"))

    for i: int in range(9):
        var x: float = float(i) * size.x / 8.0 - 60.0
        var width: float = 110.0 + float((i * 37) % 70)
        var height: float = 54.0 + float((i * 29) % 70)
        draw_rect(Rect2(Vector2(x, horizon - height), Vector2(width, height + 120.0)), Color(0.05, 0.12, 0.17, 0.78))
        draw_colored_polygon(PackedVector2Array([
            Vector2(x - 12.0, horizon - height),
            Vector2(x + width * 0.5, horizon - height - 24.0),
            Vector2(x + width + 12.0, horizon - height),
            Vector2(x + width, horizon - height + 8.0),
            Vector2(x, horizon - height + 8.0)
        ]), Color(0.13, 0.19, 0.22, 0.82))

    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 0),
        Vector2(size.x * 0.38, 0),
        Vector2(size.x * 0.24, size.y),
        Vector2(0, size.y)
    ]), Color(0.04, 0.33, 0.47, 0.12))

    draw_colored_polygon(PackedVector2Array([
        Vector2(size.x * 0.72, 0),
        Vector2(size.x, 0),
        Vector2(size.x, size.y),
        Vector2(size.x * 0.84, size.y)
    ]), Color(0.72, 0.20, 0.06, 0.10))

    draw_line(Vector2(0, 4), Vector2(size.x, 4), Color("e57927"), 4.0)
    draw_line(Vector2(28, size.y - 86), Vector2(size.x - 28, size.y - 86), Color(0.96, 0.61, 0.22, 0.13), 1.0)

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
    choice.custom_minimum_size = Vector2(0, 40)
    choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        choice.add_item(fighter.display_name)
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
    choice.custom_minimum_size = Vector2(0, 40)
    choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for title: String in ArenaCatalog.NAMES:
        choice.add_item(title)
    _style_option(choice)
    group.add_child(choice)
    return choice

func _name_card(row: HBoxContainer, left_side: bool) -> PanelContainer:
    var card: PanelContainer = PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel", _box(Color(0.02, 0.07, 0.11, 0.92), Color(0.18, 0.38, 0.50, 0.82), 1, 12))
    row.add_child(card)

    var margin: MarginContainer = MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    card.add_child(margin)

    var name_label: Label = Label.new()
    name_label.name = "Name"
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left_side else HORIZONTAL_ALIGNMENT_RIGHT
    name_label.add_theme_font_size_override("font_size", 21)
    name_label.add_theme_color_override("font_color", Color.WHITE)
    margin.add_child(name_label)
    return card

func _style_caption(label: Label) -> void:
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Color("85a8ba"))

func _style_option(button: OptionButton) -> void:
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_color_override("font_color", Color("f6f2e9"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _box(Color("0d2132"), Color("294e62"), 1, 9))
    button.add_theme_stylebox_override("hover", _box(Color("153448"), Color("d78b3b"), 2, 9))
    button.add_theme_stylebox_override("pressed", _box(Color("091824"), Color("d78b3b"), 2, 9))
    button.add_theme_stylebox_override("focus", _box(Color("0d2132"), Color("f2bd65"), 2, 9))

func _style_action(button: Button, accent: Color) -> void:
    button.add_theme_font_size_override("font_size", 18)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _box(accent.darkened(0.24), accent, 2, 14))
    button.add_theme_stylebox_override("hover", _box(accent.darkened(0.08), accent.lightened(0.18), 3, 14))
    button.add_theme_stylebox_override("pressed", _box(accent.darkened(0.40), accent, 2, 14))
    button.add_theme_stylebox_override("focus", _box(accent.darkened(0.24), Color("fff0bd"), 2, 14))

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

    player_name.text = "VOCÊ  •  " + character.display_name.to_upper()
    cpu_name.text = opponent.display_name.to_upper() + "  •  CPU"

    player_name.add_theme_color_override("font_color", character.energy_color.lightened(0.28))
    cpu_name.add_theme_color_override("font_color", opponent.energy_color.lightened(0.28))

    description.text = "%s • %d técnicas • Combos terrestres e aéreos • Ultimate e transformação" % [character.display_name,character.jutsus.size()]
    if technique_pick != null:
        technique_pick.clear()
        for id: String in character.jutsus:
            var technique: JutsuDefinition = character.find_jutsu(id)
            technique_pick.add_item(technique.display_name if technique != null else id.capitalize())
            technique_pick.set_item_metadata(technique_pick.item_count - 1,id)
    for index: int in range(roster_buttons.size()):
        roster_buttons[index].button_pressed = index == (player_pick.selected if roster_side == "player" else cpu_pick.selected)

    _describe_technique(0)
    if roster_scroll != null and not roster_buttons.is_empty():
        roster_scroll.call_deferred("ensure_control_visible", roster_buttons[player_pick.selected if roster_side == "player" else cpu_pick.selected])
    if is_instance_valid(preview):
        preview.call("show_fighters", character, opponent)

func _build_roster_strip(column: VBoxContainer) -> void:
    var row = HBoxContainer.new()
    column.add_child(row)
    var side = Button.new()
    side.text = "VOCÊ"
    side.custom_minimum_size.x = 78
    side.tooltip_text = "Escolher personagem do jogador ou da CPU"
    side.pressed.connect(func():
        roster_side = "cpu" if roster_side == "player" else "player"
        side.text = "CPU" if roster_side == "cpu" else "VOCÊ"
        _describe(0))
    row.add_child(side)
    var scroll = ScrollContainer.new()
    roster_scroll = scroll
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size.y = 76
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    row.add_child(scroll)
    var portraits = HBoxContainer.new()
    portraits.add_theme_constant_override("separation",6)
    scroll.add_child(portraits)
    for index: int in range(CharacterCatalog.READY.size()):
        var definition: CharacterDefinition = CharacterCatalog.READY[index]
        var card = Button.new()
        card.custom_minimum_size = Vector2(164,60)
        card.tooltip_text = definition.display_name
        card.toggle_mode = true
        var content = HBoxContainer.new()
        content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        content.offset_left = 8
        content.offset_right = -8
        content.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(content)
        var portrait = TextureRect.new()
        portrait.texture = load("res://assets/ui/portraits/"+definition.character_id+".png")
        portrait.custom_minimum_size = Vector2(48,48)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(portrait)
        var name_label = Label.new()
        name_label.text = definition.display_name
        name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size",12)
        name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(name_label)
        card.pressed.connect(_pick_roster.bind(index))
        portraits.add_child(card)
        roster_buttons.append(card)

func _pick_roster(index: int) -> void:
    if roster_side == "cpu":
        cpu_pick.select(index)
    else:
        player_pick.select(index)
    _describe(index)

func _preview_technique() -> void:
    if technique_pick == null or technique_pick.selected < 0:
        return
    preview.preview_technique(String(technique_pick.get_item_metadata(technique_pick.selected)))


func _arena_changed(_index: int) -> void:
    arena_badge.text = ArenaCatalog.NAMES[arena_pick.selected].to_upper()

func _start() -> void:
    if GameFlow.busy:
        return
    var player_id: String = CharacterCatalog.READY[player_pick.selected].character_id
    var cpu_id: String = CharacterCatalog.READY[cpu_pick.selected].character_id
    var stage: String = ArenaCatalog.IDS[arena_pick.selected]
    GameFlow.team_enabled = team_toggle.button_pressed
    GameFlow.battle_rules_enabled = rules_enabled
    GameFlow.team_preferences_set = true
    var result: Error = GameFlow.start_versus(player_id, cpu_id, stage) if mode_pick.selected == 0 else GameFlow.start_arcade(["", "training", "tournament", "survival", "boss", "mob"][mode_pick.selected], player_id, cpu_id, stage)
    if result != OK:
        description.text = "Não foi possível iniciar a batalha: " + error_string(result)

func _show_team_options() -> void:
    var dialog: ConfirmationDialog = ConfirmationDialog.new()
    dialog.name = "TeamOptions"
    dialog.title = "Formação de equipe"
    dialog.ok_button_text = "APLICAR"
    dialog.cancel_button_text = "VOLTAR"
    add_child(dialog)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    dialog.add_child(column)
    var help: Label = Label.new()
    help.text = "Um líder + até dois parceiros • Vida compartilhada\nSuporte tem recarga. Trocas consomem a barra de suporte."
    column.add_child(help)
    var picks: Array[OptionButton] = []
    var configured: Array[PackedStringArray] = [GameFlow.player_partners, GameFlow.cpu_partners]
    for side: int in range(2):
        var label: Label = Label.new()
        label.text = "SUA EQUIPE" if side == 0 else "EQUIPE CPU"
        column.add_child(label)
        var row: HBoxContainer = HBoxContainer.new()
        column.add_child(row)
        for slot: int in range(2):
            var pick: OptionButton = OptionButton.new()
            pick.name = "Partner%d" % picks.size()
            pick.custom_minimum_size = Vector2(255, 44)
            pick.add_item("Sem parceiro")
            pick.set_item_metadata(0, "")
            for definition: CharacterDefinition in CharacterCatalog.READY:
                pick.add_item(definition.display_name)
                pick.set_item_metadata(pick.item_count - 1, definition.character_id)
                if slot < configured[side].size() and configured[side][slot] == definition.character_id:
                    pick.select(pick.item_count - 1)
            row.add_child(pick)
            picks.append(pick)
    var rules: CheckBox = CheckBox.new()
    rules.name = "BattleRulesEnabled"
    rules.text = "Estados elementais, quebra de equipamento e cenário"
    rules.button_pressed = rules_enabled
    column.add_child(rules)
    var error_label: Label = Label.new()
    error_label.add_theme_color_override("font_color", Color("ff8a72"))
    column.add_child(error_label)
    # Keep the dialog open on invalid duplicate choices, with an actionable error.
    dialog.dialog_hide_on_ok = false
    dialog.confirmed.connect(func():
        var player_ids: PackedStringArray = []
        var cpu_ids: PackedStringArray = []
        for index: int in range(picks.size()):
            var id: String = picks[index].get_selected_metadata()
            if not id.is_empty():
                if index < 2:
                    player_ids.append(id)
                else:
                    cpu_ids.append(id)
        if GameFlow.configure_teams(team_toggle.button_pressed, player_ids, cpu_ids) != OK:
            error_label.text = "Escolha parceiros diferentes em cada equipe."
            return
        rules_enabled = rules.button_pressed
        GameFlow.battle_rules_enabled = rules_enabled
        description.text = "Equipe pronta • Z/X suporte, C troca, V supremo, B despertar • Botões na luta."
        dialog.queue_free())
    dialog.canceled.connect(dialog.queue_free)
    dialog.popup_centered(Vector2i(570, 440))


func _enter_world() -> void:
    if GameFlow.busy:
        return
    GameFlow.player_character = CharacterCatalog.READY[player_pick.selected]
    GameFlow.campaign_id = "classic"
    GameFlow.enter_world()

func _show_options() -> void:
    var dialog: AcceptDialog = AcceptDialog.new()
    dialog.title = "Dificuldade e controle"
    dialog.min_size = Vector2i(520, 320)
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.custom_minimum_size = Vector2(520, 380)
    dialog.add_child(scroll)
    var column: VBoxContainer = VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 8)
    scroll.add_child(column)
    var label: Label = Label.new()
    label.text = "Dificuldade da CPU (aplicada na próxima batalha)"
    column.add_child(label)
    var difficulty_pick: OptionButton = OptionButton.new()
    for title: String in CombatSettings.DIFFICULTIES:
        difficulty_pick.add_item(title)
    difficulty_pick.select(CombatSettings.difficulty)
    difficulty_pick.item_selected.connect(func(index: int) -> void:
        CombatSettings.difficulty = index
        CombatSettings.save_preferences())
    column.add_child(difficulty_pick)
    var help: Label = Label.new()
    help.text = "Controle: X ataque • A salto • Y jutsu • B dash\nLB defesa • LB + X agarrão • RB chakra • stick direito câmera / clique trava\nDirecional: baixo substituição • esquerda esquiva\ncima ultimate • direita transformação"
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.custom_minimum_size.x = 480
    column.add_child(help)
    var graphics_label: Label = Label.new()
    graphics_label.text = "Qualidade gráfica • próxima batalha ou exploração"
    column.add_child(graphics_label)
    var graphics: OptionButton = OptionButton.new()
    graphics.name = "GraphicsQuality"
    for title: String in GraphicsPreferences.LABELS:
        graphics.add_item(title)
    graphics.select(GraphicsPreferences.read_quality())
    var graphics_help: Label = Label.new()
    graphics_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var graphic_descriptions: PackedStringArray = ["Menos efeitos e sombras, para priorizar fluidez.", "Efeitos e sombras equilibrados.", "Mais efeitos, sombras e nitidez."]
    graphics_help.text = graphic_descriptions[graphics.selected]
    graphics.item_selected.connect(func(index: int) -> void:
        graphics_help.text = graphic_descriptions[index]
        var result: Error = GraphicsPreferences.save_quality(index)
        if result != OK:
            graphics.select(GraphicsPreferences.read_quality())
            graphics_help.text = graphic_descriptions[graphics.selected]
            push_warning("Não foi possível salvar a qualidade gráfica."))
    column.add_child(graphics)
    column.add_child(graphics_help)
    var outfit_label: Label = Label.new()
    outfit_label.text = "Henrique • Roupa"
    column.add_child(outfit_label)
    var outfit: OptionButton = OptionButton.new()
    for title: String in ["Original", "Renegado • lenço vermelho", "Operações • colete"]:
        outfit.add_item(title)
    outfit.select(CombatSettings.henrique_outfit)
    outfit.item_selected.connect(func(index: int) -> void:
        CombatSettings.henrique_outfit = index
        CombatSettings.save_preferences()
        for fighter: CharacterBody3D in preview.fighters:
            fighter.rig_adapter._install_roster_visual_identity())
    column.add_child(outfit)
    preload("res://scripts/camera_preferences_ui.gd").build(column)
    preload("res://scripts/controls_audio_preferences_ui.gd").build(column)
    var volume_label: Label = Label.new()
    volume_label.text = "Volume geral"
    column.add_child(volume_label)
    var volume: HSlider = HSlider.new()
    volume.min_value = 0.0
    volume.max_value = 1.0
    volume.step = 0.05
    volume.value = CombatSettings.master_volume
    volume.value_changed.connect(func(value: float) -> void:
        CombatSettings.master_volume = value
        CombatSettings.apply_audio()
        CombatSettings.save_preferences())
    column.add_child(volume)
    dialog.confirmed.connect(dialog.queue_free)
    dialog.canceled.connect(dialog.queue_free)
    add_child(dialog)
    dialog.popup_centered(Vector2i(560, 620))

func _describe_technique(_index: int) -> void:
    if technique_pick == null or technique_pick.item_count == 0: return
    var character = CharacterCatalog.READY[player_pick.selected]
    var data = character.find_jutsu(String(technique_pick.get_item_metadata(technique_pick.selected)))
    if data == null: return
    description.text = "%s • %s • Chakra %d • Recarga %.1f s" % [character.display_name,data.display_name,int(data.chakra_cost),data.cooldown]
