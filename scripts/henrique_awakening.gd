extends "res://scripts/roster_awakening.gd"

var avatar: SusanooVisual

func _ready() -> void:
    super._ready()
    avatar = SusanooVisual.new()
    avatar.position.y = -0.95
    add_child(avatar)
    avatar.visible = false

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    avatar.visible = active or transforming
    if avatar.visible:
        var striking: bool = fighter.attack_active or fighter.specials.current == "henrique_susanoo_slash"
        var progress: float = fighter.attack_elapsed / maxf(fighter.attack_duration, 0.01) if fighter.attack_active else fighter.specials.elapsed / maxf(fighter.specials.duration, 0.01)
        avatar.update_pose(delta, striking, progress)

func stop() -> void:
    super.stop()
    if avatar != null:
        avatar.visible = false

func set_quality(level: int) -> void:
    super.set_quality(level)
    if avatar != null:
        avatar.set_quality(level)
