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

func _ready() -> void:
    health_bar.max_value = float(player.call("get_max_health"))
    chakra_bar.max_value = float(player.call("get_max_chakra"))
    _apply_anime_hud_style()


func _apply_anime_hud_style() -> void:
    var definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
    var chakra_color: Color = Color(0.10, 0.58, 1.0)
    if definition != null:
        chakra_color = definition.energy_color

    _style_bar(health_bar, Color("e85846"))
    _style_bar(chakra_bar, chakra_color)

    $Title.add_theme_color_override("font_color", Color("ffd27a"))
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
    rig_label.add_theme_color_override("font_color", Color("b7cadb"))
    fps_label.add_theme_color_override("font_color", Color("d6e4ed"))

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
    health_bar.value = float(player.call("get_health"))
    chakra_bar.value = float(player.call("get_chakra"))

    var locked_target: Node3D = player.call("get_locked_target") as Node3D
    var lock_text: String = "LIVRE"
    if is_instance_valid(locked_target):
        lock_text = locked_target.name

    var animation_state: String = String(player.call("get_animation_state"))
    status_label.text = "LOCK: %s | COMBO: %d | ESTADO: %s" % [
        lock_text,
        int(player.call("get_combo_step")),
        animation_state
    ]

    var sub_cd: float = float(player.call("get_substitution_cooldown"))
    var jutsu_cd: float = float(player.call("get_jutsu_cooldown"))
    resource_label.text = "SUB: %d | CD SUB: %.1f | CD JUTSU: %.1f" % [
        int(player.call("get_substitutions")),
        sub_cd,
        jutsu_cd
    ]

    resource_label.text += " | GUARDA: %d | %s" % [int(player.guard_meter), String(player.specials.selected).to_upper()]
    if is_instance_valid(player.cinematic_owner) and player.cinematic_owner.get("phase") == "clash":
        resource_label.text = "ULT DA CPU — TOQUE ATK OU SUB! VOCÊ %d : CPU %d" % [player.cinematic_owner.cpu_presses, player.cinematic_owner.presses]
    elif player.ultimate.phase == "clash":
        resource_label.text = "ULT — TOQUE ATK! VOCÊ %d : CPU %d | %.1fs | mínimo %d" % [player.ultimate.presses, player.ultimate.cpu_presses, maxf(player.ultimate.definition.clash_duration - player.ultimate.elapsed, 0.0), player.ultimate.definition.clash_presses]
    else:
        resource_label.text += "\nULT: %.1fs | AWK: %s" % [player.ultimate.cooldown, "%.1fs" % player.awakening.remaining if player.awakening.active else "CARREGUE CHK" if player.awakening.eligible() else "VIDA BAIXA + CHK CHEIO" if player.character_definition.has_awakening else "INDISPONÍVEL"]
    var tool_name: String = player.ninja_tools.SLOTS[player.ninja_tools.selected]
    resource_label.text += " | %s: %s" % [tool_name, "∞" if tool_name == "shuriken" else str(player.ninja_tools.stock[tool_name])]
    var labels: Array[String] = ["SHUR", "RAMEN", "PILL", "KUNAI", "BOMB"]
    var controls: Node = get_node("MobileControls")
    if controls.tool_label != labels[player.ninja_tools.selected]:
        controls.tool_label = labels[player.ninja_tools.selected]
        controls.queue_redraw()
    var cpu: Node = get_node("../EnemyDummy")
    status_label.text += " | %s: %d CHK:%d" % [cpu.character_definition.display_name, int(cpu.health), int(cpu.chakra)]

    var combo_hits: int = int(player.call("get_combo_hits"))
    var combo_damage: float = float(player.call("get_combo_damage"))
    combo_label.visible = combo_hits > 0
    if combo_hits > 0:
        combo_label.text = "%d HITS\n%d DANO" % [combo_hits, int(round(combo_damage))]

    if is_instance_valid(rig_adapter) and rig_adapter.has_method("get_rig_status"):
        rig_label.text = String(rig_adapter.call("get_rig_status"))

    fps_label.text = "FPS:%d DC:%d" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
