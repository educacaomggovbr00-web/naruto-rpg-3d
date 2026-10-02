extends CanvasLayer

@onready var player = $"../Player"
@onready var chakra_bar: ProgressBar = $ChakraBar
@onready var status_label: Label = $Status

func _ready() -> void:
    chakra_bar.max_value = player.max_chakra

func _process(_delta: float) -> void:
    chakra_bar.value = player.chakra

    var lock_text := "LIVRE"
    if is_instance_valid(player.locked_target):
        lock_text = player.locked_target.name

    status_label.text = "LOCK: %s   |   COMBO: %d" % [lock_text, player.combo_step]
