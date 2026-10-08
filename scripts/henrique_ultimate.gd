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
        var timing: Dictionary = _clip_timing(definition.finisher_clip)
        var duration: float = maxf(float(timing.get("duration", 0.62)), 0.01)
        avatar.update_pose(delta, phase == "finish", elapsed / duration, Vector3.ZERO,
            float(timing.get("impact", 0.28)) / duration)

func cancel(reason: String = "cancelled") -> void:
    super.cancel(reason)
    if avatar != null:
        avatar.visible = false
        avatar.reset_pose()
