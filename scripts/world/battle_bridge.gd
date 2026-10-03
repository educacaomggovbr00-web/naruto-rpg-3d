extends Node
## No alternative combat controller: missions use main.tscn unchanged.
var finished: bool = false

func _ready() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.layer = 30
    var button: Button = Button.new()
    button.text = "ALDEIA"
    button.position = Vector2(515, 12)
    button.custom_minimum_size = Vector2(155, 46)
    button.pressed.connect(GameFlow.enter_world)
    layer.add_child(button)
    add_child(layer)
    if not GameFlow.pending_battle.is_empty() and int(GameFlow.progress.supplies) > 0:
        var fighter: Node = get_parent().get_node("Player")
        fighter.ninja_tools.stock.bomb += 1
        fighter.ninja_tools.stock.food_pills += 1
        GameFlow.progress.supplies -= 1
        GameFlow.save_progress()

func _physics_process(_delta: float) -> void:
    if finished or GameFlow.pending_battle.is_empty():
        return
    var fighter: Node = get_parent().get_node("Player")
    var cpu: Node = get_parent().get_node("EnemyDummy")
    if fighter.defeated or not cpu.targetable:
        finished = true
        GameFlow.finish_battle(not cpu.targetable and not fighter.defeated)
