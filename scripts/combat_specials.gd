extends Node3D

var clones: Array[CharacterBody3D] = []
var projectiles: Array[Node3D] = []
var demon_projectile: Node3D = null
var transformed: bool = false
var selected: String = "demon"
var current: String = ""
var elapsed: float = 0.0
var duration: float = 0.0
var released: bool = false
var rasengan_hitbox: Area3D
var sphere_visual: MeshInstance3D
var style_visual: MeshInstance3D
var style_material: StandardMaterial3D
var active_opened: bool = false
var confirmed_target: Node3D = null
var sequence_elapsed: float = 0.0
var sequence_stage: int = 0
var barrage_hitbox: Area3D
var chidori_visual: MultiMeshInstance3D
var owns_camera: bool = false
var move_definition: JutsuDefinition
var traps: Array[Node3D] = []
var owner_fighter: CharacterBody3D

func _ready() -> void:
    owner_fighter = get_parent() as CharacterBody3D
    var choices: PackedStringArray = owner_fighter.character_definition.jutsus
    selected = choices[0] if not choices.is_empty() else ""
    if not owner_fighter.has_method("is_cpu_controlled"):
        call_deferred("warm_clone_pool")
    process_physics_priority = 15
    rasengan_hitbox = Area3D.new()
    rasengan_hitbox.set_script(preload("res://scripts/combat_hitbox.gd"))
    rasengan_hitbox.collision_layer = 0
    rasengan_hitbox.collision_mask = 8 if owner_fighter.collision_layer == 4 else 16
    var collision: CollisionShape3D = CollisionShape3D.new()
    var hit_shape: SphereShape3D = SphereShape3D.new()
    hit_shape.radius = 0.55
    collision.shape = hit_shape
    rasengan_hitbox.add_child(collision)
    add_child(rasengan_hitbox)
    rasengan_hitbox.top_level = true
    sphere_visual = MeshInstance3D.new()
    sphere_visual.set_script(preload("res://scripts/chakra_orb.gd"))
    rasengan_hitbox.add_child(sphere_visual)
    sphere_visual.visible = false

    style_visual = MeshInstance3D.new()
    style_material = StandardMaterial3D.new()
    style_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    style_material.emission_enabled = true
    style_visual.material_override = style_material
    style_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    rasengan_hitbox.add_child(style_visual)
    style_visual.visible = false

    chidori_visual = MultiMeshInstance3D.new()
    chidori_visual.set_script(preload("res://scripts/chidori_effect.gd"))
    rasengan_hitbox.add_child(chidori_visual)
    barrage_hitbox = Area3D.new()
    barrage_hitbox.set_script(preload("res://scripts/combat_hitbox.gd"))
    barrage_hitbox.collision_layer = 0
    barrage_hitbox.collision_mask = rasengan_hitbox.collision_mask
    var barrage_shape: CollisionShape3D = CollisionShape3D.new()
    var fist: SphereShape3D = SphereShape3D.new()
    fist.radius = 0.7
    barrage_shape.shape = fist
    barrage_hitbox.add_child(barrage_shape)
    add_child(barrage_hitbox)
    barrage_hitbox.top_level = true
    var projectile_script: Script = null
    if "demon" in choices:
        projectile_script = preload("res://scripts/chakra_projectile.gd")
    elif "fireball" in choices:
        projectile_script = preload("res://scripts/fireball_projectile.gd")
    else:
        for jutsu_id: String in choices:
            var projectile_data: JutsuDefinition = owner_fighter.character_definition.find_jutsu(jutsu_id)
            if projectile_data != null and projectile_data.strategy == "projectile":
                projectile_script = preload("res://scripts/generic_jutsu_projectile.gd")
                break

    var projectile_count: int = 3 if projectile_script != null else 0
    for i: int in range(projectile_count):
        var projectile: Node3D = Node3D.new()
        projectile.set_script(projectile_script)
        owner_fighter.get_parent().add_child.call_deferred(projectile)
        projectiles.append(projectile)

    if "booby_trap" in choices:
        for index: int in range(3):
            var trap: Node3D = Node3D.new()
            trap.set_script(preload("res://scripts/booby_trap.gd"))
            owner_fighter.get_parent().add_child.call_deferred(trap)
            traps.append(trap)

func warm_clone_pool() -> void:
    if not clones.is_empty() or owner_fighter.character_definition.character_id != "naruto":
        return
    for i: int in range(3):
        var clone: CharacterBody3D = CharacterBody3D.new()
        clone.set_script(preload("res://scripts/shadow_clone.gd"))
        owner_fighter.get_parent().add_child(clone)
        clone.call("prepare", owner_fighter)
        clones.append(clone)

func summon_clone(target: Node3D, offset: Vector3, delay: float, clip: String, lift: float = 0.0, damage: float = 6.0) -> bool:
    for clone: CharacterBody3D in clones:
        if not clone.active:
            var origin: Vector3 = owner_fighter.global_position + owner_fighter.global_basis.x * (1.2 if offset.x >= 0.0 else -1.2)
            clone.call("summon", target, origin, offset, delay, clip, lift, damage, self)
            return true
    return false

func cycle_selection() -> void:
    var choices: PackedStringArray = owner_fighter.character_definition.jutsus
    if choices.is_empty():
        return
    var index: int = choices.find(selected)
    selected = choices[(index + 1) % choices.size()]

func start(kind: String = "") -> bool:
    var move: String = selected if kind.is_empty() else kind
    if not current.is_empty() or owner_fighter.defeated or owner_fighter.stagger_timer > 0.0 or owner_fighter.jutsu_timer > 0.0 or owner_fighter.attack_active or owner_fighter.dodge_timer > 0.0 or owner_fighter.chakra_dash_timer > 0.0 or owner_fighter.jutsu_cooldown > 0.0:
        return false
    if move not in owner_fighter.character_definition.jutsus:
        return false
    var data: JutsuDefinition = owner_fighter.character_definition.find_jutsu(move)
    var cost: float = data.chakra_cost if data != null else 32.0
    if owner_fighter.chakra < cost:
        return false
    if data != null and data.strategy == "trap":
        if not owner_fighter.is_on_floor():
            return false
        var available: bool = false
        for trap: Node3D in traps:
            if trap.is_inside_tree() and not trap.active:
                available = true
                break
        if not available:
            return false
    if move in ["demon", "clones", "whirlwind", "barrage"]:
        warm_clone_pool()
    owner_fighter.chakra -= cost
    owner_fighter.jutsu_cooldown = data.cooldown if data != null else 4.0 if move == "barrage" else 1.5
    owner_fighter.jutsu_timer = 0.65
    owner_fighter.is_guarding = false
    owner_fighter.is_charging_chakra = false
    owner_fighter.animation_action_id += 1
    if owner_fighter.awakening.active and move in ["demon", "rasengan"]:
        move = "rasengan"
    var audio: Node = owner_fighter.get_parent().get_node_or_null("AudioManager")
    if audio != null:
        audio.call("play", "chakra")
    current = move
    move_definition = owner_fighter.character_definition.find_jutsu(move)
    var visual_color: Color = owner_fighter.character_definition.energy_color
    if move_definition != null:
        visual_color = _effect_color(move_definition.effect, visual_color)
    if owner_fighter.awakening.active:
        visual_color = visual_color.lightened(0.12)
    sphere_visual.call("set_energy_color", visual_color)
    style_material.albedo_color = visual_color
    style_material.emission = visual_color
    if move_definition != null:
        style_visual.mesh = RosterVisualStyle.projectile_mesh(move_definition.effect)
        style_visual.scale = RosterVisualStyle.projectile_scale(move_definition.effect, move_definition.hitbox_radius) * 0.72
    elapsed = 0.0
    duration = 0.95 if move in ["rasengan", "chidori", "raikiri"] else 0.45 if move == "barrage" else 1.85 if move == "demon" else 0.65
    if move_definition != null:
        var move_timing: Dictionary = move_definition.animation_timing(owner_fighter.rig_adapter.manifest)
        if move_definition.strategy == "hand":
            duration = float(move_timing.get("duration", 0.95))
        elif move_definition.strategy == "burst":
            duration = maxf(0.72, float(move_timing.get("duration", 0.72)))
        elif move not in ["demon", "clones", "whirlwind", "barrage"]:
            duration = maxf(0.65, float(move_timing.get("duration", 0.65)))
        var hit_shape: SphereShape3D = rasengan_hitbox.get_child(0).shape as SphereShape3D
        if move_definition.strategy in ["hand", "burst"]:
            hit_shape.radius = move_definition.hitbox_radius
    confirmed_target = null
    sequence_stage = 0
    sequence_elapsed = 0.0
    owner_fighter.jutsu_timer = duration
    active_opened = false
    released = false

    if move == "rasengan":
        var state_machine: Node = _combat_state_machine()
        if state_machine != null:
            var rasengan_timing: Dictionary = move_definition.animation_timing(owner_fighter.rig_adapter.manifest) if move_definition != null else {}
            var rasengan_startup: float = float(rasengan_timing.get("startup", 0.38))
            state_machine.call("mark_special_phase", "rasengan_startup", maxf(rasengan_startup, 0.12))

    # Brief, readable camera emphasis for Naruto's close-range Rasengan.
    # It uses the existing combat camera instead of a separate cinematic camera.
    if move == "rasengan" and not owner_fighter.has_method("is_cpu_controlled") and is_instance_valid(owner_fighter.locked_target):
        owns_camera = true
        owner_fighter.camera_rig.call("begin_sequence", owner_fighter.locked_target, minf(duration, 0.62))
        owner_fighter.camera_rig.call("set_sequence_shot", "jutsu")

    if move == "demon":
        for clone: CharacterBody3D in clones:
            if not clone.active:
                clone.call("present", owner_fighter.global_position - owner_fighter.global_basis.z * 0.8, owner_fighter.rotation.y, 0.65, "jutsu", self)
                break
    return true

func _physics_process(delta: float) -> void:
    if current.is_empty():
        return
    if owner_fighter.defeated or owner_fighter.stagger_timer > 0.0:
        cancel()
        return
    if owner_fighter.jutsu_timer <= 0.0:
        # Player physics runs first and may expire recovery before this timeline.
        cancel(false)
        return
    elapsed += delta
    if current == "barrage":
        _barrage_timeline(delta)
    elif move_definition != null and move_definition.strategy == "hand":
        var hand: Vector3 = owner_fighter.rig_adapter.call("get_hand_world_position")
        rasengan_hitbox.global_position = hand + owner_fighter.global_basis.z * 0.12
        var lightning: bool = move_definition.effect == "lightning"
        var styled_hand: bool = move_definition.effect not in ["chakra", "lightning"] and owner_fighter.character_definition.character_id != "naruto"
        sphere_visual.visible = not lightning and not styled_hand and elapsed > 0.12 and elapsed < maxf(0.24, duration - 0.10)
        style_visual.visible = styled_hand and elapsed > 0.12 and elapsed < maxf(0.24, duration - 0.10)
        chidori_visual.visible = lightning and elapsed > 0.12 and elapsed < maxf(0.24, duration - 0.10)
        var orb_grow: float = minf(1.0, elapsed * 5.4)
        var orb_pulse: float = 1.0 + (sin(elapsed * 42.0) * 0.045 if current == "rasengan" else 0.0)
        sphere_visual.scale = Vector3.ONE * orb_grow * orb_pulse
        var timing: Dictionary = move_definition.animation_timing(owner_fighter.rig_adapter.manifest)
        var startup: float = float(timing.get("startup", 0.38))
        var active_time: float = float(timing.get("active", 0.30))
        if current == "rasengan":
            var state_machine: Node = _combat_state_machine()
            if state_machine != null:
                var movement_lead: float = move_definition.movement_lead
                var movement_start: float = maxf(0.0, startup - movement_lead)
                if elapsed < movement_start:
                    state_machine.call("mark_special_phase", "rasengan_startup", maxf(movement_start - elapsed, 0.03))
                elif elapsed <= startup + active_time:
                    state_machine.call("mark_special_phase", "rasengan_drive", maxf(startup + active_time - elapsed, 0.03))
                else:
                    state_machine.call("mark_special_phase", "rasengan_recovery", maxf(duration - elapsed, 0.03))
        if elapsed >= startup and not active_opened:
            active_opened = true
            rasengan_hitbox.call("activate", owner_fighter, move_definition.damage, move_definition.knockback, move_definition.launch_force, move_definition.hitstun, active_time)
        if elapsed >= startup + active_time:
            rasengan_hitbox.call("deactivate")
    elif not released and elapsed >= release_time():
        released = true
        if move_definition != null and move_definition.strategy == "burst":
            rasengan_hitbox.global_position = owner_fighter.global_position + Vector3.UP * 0.65 + owner_fighter.global_basis.z * 0.45
            var generic_burst: bool = owner_fighter.character_definition.character_id != "naruto"
            sphere_visual.visible = not generic_burst
            style_visual.visible = generic_burst
            if generic_burst:
                style_visual.scale = RosterVisualStyle.projectile_scale(move_definition.effect, move_definition.hitbox_radius)
            else:
                sphere_visual.scale = Vector3.ONE * clampf(move_definition.hitbox_radius * 0.85, 0.9, 2.4)
            rasengan_hitbox.call("activate", owner_fighter, move_definition.damage, move_definition.knockback, move_definition.launch_force, move_definition.hitstun, 0.18)
            return
        if move_definition != null and move_definition.strategy == "trap":
            for trap: Node3D in traps:
                if trap.is_inside_tree() and not trap.active:
                    trap.call("arm", owner_fighter, move_definition)
                    break
            return
        if current in ["clones", "whirlwind"]:
            var victim: Node3D = owner_fighter.locked_target
            if is_instance_valid(victim):
                var aerial: bool = current == "whirlwind"
                summon_clone(victim, Vector3(-0.7, 0, -1.0), 0.18, "air_attack_2" if aerial else "attack_2", 0.0, 6.0)
                summon_clone(victim, Vector3(0.7, 0, -1.0), 0.36, "air_attack_4" if aerial else "attack_3", -13.0 if aerial else 3.0, 8.0)
            return
        for projectile: Node3D in projectiles:
            if projectile.is_inside_tree() and not projectile.active:
                demon_projectile = projectile
                transformed = current == "demon"
                var origin: Vector3 = owner_fighter.global_position + Vector3.UP * 0.25 + owner_fighter.global_basis.z * 0.8
                if projectile.has_method("launch_jutsu") and move_definition != null:
                    projectile.call("launch_jutsu", owner_fighter, owner_fighter.locked_target, origin, owner_fighter.global_basis.z, move_definition)
                else:
                    projectile.call("launch", owner_fighter, owner_fighter.locked_target, origin, owner_fighter.global_basis.z)
                break
    if elapsed >= duration:
        # Successful release lets delayed clone attacks finish autonomously.
        cancel(false)

func cancel(stop_clones: bool = true) -> void:
    if stop_clones:
        for clone: CharacterBody3D in clones:
            if is_instance_valid(clone) and clone.active and clone.sequence_owner == self:
                clone.call("recycle")
    var ended_kind: String = current
    current = ""
    transformed = false
    if ended_kind == "rasengan" and not owner_fighter.defeated and owner_fighter.stagger_timer <= 0.0:
        var state_machine: Node = _combat_state_machine()
        if state_machine != null:
            state_machine.call("mark_special_phase", "rasengan_recovery", 0.16)
    if is_instance_valid(demon_projectile) and demon_projectile.active and (stop_clones or ended_kind == "demon"):
        demon_projectile.call("recycle")
    demon_projectile = null
    sphere_visual.visible = false
    style_visual.visible = false
    chidori_visual.visible = false
    rasengan_hitbox.call("deactivate")
    barrage_hitbox.call("deactivate")
    confirmed_target = null
    if owns_camera and is_instance_valid(owner_fighter.camera_rig):
        owner_fighter.camera_rig.call("end_sequence")
    owns_camera = false
    owner_fighter.jutsu_timer = 0.0

func demon_confirm(target: Node) -> void:
    transformed = false
    owner_fighter.jutsu_timer = 0.45
    duration = elapsed + 0.45
    var victim: Node3D = target as Node3D
    summon_clone(victim, Vector3(-0.5, 0, -1.0), 0.12, "attack_2", 0.0, 8.0)
    summon_clone(victim, Vector3(0.5, 0, -1.0), 0.32, "attack_3", 3.0, 8.0)

func _exit_tree() -> void:
    for clone: CharacterBody3D in clones:
        if is_instance_valid(clone):
            clone.queue_free()
    for projectile: Node3D in projectiles:
        if is_instance_valid(projectile):
            projectile.queue_free()
    for trap: Node3D in traps:
        if is_instance_valid(trap):
            trap.queue_free()

func movement_velocity(delta: float) -> Vector3:
    if current == "barrage" and is_instance_valid(confirmed_target) and sequence_elapsed < 0.65:
        var pursuit: Vector3 = confirmed_target.global_position - owner_fighter.global_position - owner_fighter.global_basis.z * 1.0
        return pursuit.limit_length(1.0) * 12.0
    if move_definition == null or move_definition.strategy != "hand":
        return Vector3.ZERO
    var timing: Dictionary = move_definition.animation_timing(owner_fighter.rig_adapter.manifest)
    var startup: float = float(timing.get("startup", 0.38))
    var active_time: float = float(timing.get("active", 0.30))
    var movement_lead: float = move_definition.movement_lead if move_definition != null else 0.1
    var movement_start: float = startup - movement_lead
    if elapsed < movement_start or elapsed > startup + active_time:
        return Vector3.ZERO
    var forward: Vector3 = owner_fighter.global_basis.z
    if is_instance_valid(owner_fighter.locked_target):
        var aim: Vector3 = owner_fighter.locked_target.global_position - owner_fighter.global_position
        aim.y = 0.0
        if aim.length() <= 1.0:
            return Vector3.ZERO
        owner_fighter.call("_face_direction", aim, delta, move_definition.tracking_strength if move_definition != null else 7.0)
        forward = owner_fighter.global_basis.z
    var movement_window: float = maxf(active_time + movement_lead, 0.01)
    var movement_phase: float = clampf((elapsed - movement_start) / movement_window, 0.0, 1.0)
    var drive: float = lerpf(0.70, 1.16, sin(movement_phase * PI * 0.5))
    return forward * (move_definition.movement_speed if move_definition != null else 13.0) * drive

func contact(target: Node, dealt: float, blocked: bool = false) -> void:
    if current == "rasengan" and dealt > 0.0:
        var state_machine: Node = _combat_state_machine()
        if state_machine != null:
            state_machine.call("mark_special_phase", "rasengan_impact", 0.18)
        var rasengan_target: Node3D = target as Node3D
        var feedback: Node = owner_fighter.get_parent().get_node_or_null("CombatFeedback")
        if rasengan_target != null and feedback != null and feedback.has_method("spawn_chakra_impact"):
            feedback.call(
                "spawn_chakra_impact",
                rasengan_target.global_position + Vector3.UP * 0.72,
                owner_fighter.character_definition.energy_color
            )
        if is_instance_valid(owner_fighter.camera_rig) and owner_fighter.camera_rig.has_method("add_combat_impact"):
            owner_fighter.camera_rig.call("add_combat_impact", 0.11 if blocked else 0.17, 1.8 if blocked else 3.4)
        return

    if current != "barrage" or is_instance_valid(confirmed_target) or dealt <= 0.0 or blocked:
        return
    if target.has_method("get_is_guarding") and bool(target.call("get_is_guarding")):
        return
    confirmed_target = target as Node3D
    sequence_elapsed = 0.0
    duration = elapsed + 1.4
    owner_fighter.jutsu_timer = 1.5
    barrage_hitbox.call("deactivate")
    owns_camera = true
    owner_fighter.camera_rig.call("begin_sequence", owner_fighter if owner_fighter.collision_layer == 4 else confirmed_target, 1.4)
    summon_clone(confirmed_target, -owner_fighter.global_basis.z * 1.0, 0.08, "attack_4", 8.5, 5.0)

func _barrage_timeline(delta: float) -> void:
    barrage_hitbox.global_position = owner_fighter.rig_adapter.call("get_hand_world_position", "RightHand" if sequence_stage >= 2 else "LeftHand")
    barrage_hitbox.global_position += owner_fighter.global_basis.z * 0.16
    if not is_instance_valid(confirmed_target):
        if not active_opened and elapsed >= 0.12:
            active_opened = true
            barrage_hitbox.call("activate", owner_fighter, 4.0, 0.0, 0.0, 0.6, 0.09)
        return
    if not bool(confirmed_target.call("is_targetable")) or float(confirmed_target.get("invulnerable_timer")) > 0.0:
        cancel()
        return
    sequence_elapsed += delta
    if sequence_stage == 0 and sequence_elapsed >= 0.32:
        sequence_stage = 1
        summon_clone(confirmed_target, -owner_fighter.global_basis.z * 1.0 + owner_fighter.global_basis.x * 0.5, 0.08, "air_attack_2", 0.0, 5.0)
    if sequence_stage == 1 and sequence_elapsed >= 0.65:
        sequence_stage = 2
        owner_fighter.animation_action_id += 1
    if sequence_stage == 2 and sequence_elapsed >= 0.80:
        sequence_stage = 3
        barrage_hitbox.call("activate", owner_fighter, 12.0, 8.0, -13.0, 0.75, 0.12)
    if sequence_elapsed >= 1.25:
        cancel()

func release_time() -> float:
    if move_definition == null:
        return 0.24
    return float(move_definition.animation_timing(owner_fighter.rig_adapter.manifest).get("impact", 0.24))

func animation_clip() -> String:
    if current == "barrage":
        return "air_attack_4" if sequence_stage >= 2 else "attack_1"
    if move_definition != null and not move_definition.animation_name.is_empty():
        return move_definition.animation_name
    return "jutsu"

func projectile_finished() -> void:
    transformed = false
    if current == "demon" and not released:
        return
    duration = minf(duration, elapsed + 0.45)


func _combat_state_machine() -> Node:
    return owner_fighter.get_node_or_null("CombatStateMachine")

func _effect_color(effect: String, fallback: Color) -> Color:
    return RosterVisualStyle.color(effect, fallback).lerp(fallback, 0.18)
