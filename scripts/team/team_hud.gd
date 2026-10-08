extends CanvasLayer
var fighter: CharacterBody3D
var enemy: CharacterBody3D
var panel: PanelContainer
var support_bar: ProgressBar
var storm_bar: ProgressBar
var names: Label
var status: Label
var buttons: Array[Button] = []
var gauge_labels: Array[Label] = []
var refresh: float = 0.0
var wall_button: Button

func _ready() -> void:
    layer = 12
    panel = PanelContainer.new()
    panel.position = Vector2(400, 226) if GameFlow.arcade_mode == "training" else Vector2(14, 226)
    panel.size = Vector2(370,168 if fighter.team != null and fighter.team.members.size()>1 else 58)
    add_child(panel)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 4)
    panel.add_child(column)
    names = Label.new()
    names.add_theme_font_size_override("font_size", 13)
    names.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    column.add_child(names)
    if fighter.team != null and fighter.team.members.size() > 1:
        var bars: HBoxContainer = HBoxContainer.new()
        column.add_child(bars)
        for caption: String in ["SUPORTE", "STORM"]:
            var group: VBoxContainer = VBoxContainer.new()
            group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            bars.add_child(group)
            var label: Label = Label.new()
            label.text = caption
            label.add_theme_font_size_override("font_size", 11)
            group.add_child(label)
            gauge_labels.append(label)
            var bar: ProgressBar = ProgressBar.new()
            bar.custom_minimum_size = Vector2(170, 10)
            bar.max_value = 100.0
            bar.show_percentage = false
            group.add_child(bar)
            _style_bar(bar, Color("4ecbc1") if caption == "SUPORTE" else Color("ffc569"))
            if caption == "SUPORTE":
                support_bar = bar
            else:
                storm_bar = bar
        var row: HBoxContainer = HBoxContainer.new()
        column.add_child(row)
        var captions: PackedStringArray = ["SUP 1", "SUP 2", "TROCAR"]
        for index: int in range(3):
            var button: Button = Button.new()
            button.text = captions[index]
            button.custom_minimum_size = Vector2(115, 40)
            button.pressed.connect(_command.bind(index))
            row.add_child(button)
            buttons.append(button)
        var special_row: HBoxContainer = HBoxContainer.new()
        column.add_child(special_row)
        for index: int in range(2):
            var button: Button = Button.new()
            button.text = "TEAM ULT" if index == 0 else "AWK EQUIPE"
            button.custom_minimum_size = Vector2(175, 34)
            button.pressed.connect(_command.bind(3 + index))
            special_row.add_child(button)
            buttons.append(button)
    status = Label.new()
    status.add_theme_font_size_override("font_size", 11)
    status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    column.add_child(status)
    if GameFlow.is_story_battle():
        wall_button = Button.new()
        wall_button.text = "CORRER NA PAREDE • FASE 2"
        wall_button.pressed.connect(func():
            var encounter: Node = fighter.get_parent().get_node_or_null("BattleBridge/BossEncounter")
            if encounter != null:
                encounter.start_wall_run())
        column.add_child(wall_button)

func _command(index: int) -> void:
    if fighter.team == null or get_tree().paused:
        return
    match index:
        0, 1: fighter.team.call_support(index)
        2: fighter.team.request_change(0)
        3: fighter.team.start_ultimate()
        4: fighter.team.start_linked_awakening()

func _style_bar(bar: ProgressBar, color: Color) -> void:
    var background: StyleBoxFlat = StyleBoxFlat.new()
    background.bg_color = Color("183747")
    background.set_corner_radius_all(4)
    bar.add_theme_stylebox_override("background", background)
    var fill: StyleBoxFlat = StyleBoxFlat.new()
    fill.bg_color = color
    fill.set_corner_radius_all(4)
    bar.add_theme_stylebox_override("fill", fill)

func _process(delta: float) -> void:
    refresh -= delta
    if refresh > 0.0:
        return
    refresh = .1
    var team: Node = fighter.team
    if team != null and support_bar != null:
        support_bar.value = team.support
        storm_bar.value = team.storm
        gauge_labels[0].text = "SUPORTE %d" % int(team.support)
        gauge_labels[1].text = "STORM %d" % int(team.storm)
        var partner_names: PackedStringArray = []
        var partners: Array[int] = team.partner_indices()
        for index: int in partners:
            partner_names.append(team.members[index].display_name)
        names.text = "EQUIPE • " + " / ".join(partner_names)
        for slot: int in range(2):
            buttons[slot].disabled = slot >= partners.size() or team.support < CombatTeam.SUPPORT_COST or not team.can_act() or team.member_state[partners[slot]].support_cd > 0.0
            buttons[slot].tooltip_text = team.members[partners[slot]].display_name + " • %.1fs" % team.member_state[partners[slot]].support_cd if slot < partners.size() else "Sem parceiro"
        buttons[2].disabled = not team.can_act() or team.support < CombatTeam.SWITCH_COST or team.switch_cooldown > 0.0
        buttons[3].disabled = not team.can_act() or team.storm < 100.0 or team.support < 50.0 or fighter.chakra < 65.0
        buttons[4].disabled = not team.can_act() or team.storm < 100.0 or fighter.health > fighter.max_health * .5 or fighter.chakra < fighter.max_chakra * .8
        status.text = team.last_action if team.action_remaining > 0.0 else "Z/X suporte • C troca • V supremo • B despertar"
        if team.linked_remaining > 0.0:
            status.text = "AWAKENING DA EQUIPE • %.1fs" % team.linked_remaining
    else:
        names.text = "ESTADOS DE COMBATE"
        status.text = "Fogo / água / eletricidade • Armadura • Cenário"
    var states: Node = fighter.get_node_or_null("ElementalStates")
    var has_team: bool = team != null and team.members.size()>1
    var damaged: bool = fighter.battle_condition != null and (fighter.battle_condition.armor_broken or fighter.battle_condition.weapon_broken)
    var encounter: Node = fighter.get_parent().get_node_or_null("BattleBridge/BossEncounter")
    var wall_ready: bool = GameFlow.is_story_battle() and encounter != null and encounter.giant.visible
    panel.visible = has_team or states != null or damaged or wall_ready
    if wall_button != null:
        wall_button.visible = wall_ready
    if states != null:
        status.text = states.summary()
    if fighter.battle_condition != null and fighter.battle_condition.armor_broken:
        names.text += " • ARMADURA ROMPIDA"
    if fighter.battle_condition != null and fighter.battle_condition.weapon_broken:
        names.text += " • ARMA ROMPIDA"
