extends Node3D
## Shared lightweight Ultimate for non-Naruto fighters.
## It requires a real entry hit before the short cinematic finisher can happen.

var definition: UltimateDefinition = null
var fighter: CharacterBody3D = null
var entry_box: Area3D = null
var target: Node3D = null
var phase: String = ""
var elapsed: float = 0.0
var cooldown: float = 0.0
var opened: bool = false
var cinematic_started: bool = false
var last_result: String = ""
var power_visual: MeshInstance3D = null

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D
    definition = fighter.character_definition.ultimate_definition
    process_physics_priority = 15

    entry_box = Area3D.new()
    entry_box.set_script(preload("res://scripts/combat_hitbox.gd"))
    entry_box.collision_layer = 0
    entry_box.collision_mask = 8 if fighter.collision_layer == 4 else 16

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = definition.hitbox_radius if definition != null else 0.68
    collision.shape = shape
    entry_box.add_child(collision)

    power_visual = MeshInstance3D.new()
    power_visual.set_script(preload("res://scripts/chakra_orb.gd"))
    entry_box.add_child(power_visual)
    power_visual.visible = false

    add_child(entry_box)
    entry_box.top_level = true
    power_visual.call("set_energy_color", _effect_color(definition.effect if definition != null else "chakra"))

func start() -> bool:
    if definition == null or not fighter.character_definition.has_ultimate:
        return false
    if fighter.camera_rig.cinematic_remaining > 0.0:
        return false
    if not phase.is_empty() or cooldown > 0.0 or fighter.chakra < definition.chakra_cost:
        return false
    if not fighter.call("_can_use_movement_action") or fighter.attack_cooldown > 0.0 or not fighter.is_on_floor():
        return false
    if fighter.awakening != null and fighter.awakening.active:
        return false

    fighter.specials.call("cancel")
    fighter.chakra -= definition.chakra_cost
    cooldown = definition.cooldown
    target = null
    last_result = ""
    cinematic_started = false
    _enter("entry")
    return true

func _enter(next_phase: String) -> void:
    phase = next_phase
    elapsed = 0.0
    opened = false
    entry_box.call("deactivate")
    fighter.animation_action_id += 1
    fighter.attack_buffer = 0.0
    fighter.is_guarding = false
    fighter.is_charging_chakra = false
    fighter.jutsu_timer = 0.35
    power_visual.visible = phase in ["entry", "finish"]

    if is_instance_valid(target):
        fighter.camera_rig.call("set_sequence_shot", "clash" if phase == "sequence" else "chain")

func _physics_process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)
    if phase.is_empty():
        return

    if bool(fighter.call("is_defeated")) or fighter.stagger_timer > 0.0:
        cancel("interrupted")
        return

    elapsed += delta
    fighter.jutsu_timer = maxf(fighter.jutsu_timer, delta + 0.12)

    if phase == "entry":
        entry_box.global_position = fighter.global_position + Vector3.UP * 0.65 + fighter.global_basis.z * 0.78
        if not opened and elapsed >= 0.16:
            opened = true
            entry_box.call(
                "activate",
                self,
                definition.entry_damage,
                1.5,
                0.0,
                0.75,
                0.28
            )
        if elapsed >= 0.72:
            cancel("miss_or_block")
        return

    if not is_instance_valid(target) or not bool(target.call("is_targetable")):
        cancel("ko_or_missing_target")
        return
    if float(target.get("invulnerable_timer")) > 0.0:
        cancel("substitution")
        return
    if not target.call("refresh_cinematic_lock", self):
        cancel("lost_lock")
        return

    if phase == "sequence":
        power_visual.visible = true
        entry_box.global_position = (fighter.global_position + target.global_position) * 0.5 + Vector3.UP * 0.65
        power_visual.scale = Vector3.ONE * (1.3 + sin(elapsed * 10.0) * 0.12)
        if elapsed >= definition.sequence_duration:
            _enter("finish")
        return

    if phase == "finish":
        entry_box.global_position = target.global_position + Vector3.UP * 0.55
        if not opened and elapsed >= 0.18:
            opened = true
            target.call("end_cinematic_lock", self)
            entry_box.call(
                "activate",
                self,
                definition.finisher_damage,
                definition.finisher_knockback,
                5.0,
                0.90,
                0.14
            )
            if fighter.combat_feedback != null:
                fighter.combat_feedback.call("spawn_impact", target.global_position + Vector3.UP * 0.6, "slam")
            fighter.camera_rig.call("add_combat_impact", 0.16, 3.5)

        if elapsed >= 0.62:
            cancel("complete")

func on_hitbox_contact(_box: Area3D, victim: Node, dealt: float, blocked: bool) -> void:
    if phase != "entry" or dealt <= 0.0 or blocked or not bool(victim.call("is_targetable")):
        return
    if not victim.has_method("begin_cinematic_lock") or not victim.call("begin_cinematic_lock", self):
        return

    target = victim as Node3D
    cinematic_started = true
    entry_box.call("deactivate")
    fighter.camera_rig.call("begin_sequence", target, definition.sequence_duration + 1.0)
    _enter("sequence")

func on_attack_connected(victim: Node, dealt: float, lift: float) -> void:
    fighter.call("on_attack_connected", victim, dealt, lift)

func get_damage_multiplier() -> float:
    return fighter.call("get_damage_multiplier")

func movement_velocity(delta: float) -> Vector3:
    if phase != "entry":
        return Vector3.ZERO

    var victim: Node3D = fighter.locked_target
    if not is_instance_valid(victim):
        return fighter.global_basis.z * 10.0

    var aim: Vector3 = victim.global_position - fighter.global_position
    aim.y = 0.0
    if aim.length() <= 1.1:
        return Vector3.ZERO

    fighter.call("_face_direction", aim, delta, 12.0)
    return fighter.global_basis.z * 13.0

func animation_clip() -> String:
    if definition == null:
        return "jutsu"
    if phase == "finish":
        return definition.finisher_clip
    if phase == "sequence":
        return "chakra_charge"
    return definition.entry_clip

func cancel(reason: String = "cancelled") -> void:
    if phase.is_empty():
        return

    last_result = reason
    phase = ""
    entry_box.call("deactivate")
    power_visual.visible = false
    power_visual.scale = Vector3.ONE

    if is_instance_valid(target) and target.has_method("end_cinematic_lock"):
        target.call("end_cinematic_lock", self)

    target = null
    fighter.camera_rig.call("end_sequence")
    fighter.jutsu_timer = 0.0
    fighter.attack_buffer = 0.0
    fighter.jump_requested = false
    fighter.animation_action_id += 1

func _exit_tree() -> void:
    if is_instance_valid(target) and target.has_method("end_cinematic_lock"):
        target.call("end_cinematic_lock", self)


func _effect_color(effect: String) -> Color:
    match effect:
        "fire":
            return Color(1.0, 0.22, 0.04)
        "water":
            return Color(0.08, 0.52, 1.0)
        "wind":
            return Color(0.44, 0.94, 0.84)
        "lightning":
            return Color(0.45, 0.80, 1.0)
        "sand", "earth":
            return Color(0.86, 0.61, 0.22)
        "shadow":
            return Color(0.20, 0.10, 0.32)
        "mind":
            return Color(0.96, 0.34, 0.74)
        "insect":
            return Color(0.28, 0.24, 0.12)
        "steel", "puppet", "bone":
            return Color(0.74, 0.80, 0.88)
        "snake":
            return Color(0.38, 0.80, 0.28)
        "taijutsu":
            return Color(0.34, 1.0, 0.38)
        _:
            return fighter.character_definition.energy_color if fighter != null else Color(0.20, 0.65, 1.0)
