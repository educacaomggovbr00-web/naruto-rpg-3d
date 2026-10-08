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
var guard_bar: ProgressBar
var enemy_guard_bar: ProgressBar
var mode_label: Label

func _ready() -> void:
    health_bar.max_value = float(player.call("get_max_health"))
    chakra_bar.max_value = float(player.call("get_max_chakra"))
    _build_backplates()
    _apply_anime_hud_style()
    _build_combat_indicators()

    var player_definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
    var enemy_definition: CharacterDefinition = enemy.call("get_character_definition") as CharacterDefinition
    if player_definition != null and enemy_definition != null:
        $Title.text = "%s  VS  %s" % [
            player_definition.display_name.to_upper(),
            enemy_definition.display_name.to_upper()
        ]

    rig_label.visible = false
    fps_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
        rig_label.visible = not rig_label.visible
        fps_label.visible = rig_label.visible


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
    info.size = Vector2(555, 64)
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
func _process(delta: float) -> void:
    refresh_timer -= delta
    if refresh_timer > 0.0:
        return
    refresh_timer = 0.10
    health_bar.max_value = float(player.call("get_max_health"))
    chakra_bar.max_value = float(player.call("get_max_chakra"))
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
        lock_text = locked_target.name

    status_label.text = "ALVO: %s  •  COMBO %d  •  GUARDA %d" % [
        lock_text,
        int(player.call("get_combo_step")),
        int(player.guard_meter)
    ]

    var sub_cd: float = float(player.call("get_substitution_cooldown"))
    var jutsu_cd: float = float(player.call("get_jutsu_cooldown"))
    var selected_jutsu: JutsuDefinition = player.character_definition.find_jutsu(String(player.specials.selected))
    var jutsu_name: String = selected_jutsu.display_name.substr(0, 22) if selected_jutsu != null else String(player.specials.selected).to_upper()
    resource_label.text = "SUB %d  •  %s %s" % [
        int(player.call("get_substitutions")),
        jutsu_name,
        "%.1fs" % jutsu_cd if jutsu_cd > 0.0 else "PRONTO" if selected_jutsu != null and player.chakra >= selected_jutsu.chakra_cost else "CARREGUE CHK"
    ]
    if is_instance_valid(player.cinematic_owner) and player.cinematic_owner.get("phase") == "clash":
        resource_label.text = "ULT DA CPU — TOQUE ATK OU SUB! VOCÊ %d : CPU %d" % [player.cinematic_owner.cpu_presses, player.cinematic_owner.presses]
    elif player.ultimate.phase == "clash":
        resource_label.text = "ULT — TOQUE ATK! VOCÊ %d : CPU %d | %.1fs | mínimo %d" % [player.ultimate.presses, player.ultimate.cpu_presses, maxf(player.ultimate.definition.clash_duration - player.ultimate.elapsed, 0.0), player.ultimate.definition.clash_presses]
    else:
        var awakening_text: String = "%.1f" % player.awakening.remaining if player.awakening.active else "PRONTO" if player.awakening.eligible() else "—"
        resource_label.text += "  •  ULT %s  •  AWK %s" % ["%.1fs" % player.ultimate.cooldown if player.ultimate.cooldown > 0.0 else "PRONTO" if player.chakra >= 80.0 else "CHK", awakening_text]
    var labels: Array[String] = ["SHUR", "RAMEN", "PILL", "KUNAI", "BOMB"]
    var controls: Node = get_node("MobileControls")
    controls.cooldowns = {"jutsu": player.jutsu_cooldown, "dodge": player.dodge_cooldown, "sub": player.substitution_cooldown, "grab": player.techniques.cooldown}
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
