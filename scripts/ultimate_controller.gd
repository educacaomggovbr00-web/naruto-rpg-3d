extends Node3D
## Shared confirmed-entry Ultimate lifecycle. Choreography is a licensed-clip adaptation.
var definition: UltimateDefinition = preload("res://assets/combat/naruto_handbook.tres")
var fighter: CharacterBody3D
var entry_box: Area3D
var entry_clone: CharacterBody3D = null
var entry_direction: Vector3 = Vector3.BACK
var target: Node3D = null
var phase: String = ""
var elapsed: float = 0.0
var cooldown: float = 0.0
var presses: int = 0
var opened: bool = false
var cinematic_started: bool = false
var last_result: String = ""
var owned_clones: Array[CharacterBody3D] = []
var activation_serial: int = 0
var last_press_msec: int = -1000

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D
    process_physics_priority = 15
    entry_box = Area3D.new()
    entry_box.set_script(preload("res://scripts/combat_hitbox.gd"))
    entry_box.collision_layer = 0
    entry_box.collision_mask = 16
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = 0.65
    collision.shape = shape
    entry_box.add_child(collision)
    add_child(entry_box)
    entry_box.top_level = true

func start() -> bool:
    if not phase.is_empty() or cooldown > 0.0 or fighter.chakra < definition.chakra_cost or not fighter.call("_can_use_movement_action") or fighter.attack_cooldown > 0.0 or not fighter.is_on_floor():
        return false
    # Sealed Power needs separate verified choreography; do not relabel Handbook.
    if fighter.get("awakening") != null and fighter.awakening.active:
        return false
    fighter.specials.call("cancel")
    fighter.chakra -= definition.chakra_cost
    cooldown = definition.cooldown
    activation_serial += 1
    last_result = ""
    target = null
    presses = 0
    cinematic_started = false
    _enter("entry")
    return true

func _enter(next: String) -> void:
    phase = next
    elapsed = 0.0
    opened = false
    entry_box.call("deactivate")
    fighter.animation_action_id += 1
    fighter.attack_buffer = 0.0
    fighter.is_guarding = false
    fighter.is_charging_chakra = false
    fighter.jutsu_timer = 0.2
    if is_instance_valid(target):
        fighter.camera_rig.call("set_sequence_shot", phase)

func _physics_process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)
    if phase.is_empty():
        return
    if fighter.defeated or fighter.stagger_timer > 0.0:
        cancel("interrupted")
        return
    if phase != "entry":
        if not is_instance_valid(target) or not bool(target.call("is_targetable")):
            cancel("ko_or_missing_target")
            return
        if float(target.get("invulnerable_timer")) > 0.0:
            cancel("substitution")
            return
        if not (phase == "finish" and opened) and not target.call("refresh_cinematic_lock", self):
            cancel("lost_lock")
            return
    elapsed += delta
    fighter.jutsu_timer = maxf(fighter.jutsu_timer, delta + 0.1)
    var clip: String = animation_clip()
    var timing: Dictionary = fighter.rig_adapter.manifest["clips"][clip]
    var bone: String = definition.finisher_bone if phase == "finish" else definition.entry_bone
    entry_box.global_position = fighter.rig_adapter.call("get_hand_world_position", bone)
    entry_box.global_position += fighter.global_basis.z * 0.16
    if phase == "entry":
        if not opened and elapsed >= float(timing["impact"]):
            opened = true
            for clone: CharacterBody3D in fighter.specials.clones:
                if not clone.active:
                    entry_clone = clone
                    clone.call("present", fighter.global_position + fighter.global_basis.z * 0.8, fighter.rotation.y, 1.2, "air_attack_1")
                    owned_clones.append(clone)
                    entry_direction = fighter.global_basis.z
                    entry_box.call("activate", self, definition.entry_damage, 0.0, 0.0, 1.2, 0.85)
                    break
            if entry_clone == null:
                cancel("pool_busy")
                return
        if is_instance_valid(entry_clone) and entry_clone.active:
            _move_entry_clone(delta)
        if phase == "entry" and elapsed >= 1.15:
            cancel("miss_or_block")
    elif phase == "clash":
        if elapsed >= definition.clash_duration:
            if presses < definition.clash_presses:
                cancel("clash_lost")
            else:
                _enter("dogpile")
                _summon(Vector3(-0.45, 0, -0.7), 0.05, "attack_2", 6.0)
                _summon(Vector3(0.45, 0, -0.7), 0.25, "attack_3", 6.0)
    elif phase == "dogpile" and elapsed >= definition.dogpile_duration:
        _recycle_clones()
        _enter("chain")
        for i: int in range(3):
            for clone: CharacterBody3D in fighter.specials.clones:
                if not clone.active:
                    clone.call("present", fighter.global_position - fighter.global_basis.z * (0.8 + float(i) * 0.75), fighter.rotation.y, definition.chain_duration + 0.1, "guard")
                    owned_clones.append(clone)
                    break
    elif phase == "chain" and elapsed >= definition.chain_duration:
        _recycle_clones()
        _enter("finish")
    elif phase == "finish":
        if not opened and elapsed >= float(timing["impact"]):
            opened = true
            # Unlock before physical final hit so knockback is not suppressed.
            target.call("end_cinematic_lock", self)
            entry_box.call("activate", self, definition.finisher_damage, 15.0, 5.0, 0.9, float(timing.get("active", 0.09)))
        if opened:
            # The finisher still needs a real collision and may miss after escape.
            if elapsed >= float(timing["duration"]) + 0.2:
                cancel("complete")

func on_hitbox_contact(_box: Area3D, victim: Node, dealt: float, blocked: bool) -> void:
    if phase != "entry" or dealt <= 0.0 or blocked or not bool(victim.call("is_targetable")):
        return
    if not victim.has_method("begin_cinematic_lock") or not victim.call("begin_cinematic_lock", self):
        return
    target = victim as Node3D
    entry_box.call("deactivate")
    _recycle_clones()
    entry_clone = null
    cinematic_started = true
    fighter.camera_rig.call("begin_sequence", target, 6.0)
    _enter("clash")

func on_attack_connected(victim: Node, dealt: float, lift: float) -> void:
    fighter.call("on_attack_connected", victim, dealt, lift)

func get_damage_multiplier() -> float:
    return fighter.call("get_damage_multiplier")

func press_attack() -> void:
    # Ignore echoes/events closer than 50ms; touchscreen ATK and keyboard share this.
    var now: int = Time.get_ticks_msec()
    if phase == "clash" and now - last_press_msec >= 50:
        presses += 1
        last_press_msec = now

func animation_clip() -> String:
    if phase == "entry":
        return definition.entry_clip
    if phase == "finish":
        return definition.finisher_clip
    return "chakra_charge" if phase == "clash" else "jutsu"

func movement_velocity(delta: float) -> Vector3:
    if (phase == "dogpile" or (phase == "finish" and not opened)) and is_instance_valid(target):
        var aim: Vector3 = target.global_position - fighter.global_position
        aim.y = 0.0
        fighter.call("_face_direction", aim, delta, 10.0)
        return (aim - fighter.global_basis.z * 0.9).limit_length(1.0) * 9.0
    return Vector3.ZERO

func _summon(offset: Vector3, delay: float, clip: String, damage: float) -> void:
    for clone: CharacterBody3D in fighter.specials.clones:
        if not clone.active:
            clone.call("summon", target, fighter.global_position + fighter.global_basis.x * offset.x, offset, delay, clip, 0.0, damage)
            owned_clones.append(clone)
            return

func _recycle_clones() -> void:
    for clone: CharacterBody3D in owned_clones:
        if is_instance_valid(clone) and clone.active:
            clone.call("recycle")
    owned_clones.clear()

func cancel(reason: String = "cancelled") -> void:
    if phase.is_empty():
        return
    last_result = reason
    phase = ""
    entry_clone = null
    entry_box.call("deactivate")
    _recycle_clones()
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
    _recycle_clones()

func _move_entry_clone(delta: float) -> void:
    # Storm 1 Handbook opens by throwing a clone. Sweep its physical volume.
    var travel: Vector3 = entry_direction * 18.0 * delta
    var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    query.shape = entry_box.get_child(0).shape
    query.transform = Transform3D(Basis.IDENTITY, entry_clone.global_position)
    query.motion = travel
    query.collision_mask = 1 | 16
    query.collide_with_areas = true
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var fractions: PackedFloat32Array = space.cast_motion(query)
    var fraction: float = fractions[0] if fractions.size() == 2 else 1.0
    entry_clone.global_position += travel * fraction
    entry_box.global_position = entry_clone.global_position
    query.motion = Vector3.ZERO
    query.transform.origin = entry_clone.global_position + entry_direction * 0.025
    var contacts: Array[Dictionary] = space.intersect_shape(query, 8)
    for contact: Dictionary in contacts:
        var collider: Node = contact["collider"] as Node
        if collider is Area3D and collider.has_method("get_fighter"):
            entry_box.call("try_hit", collider.call("get_fighter"))
            if phase != "entry":
                return
        elif collider is StaticBody3D:
            cancel("scenery")
            return
    if fraction < 1.0 and phase == "entry":
        cancel("miss_or_block")
