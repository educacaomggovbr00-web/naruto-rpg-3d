extends "res://scripts/roster_awakening.gd"

var avatar: SusanooVisual
var selected_form: int = 3

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
        # Build up through actual forms during the existing interruptible summon.
        var summon_phase: float = 1.0 - remaining / maxf(definition.transform_duration, 0.01) if transforming else 1.0
        avatar.set_form(mini(selected_form, int(summon_phase * 4.0)) if transforming else selected_form)
        var striking: bool = fighter.attack_active or fighter.specials.current == "henrique_susanoo_slash"
        var timing: Dictionary = fighter.selected_attack.animation_timing(fighter.rig_adapter.manifest) if fighter.attack_active and fighter.selected_attack != null else fighter.rig_adapter.manifest.get("clips", {}).get(fighter.get_special_animation(), {})
        var duration: float = maxf(float(timing.get("duration", 0.58)), 0.01)
        var progress: float = (fighter.attack_elapsed if fighter.attack_active else fighter.specials.elapsed) / duration
        var summon: float = 1.0 - remaining / maxf(definition.transform_duration, 0.01) if transforming else 1.0
        avatar.update_pose(delta, striking, progress, fighter.global_basis.inverse() * fighter.velocity,
            float(timing.get("impact", 0.24)) / duration, summon, fighter.is_guarding)

func stop() -> void:
    super.stop()
    if avatar != null:
        avatar.visible = false
        avatar.reset_pose()

func set_quality(level: int) -> void:
    super.set_quality(level)
    if avatar != null:
        avatar.set_quality(level)


func _unhandled_input(event: InputEvent) -> void:
    if fighter.name != "Player":
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_9:
        cycle_form()
        get_viewport().set_input_as_handled()

func cycle_form() -> void:
    selected_form = (selected_form + 1) % 4
    avatar.set_form(selected_form)

func movement_multiplier() -> float:
    return [1.15, 1.10, 1.04, 1.08][selected_form] if active else 1.0

func damage_multiplier() -> float:
    return [1.10, 1.20, 1.35, 1.30][selected_form] if active else 1.0
