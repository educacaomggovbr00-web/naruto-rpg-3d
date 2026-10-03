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
var active_opened: bool = false
var confirmed_target: Node3D = null
var sequence_elapsed: float = 0.0
var sequence_stage: int = 0
var barrage_hitbox: Area3D
var chidori_visual: MultiMeshInstance3D
var owns_camera: bool = false
var owner_fighter: CharacterBody3D

func _ready() -> void:
    owner_fighter = get_parent() as CharacterBody3D
    selected = owner_fighter.character_definition.jutsus[0]
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
    for i: int in range(3):
        var projectile: Node3D = Node3D.new()
        projectile.set_script(preload("res://scripts/fireball_projectile.gd") if selected == "fireball" else preload("res://scripts/chakra_projectile.gd"))
        owner_fighter.get_parent().add_child.call_deferred(projectile)
        projectiles.append(projectile)

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
    var index: int = choices.find(selected)
    selected = choices[(index + 1) % choices.size()]

func start(kind: String = "") -> bool:
    var move: String = selected if kind.is_empty() else kind
    if not current.is_empty() or owner_fighter.defeated or owner_fighter.stagger_timer > 0.0 or owner_fighter.jutsu_timer > 0.0 or owner_fighter.attack_active or owner_fighter.dodge_timer > 0.0 or owner_fighter.chakra_dash_timer > 0.0 or owner_fighter.jutsu_cooldown > 0.0:
        return false
    if move not in owner_fighter.character_definition.jutsus:
        return false
    if owner_fighter.chakra < 32.0:
        return false
    if move in ["demon", "clones", "whirlwind", "barrage"]:
        warm_clone_pool()
    owner_fighter.chakra -= 32.0
    owner_fighter.jutsu_cooldown = 4.0 if move == "barrage" else 1.5
    owner_fighter.jutsu_timer = 0.65
    owner_fighter.is_guarding = false
    owner_fighter.is_charging_chakra = false
    owner_fighter.animation_action_id += 1
    if owner_fighter.awakening.active and move in ["demon", "rasengan"]:
        move = "rasengan"
    sphere_visual.call("set_energy_color", Color(1.0, 0.15, 0.05) if owner_fighter.awakening.active else owner_fighter.character_definition.energy_color)
    var audio: Node = owner_fighter.get_parent().get_node_or_null("AudioManager")
    if audio != null:
        audio.call("play", "chakra")
    current = move
    elapsed = 0.0
    duration = 0.95 if move in ["rasengan", "chidori"] else 0.45 if move == "barrage" else 1.85 if move == "demon" else 0.65
    confirmed_target = null
    sequence_stage = 0
    sequence_elapsed = 0.0
    owner_fighter.jutsu_timer = duration
    active_opened = false
    released = false
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
    elif current in ["rasengan", "chidori"]:
        var hand: Vector3 = owner_fighter.rig_adapter.call("get_hand_world_position")
        rasengan_hitbox.global_position = hand + owner_fighter.global_basis.z * 0.12
        sphere_visual.visible = current == "rasengan" and elapsed > 0.12 and elapsed < 0.84
        chidori_visual.visible = current == "chidori" and elapsed > 0.12 and elapsed < 0.84
        sphere_visual.scale = Vector3.ONE * minf(1.0, elapsed * 5.0)
        if elapsed >= 0.38 and not active_opened:
            active_opened = true
            rasengan_hitbox.call("activate", owner_fighter, 26.0, 11.0, 4.5, 0.6, 0.30)
        if elapsed >= 0.68:
            rasengan_hitbox.call("deactivate")
    elif not released and elapsed >= 0.24:
        released = true
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
                projectile.call("launch", owner_fighter, owner_fighter.locked_target, owner_fighter.global_position + Vector3.UP * 0.25 + owner_fighter.global_basis.z * 0.8, owner_fighter.global_basis.z)
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
    if is_instance_valid(demon_projectile) and demon_projectile.active and (stop_clones or ended_kind == "demon"):
        demon_projectile.call("recycle")
    demon_projectile = null
    sphere_visual.visible = false
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

func movement_velocity(delta: float) -> Vector3:
    if current == "barrage" and is_instance_valid(confirmed_target) and sequence_elapsed < 0.65:
        var pursuit: Vector3 = confirmed_target.global_position - owner_fighter.global_position - owner_fighter.global_basis.z * 1.0
        return pursuit.limit_length(1.0) * 12.0
    if current not in ["rasengan", "chidori"] or elapsed < 0.28 or elapsed > 0.68:
        return Vector3.ZERO
    var forward: Vector3 = owner_fighter.global_basis.z
    if is_instance_valid(owner_fighter.locked_target):
        var aim: Vector3 = owner_fighter.locked_target.global_position - owner_fighter.global_position
        aim.y = 0.0
        if aim.length() <= 1.0:
            return Vector3.ZERO
        owner_fighter.call("_face_direction", aim, delta, 7.0)
        forward = owner_fighter.global_basis.z
    return forward * 13.0

func contact(target: Node, dealt: float, blocked: bool = false) -> void:
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

func animation_clip() -> String:
    if current in ["rasengan", "chidori"]:
        return "rasengan"
    if current == "barrage":
        return "air_attack_4" if sequence_stage >= 2 else "attack_1"
    return "jutsu"

func projectile_finished() -> void:
    transformed = false
    if current == "demon" and not released:
        return
    duration = minf(duration, elapsed + 0.45)
