extends CanvasLayer

@onready var player: Node = $"../Player"
@onready var health_bar: ProgressBar = $HealthBar
@onready var chakra_bar: ProgressBar = $ChakraBar
@onready var status_label: Label = $Status
@onready var resource_label: Label = $Resources
@onready var combo_label: Label = $ComboCounter
@onready var rig_label: Label = $RigStatus
@onready var rig_adapter: Node = $"../Player/RiggedCharacterAdapter"
@onready var fps_label: Label = $FPS
@onready var enemy: Node = $"../EnemyDummy"

var enemy_health_bar: ProgressBar
var enemy_name_label: Label
var event_label: Label
var event_remaining: float = 0.0
var last_enemy_state: String = ""
var last_player_state: String = ""
var guard_bar: ProgressBar
var enemy_guard_bar: ProgressBar
var mode_label: Label

func _ready() -> void:
    health_bar.max_value = float(player.call("get_max_health"))
    chakra_bar.max_value = float(player.call("get_max_chakra"))
    _build_backplates()
    _apply_anime_hud_style()
    for bar: ProgressBar in [health_bar,enemy_health_bar]:
        var tail: Control = Control.new()
        tail.name = "DamageTail"
        tail.set_script(preload("res://scripts/damage_tail.gd"))
        bar.add_child(tail)
    _build_combat_indicators()

    var player_definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
    var enemy_definition: CharacterDefinition = enemy.call("get_character_definition") as CharacterDefinition
    if player_definition != null and enemy_definition != null:
        $Title.text = "%s  VS  %s" % [
            player_definition.display_name.to_upper(),
            enemy_definition.display_name.to_upper()
        ]

    rig_label.visible = "--debug-hud" in OS.get_cmdline_user_args()
    fps_label.visible = rig_label.visible
    event_label = Label.new()
    event_label.position = Vector2(480,225)
    event_label.size = Vector2(340,40)
    event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    event_label.add_theme_font_size_override("font_size",22)
    event_label.add_theme_color_override("font_color",Color("ffd07a"))
    event_label.add_theme_color_override("font_shadow_color",Color("091b29"))
    event_label.add_theme_constant_override("shadow_offset_x",2)
    event_label.add_theme_constant_override("shadow_offset_y",2)
    event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(event_label)
    event_label.visible = false
    player.combat_hit_recorded.connect(_confirmed_hit)


func _hud_panel(background: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    return style

func _build_combat_indicators() -> void:
    guard_bar = ProgressBar.new()
    guard_bar.position = Vector2(20, 216)
    guard_bar.size = Vector2(290, 9)
    guard_bar.show_percentage = false
    guard_bar.add_theme_font_size_override("font_size", 1)
    guard_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _style_bar(guard_bar, Color("51c9b0"))
    add_child(guard_bar)
    enemy_guard_bar = ProgressBar.new()
    enemy_guard_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    enemy_guard_bar.offset_left = -380
    enemy_guard_bar.offset_right = -30
    enemy_guard_bar.offset_top = 212
    enemy_guard_bar.offset_bottom = 221
    enemy_guard_bar.show_percentage = false
    enemy_guard_bar.add_theme_font_size_override("font_size", 1)
    enemy_guard_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _style_bar(enemy_guard_bar, Color("51c9b0"))
    add_child(enemy_guard_bar)
    mode_label = Label.new()
    mode_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    mode_label.offset_left = -210
    mode_label.offset_right = 210
    mode_label.offset_top = 70
    mode_label.offset_bottom = 96
    mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode_label.add_theme_font_size_override("font_size", 15)
    mode_label.add_theme_color_override("font_color", Color("ffd369"))
    mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(mode_label)
    # Combo feedback has its own lane below the enemy's vitals.
    combo_label.offset_top = 238
    combo_label.offset_bottom = 320

func _build_backplates() -> void:
    var vitals: PanelContainer = PanelContainer.new()
    vitals.position = Vector2(10, 8)
    vitals.size = Vector2(318, 142)
    vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vitals.add_theme_stylebox_override("panel", _hud_panel(Color(0.012, 0.032, 0.052, 0.76), Color(0.25, 0.52, 0.64, 0.42), 14))
    add_child(vitals)
    move_child(vitals, 0)

    var info: PanelContainer = PanelContainer.new()
    info.position = Vector2(10, 152)
    info.size = Vector2(480, 64)
    info.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_theme_stylebox_override("panel", _hud_panel(Color(0.012, 0.030, 0.048, 0.66), Color(0.24, 0.45, 0.55, 0.30), 12))
    add_child(info)
    move_child(info, 1)

    var enemy_panel: PanelContainer = PanelContainer.new()
    enemy_panel.anchor_left = 1.0
    enemy_panel.anchor_right = 1.0
    enemy_panel.offset_left = -395.0
    enemy_panel.offset_right = -20.0
    enemy_panel.offset_top = 128.0
    enemy_panel.offset_bottom = 205.0
    enemy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    enemy_panel.add_theme_stylebox_override("panel", _hud_panel(Color(0.012, 0.032, 0.052, 0.78), Color(0.62, 0.28, 0.24, 0.48), 14))
    add_child(enemy_panel)

    var enemy_box: VBoxContainer = VBoxContainer.new()
    enemy_box.add_theme_constant_override("separation", 5)
    enemy_panel.add_child(enemy_box)

    enemy_name_label = Label.new()
    enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    enemy_name_label.add_theme_font_size_override("font_size", 15)
    enemy_name_label.add_theme_color_override("font_color", Color("ffd9c8"))
    enemy_box.add_child(enemy_name_label)

    enemy_health_bar = ProgressBar.new()
    enemy_health_bar.custom_minimum_size = Vector2(350, 22)
    enemy_health_bar.show_percentage = false
    enemy_box.add_child(enemy_health_bar)
    _style_bar(enemy_health_bar, Color("d84d43"))

    $Controls.visible = false
    $Title.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_font_size_override("font_size", 13)
    resource_label.add_theme_font_size_override("font_size", 12)
    status_label.size.x = 455
    resource_label.size.x = 455
    status_label.clip_text = true
    resource_label.clip_text = true
    rig_label.add_theme_font_size_override("font_size", 11)
    fps_label.add_theme_font_size_override("font_size", 12)

func _apply_anime_hud_style() -> void:
    var definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
    var chakra_color: Color = Color(0.10, 0.58, 1.0)
    if definition != null:
        chakra_color = definition.energy_color

    _style_bar(health_bar, Color("e85846"))
    _style_bar(chakra_bar, chakra_color)

    $Title.add_theme_color_override("font_color", Color("ffd07a"))
    $Title.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.06, 0.95))
    $Title.add_theme_constant_override("shadow_offset_x", 2)
    $Title.add_theme_constant_override("shadow_offset_y", 2)

    for label: Label in [$HealthText, $ChakraText, status_label, resource_label]:
        label.add_theme_color_override("font_color", Color("f5f1e8"))
        label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.06, 0.85))
        label.add_theme_constant_override("shadow_offset_x", 1)
        label.add_theme_constant_override("shadow_offset_y", 1)

    combo_label.add_theme_color_override("font_color", Color("ffd369"))
    combo_label.add_theme_color_override("font_shadow_color", Color("32150b"))
    combo_label.add_theme_constant_override("shadow_offset_x", 3)
    combo_label.add_theme_constant_override("shadow_offset_y", 3)
    rig_label.add_theme_color_override("font_color", Color(0.64, 0.76, 0.82, 0.82))
    fps_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.92, 0.86))

func _style_bar(bar: ProgressBar, fill_color: Color) -> void:
    var background: StyleBoxFlat = StyleBoxFlat.new()
    background.bg_color = Color(0.025, 0.035, 0.06, 0.82)
    background.border_color = Color(0.78, 0.84, 0.91, 0.42)
    background.set_border_width_all(1)
    background.corner_radius_top_left = 8
    background.corner_radius_top_right = 8
    background.corner_radius_bottom_left = 8
    background.corner_radius_bottom_right = 8
    bar.add_theme_stylebox_override("background", background)

    var fill: StyleBoxFlat = StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.corner_radius_top_left = 7
    fill.corner_radius_top_right = 7
    fill.corner_radius_bottom_left = 7
    fill.corner_radius_bottom_right = 7
    bar.add_theme_stylebox_override("fill", fill)

var refresh_timer: float = 0.0
func show_combat_event(text: String) -> void:
    event_label.text = text
    event_remaining = 1.1
    event_label.modulate.a = 1.0
    event_label.visible = true

func _confirmed_hit(_amount: float, guarded: bool) -> void:
    if guarded: return
    if player.grab_attack: show_combat_event("ARREMESSO")
    elif player.attack_counter_bonus > 1.0 and player.attack_active: show_combat_event("CONTRA-ATAQUE")

func _update_combat_events(delta: float) -> void:
    event_remaining = maxf(event_remaining-delta,0.0)
    event_label.visible = event_remaining > 0.0
    event_label.modulate.a = minf(event_remaining*4.0,1.0)
    var cpu_state: String = enemy.get_combat_state()
    var hero_state: String = player.get_combat_state()
    if cpu_state != last_enemy_state and cpu_state == "guard_break": show_combat_event("GUARDA ROMPIDA")
    elif hero_state != last_player_state and hero_state == "guard_break": show_combat_event("SUA GUARDA ROMPEU")
    last_enemy_state = cpu_state
    last_player_state = hero_state

func _process(delta: float) -> void:
    _update_combat_events(delta)
    refresh_timer -= delta
    if refresh_timer > 0.0:
        return
    refresh_timer = 0.10
    var definition: CharacterDefinition = player.get_character_definition()
    $Title.text = "%s  VS  %s" % [definition.display_name.to_upper(), enemy.get_character_definition().display_name.to_upper()]
    health_bar.max_value = player.max_health
    chakra_bar.max_value = player.max_chakra
    health_bar.value = float(player.call("get_health"))
    chakra_bar.value = float(player.call("get_chakra"))
    $HealthText.text = "VIDA  %d / %d" % [int(player.health), int(player.max_health)]
    $ChakraText.text = "CHAKRA  %d / %d" % [int(player.chakra), int(player.max_chakra)]
    guard_bar.value = player.guard_meter
    enemy_guard_bar.value = enemy.guard_meter
    guard_bar.modulate = Color("ff6757") if player.guard_meter < 25.0 else Color.WHITE
    enemy_guard_bar.modulate = Color("ff6757") if enemy.guard_meter < 25.0 else Color.WHITE
    mode_label.text = "SOBREVIVÊNCIA • DUELO %d" % GameFlow.survival_wave if GameFlow.versus_mode and GameFlow.battle_mode == "survival" else "TREINAMENTO • CHAKRA ∞" if GameFlow.versus_mode and GameFlow.battle_mode == "training" else ""
    if player.techniques.feedback_timer > 0.0:
        mode_label.text = player.techniques.feedback_text

    var locked_target: Node3D = player.call("get_locked_target") as Node3D
    var lock_text: String = "LIVRE"
    if is_instance_valid(locked_target):
        lock_text = locked_target.get_character_definition().display_name if locked_target.has_method("get_character_definition") else "ALVO"

    status_label.text = "ALVO: %s  •  COMBO %d  •  GUARDA %d" % [
        lock_text,
        int(player.call("get_combo_step")),
        int(player.guard_meter)
    ]

    var sub_cd: float = float(player.call("get_substitution_cooldown"))
    var jutsu_cd: float = float(player.call("get_jutsu_cooldown"))
    var technique: JutsuDefinition = player.character_definition.find_jutsu(String(player.specials.selected))
    if not rig_label.visible:
        status_label.text = "%s  •  %s" % [technique.display_name if technique != null else "TÉCNICA NINJA", "RECARGA %.1fs" % jutsu_cd if jutsu_cd > 0.0 else "PRONTO"]
    resource_label.text = "SUB %d  •  GUARDA %d  •  %s  •  CD %.1f/%.1f" % [
        int(player.call("get_substitutions")),
        int(player.guard_meter),
        (player.character_definition.find_jutsu(String(player.specials.selected)).display_name if player.character_definition.find_jutsu(String(player.specials.selected)) != null else String(player.specials.selected).to_upper()),
        sub_cd,
        jutsu_cd
    ]
    if is_instance_valid(player.cinematic_owner) and player.cinematic_owner.get("phase") == "clash":
        resource_label.text = "ULT DA CPU — TOQUE ATK OU SUB! VOCÊ %d : CPU %d" % [player.cinematic_owner.cpu_presses, player.cinematic_owner.presses]
    elif player.ultimate.phase == "clash":
        resource_label.text = "ULT — TOQUE ATK! VOCÊ %d : CPU %d | %.1fs | mínimo %d" % [player.ultimate.presses, player.ultimate.cpu_presses, maxf(player.ultimate.definition.clash_duration - player.ultimate.elapsed, 0.0), player.ultimate.definition.clash_presses]
    else:
        var awakening_text: String = "%.1f" % player.awakening.remaining if player.awakening.active else "PRONTO" if player.awakening.eligible() else "—"
        resource_label.text += "  •  ULT %.1f  •  AWK %s" % [player.ultimate.cooldown, awakening_text]
    if player.awakening.active and player.awakening.has_method("cycle_form"):
        resource_label.text += " • " + SusanooVisual.FORM_NAMES[player.awakening.selected_form]
    var tool_name: String = player.ninja_tools.SLOTS[player.ninja_tools.selected]
    resource_label.text += "  •  %s %s" % [tool_name.to_upper(), "∞" if tool_name == "shuriken" else str(player.ninja_tools.stock[tool_name])]
    var cinematic_clash: bool = (is_instance_valid(player.cinematic_owner) and player.cinematic_owner.get("phase") == "clash") or player.ultimate.phase == "clash"
    if not rig_label.visible and not cinematic_clash:
        resource_label.text = "SUB %d%s  •  GUARDA %d  •  %s %s  •  ULT %s" % [player.substitutions," (%.1fs)" % sub_cd if sub_cd > 0 else "",int(player.guard_meter),tool_name.to_upper(),"∞" if tool_name == "shuriken" else str(player.ninja_tools.stock[tool_name]),"%.1fs" % player.ultimate.cooldown if player.ultimate.cooldown > 0 else "PRONTO"]
        if player.awakening.active:
            status_label.text = "%s  •  %.1fs" % [SusanooVisual.FORM_NAMES[player.awakening.selected_form] if player.awakening.has_method("cycle_form") else "DESPERTAR",player.awakening.remaining]
    var labels: Array[String] = ["SHUR", "RAMEN", "PILL", "KUNAI", "BOMB"]
    var controls: Node = get_node("MobileControls")
    controls.cooldowns = {"jutsu":player.jutsu_cooldown,"dodge":player.dodge_cooldown,"sub":player.substitution_cooldown,"grab":player.techniques.cooldown}
    controls.queue_redraw()
    var form_button: String = "FORMA" if player.awakening.active and player.awakening.has_method("cycle_form") else "AWK"
    if controls.awakening_label != form_button:
        controls.awakening_label = form_button
        controls.queue_redraw()
    if controls.tool_label != labels[player.ninja_tools.selected]:
        controls.tool_label = labels[player.ninja_tools.selected]
        controls.queue_redraw()
    var cpu: Node = enemy
    enemy_health_bar.max_value = maxf(float(cpu.max_health), 1.0)
    enemy_health_bar.value = clampf(float(cpu.health), 0.0, enemy_health_bar.max_value)
    var enemy_definition: CharacterDefinition = cpu.call("get_character_definition") as CharacterDefinition
    var enemy_state: String = ""
    if bool(cpu.get("guarding")):
        enemy_state = "  •  DEF"
    elif is_instance_valid(cpu.get("awakening")) and bool(cpu.awakening.active):
        enemy_state = "  •  AWK"
    enemy_name_label.text = "%s  %d/%d%s" % [
        enemy_definition.display_name.to_upper() if enemy_definition != null else "CPU",
        int(cpu.health),
        int(cpu.max_health),
        enemy_state
    ]
    if GameFlow.arcade_mode == "mob":
        var bridge: Node = get_parent().get_node("BattleBridge")
        var total: float = 0.0
        var remaining: float = 0.0
        var alive: int = 0
        for actor: CharacterBody3D in bridge.mob_enemies:
            total += actor.max_health
            remaining += actor.health
            alive += int(actor.targetable)
        enemy_health_bar.max_value = maxf(total, 1.0)
        enemy_health_bar.value = remaining
        enemy_name_label.text = "ESQUADRÃO • %d NINJAS • %d/%d" % [alive, int(remaining), int(total)]

    var combo_hits: int = int(player.call("get_combo_hits"))
    var combo_damage: float = float(player.call("get_combo_damage"))
    combo_label.visible = combo_hits > 0
    if combo_hits > 0:
        combo_label.text = "%d HITS\n%d DANO" % [combo_hits, int(round(combo_damage))]

    if is_instance_valid(rig_adapter) and rig_adapter.has_method("get_rig_status"):
        rig_label.text = String(rig_adapter.call("get_rig_status"))

    fps_label.text = "FPS:%d DC:%d" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )
