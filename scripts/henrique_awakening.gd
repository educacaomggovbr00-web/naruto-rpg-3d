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
        var timing: Dictionary = fighter.selected_attack.animation_timing(fighter.rig_adapter.manifest) if fighter.attack_active and fighter.selected_attack != null else fighter.rig_adapter.manifest.get("clips", {}).get(fighter.get_special_animation(), {})
        var duration: float = maxf(float(timing.get("duration", 0.58)), 0.01)
        var progress: float = (fighter.attack_elapsed if fighter.attack_active else fighter.specials.elapsed) / duration
        var summon: float = 1.0 - remaining / maxf(definition.transform_duration, 0.01) if transforming else 1.0
        avatar.update_pose(delta, striking, progress, fighter.global_basis.inverse() * fighter.velocity,
            float(timing.get("impact", 0.24)) / duration, summon)

func stop() -> void:
    super.stop()
    if avatar != null:
        avatar.visible = false
        avatar.reset_pose()

func set_quality(level: int) -> void:
    super.set_quality(level)
    if avatar != null:
        avatar.set_quality(level)
