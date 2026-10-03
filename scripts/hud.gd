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

func _process(_delta: float) -> void:
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

    resource_label.text += " | GUARDA: %d | %s" % [int(player.guard_meter), "RASENGAN" if player.specials.selected == "rasengan" else "DEMON WIND"]
    if player.ultimate.phase == "clash":
        resource_label.text = "ULTIMATE — TOQUE ATK: %d / %d" % [player.ultimate.presses, player.ultimate.definition.clash_presses]
    else:
        resource_label.text += " | ULT: %.1fs" % player.ultimate.cooldown
    var cpu: Node = get_node("../EnemyDummy")
    status_label.text += " | CPU: %d" % int(cpu.health)

    var combo_hits: int = int(player.call("get_combo_hits"))
    var combo_damage: float = float(player.call("get_combo_damage"))
    combo_label.visible = combo_hits > 0
    if combo_hits > 0:
        combo_label.text = "%d HITS\n%d DANO" % [combo_hits, int(round(combo_damage))]

    if is_instance_valid(rig_adapter) and rig_adapter.has_method("get_rig_status"):
        rig_label.text = String(rig_adapter.call("get_rig_status"))

    fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
