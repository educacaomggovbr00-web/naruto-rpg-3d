extends "res://scripts/roster_ultimate_controller.gd"

var avatar: SusanooVisual

func _ready() -> void:
    super._ready()
    avatar = SusanooVisual.new()
    avatar.position.y = -0.95
    add_child(avatar)
    avatar.visible = false

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    avatar.visible = phase in ["sequence", "finish"]
    if avatar.visible:
        avatar.update_pose(delta, phase == "finish", elapsed / 0.5)

func cancel(reason: String = "cancelled") -> void:
    super.cancel(reason)
    if avatar != null:
        avatar.visible = false
