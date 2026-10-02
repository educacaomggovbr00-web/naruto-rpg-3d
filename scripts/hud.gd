extends CanvasLayer

@onready var player: Node = $"../Player"
@onready var health_bar: ProgressBar = $HealthBar
@onready var chakra_bar: ProgressBar = $ChakraBar
@onready var status_label: Label = $Status
@onready var resource_label: Label = $Resources
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

    var state_text: String = ""
    if bool(player.call("get_is_charging")):
        state_text = " | CARREGANDO"
    elif bool(player.call("get_is_guarding")):
        state_text = " | DEFESA"

    status_label.text = "LOCK: %s | COMBO: %d%s" % [
        lock_text,
        int(player.call("get_combo_step")),
        state_text
    ]

    var sub_cd: float = float(player.call("get_substitution_cooldown"))
    var jutsu_cd: float = float(player.call("get_jutsu_cooldown"))
    resource_label.text = "SUB: %d | CD SUB: %.1f | CD JUTSU: %.1f" % [
        int(player.call("get_substitutions")),
        sub_cd,
        jutsu_cd
    ]

    fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
