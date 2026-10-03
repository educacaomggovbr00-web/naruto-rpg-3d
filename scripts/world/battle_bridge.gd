extends Node
## No alternative combat controller: missions use main.tscn unchanged.
var finished: bool = false

func _ready() -> void:
    var audio: Node = Node.new()
    audio.name = "AudioManager"
    audio.set_script(preload("res://scripts/audio_manager.gd"))
    get_parent().add_child.call_deferred(audio)
    var layer: CanvasLayer = CanvasLayer.new()
    layer.layer = 30
    var button: Button = Button.new()
    button.text = "ALDEIA"
    button.position = Vector2(515, 12)
    button.custom_minimum_size = Vector2(155, 46)
    button.pressed.connect(GameFlow.enter_world)
    layer.add_child(button)
    add_child(layer)
    var versus: Button = Button.new()
    versus.text = "VERSUS"
    versus.position = Vector2(680, 12)
    versus.custom_minimum_size = Vector2(140, 46)
    versus.pressed.connect(GameFlow.enter_selection)
    layer.add_child(versus)
    if not GameFlow.pending_battle.is_empty() and int(GameFlow.progress.supplies) > 0:
        var fighter: Node = get_parent().get_node("Player")
        fighter.ninja_tools.stock.bomb += 1
        fighter.ninja_tools.stock.food_pills += 1
        GameFlow.progress.supplies -= 1
        GameFlow.save_progress()

func _physics_process(_delta: float) -> void:
    if finished or (GameFlow.pending_battle.is_empty() and not GameFlow.versus_mode):
        return
    var fighter: Node = get_parent().get_node("Player")
    var cpu: Node = get_parent().get_node("EnemyDummy")
    if fighter.defeated or not cpu.targetable:
        finished = true
        GameFlow.finish_battle(not cpu.targetable and not fighter.defeated)
