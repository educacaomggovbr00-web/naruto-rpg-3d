extends CharacterBody3D

@export var moveset: MovesetDefinition = preload("res://assets/combat/naruto_moveset.tres")
var character_definition: CharacterDefinition = null
var selected_attack: AttackDefinition = null
var combo_branch: String = "neutral"

@export var max_health: float = 120.0
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var attack_range: float = 1.35
@export var detection_range: float = 18.0
@export var attack_damage: float = 10.0
@export var attack_knockback: float = 5.5
@export var attack_cooldown_time: float = 1.05
@export var guard_duration: float = 0.65
@export var recovery_delay: float = 2.5
@export var knockback_friction: float = 12.0
@export var ground_bounce_velocity: float = 6.2
@export var wall_bounce_strength: float = 0.68

# Shared ability modules use the same fighter contract as the player.
@export var enable_arsenal: bool = true
var defeated: bool:
    get:
        return not targetable
var is_guarding: bool:
    get:
        return guarding
    set(value):
        guarding = value
var is_charging_chakra: bool = false
var max_chakra: float = 100.0
var chakra: float = 100.0
var jutsu_timer: float = 0.0
var jutsu_cooldown: float = 0.0
var chakra_dash_timer: float = 0.0
var dash_elapsed: float = 0.0
var dash_speed: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var dash_hitbox: Area3D
var air_dash_count: int = 0
var arsenal_delay: float = 2.0
var attack_buffer: float = 0.0
var jump_requested: bool = false
var specials: Node3D
var awakening: Node3D
var ultimate: Node3D
var ninja_tools: Node3D
@onready var camera_rig: Node3D = $"../Player/CameraRig"

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var health: float = 120.0
var targetable: bool = true
var cinematic_owner: Node = null
var cinematic_watchdog: float = 0.0
var guarding: bool = false
var spawn_position: Vector3 = Vector3.ZERO

var attack_cooldown: float = 0.0
var guard_timer: float = 0.0
var stagger_timer: float = 0.0
var dodge_timer: float = 0.0
var respawn_timer: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var attack_cycle: int = 0
var hit_cycle: int = 0
var guard_meter: float = 100.0
var guard_regen_delay: float = 0.0
var substitutions: int = 4
var substitution_regen: float = 0.0
var substitution_cooldown: float = 0.0
var invulnerable_timer: float = 0.0
var reaction_timer: float = 0.0
var juggle_hits: int = 0
var juggle_timer: float = 0.0
@export var reactive_substitution: bool = true

@export var decision_interval_min: float = 0.18
@export var decision_interval_max: float = 0.32
var decision_timer: float = 0.20
var neutral_motion: String = "approach"
var orbit_side: float = 1.0
var decision_rng: RandomNumberGenerator = RandomNumberGenerator.new()

var locked_target: CharacterBody3D = null
var combo_step: int = 1
var animation_action_id: int = 0
var attack_confirmed: bool = false
var attack_airborne: bool = false
var attack_timing: Dictionary = {}

var attack_active: bool = false
var attack_elapsed: float = 0.0
var attack_hit_triggered: bool = false
var ground_bounce_pending: bool = false
var wall_bounce_pending: bool = false

@onready var rig_adapter: Node3D = $RiggedCharacterAdapter
@onready var visual: MeshInstance3D = $Visual
@onready var lock_label: Label3D = $LockLabel
@onready var health_label: Label3D = $HealthLabel
@onready var player: CharacterBody3D = $"../Player"
@onready var attack_hitbox: Area3D = $AttackHitbox
@onready var combat_feedback: Node = get_node_or_null("../CombatFeedback")

func get_character_definition() -> CharacterDefinition:
    return GameFlow.cpu_character

func _ready() -> void:
    character_definition = get_character_definition()
    moveset = character_definition.moveset
    max_chakra = character_definition.max_chakra
    chakra = max_chakra
    if GameFlow.versus_mode:
        max_health = character_definition.max_health
        move_speed = character_definition.movement_speed
    specials = _ability("CombatSpecials", preload("res://scripts/combat_specials.gd"))
    awakening = _ability("Awakening", preload("res://scripts/naruto_awakening.gd"))
    ultimate = _ability("Ultimate", preload("res://scripts/ultimate_controller.gd"))
    ninja_tools = _ability("NinjaTools", preload("res://scripts/ninja_tools.gd"))
    dash_hitbox = Area3D.new()
    dash_hitbox.set_script(preload("res://scripts/combat_hitbox.gd"))
    dash_hitbox.collision_layer = 0
    dash_hitbox.collision_mask = 8
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = 0.85
    collision.shape = shape
    dash_hitbox.add_child(collision)
    add_child(dash_hitbox)
    decision_rng.randomize()
    locked_target = player
    health = max_health
    spawn_position = global_position
    _update_labels()

func _physics_process(delta: float) -> void:
    if is_instance_valid(cinematic_owner):
        cinematic_watchdog -= delta
        if cinematic_watchdog > 0.0 and targetable:
            _update_timers(delta)
            velocity = Vector3.ZERO
            return
        cinematic_owner = null
    if not is_on_floor():
        velocity.y -= gravity * delta

    _update_timers(delta)
    _update_attack_timeline(delta)

    if not targetable:
        velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
        velocity.z = move_toward(velocity.z, 0.0, knockback_friction * delta)
        _move_and_handle_bounces()

        if respawn_timer <= 0.0:
            _respawn()
        return

    if not is_instance_valid(player) or bool(player.call("is_defeated")):
        _slow_down(delta)
        _move_and_handle_bounces()
        return

    if stagger_timer > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, knockback_friction * 0.35 * delta)
        velocity.z = move_toward(velocity.z, 0.0, knockback_friction * 0.35 * delta)
        _move_and_handle_bounces()
        return

    if dodge_timer > 0.0:
        velocity.x = dodge_direction.x * 8.5
        velocity.z = dodge_direction.z * 8.5
        _move_and_handle_bounces()
        return

    var to_player: Vector3 = player.global_position - global_position
    to_player.y = 0.0
    var distance: float = to_player.length()

    if distance <= detection_range and to_player.length_squared() > 0.001:
        _face_direction(to_player, delta)

    if guard_timer > 0.0:
        guarding = true
        _slow_down(delta)
        _move_and_handle_bounces()
        return

    guarding = false
    if chakra_dash_timer > 0.0:
        _dash_motion(delta)
        _move_and_handle_bounces()
        return
    if jutsu_timer > 0.0:
        var motion: Vector3 = ultimate.call("movement_velocity", delta) if not ultimate.phase.is_empty() else Vector3.ZERO if awakening.transforming else specials.call("movement_velocity", delta)
        velocity.x = motion.x
        velocity.z = motion.z
        if specials.current == "barrage":
            velocity.y = motion.y
        _move_and_handle_bounces()
        return

    decision_timer = maxf(decision_timer - delta, 0.0)
    if not attack_active and decision_timer <= 0.0:
        _decide_neutral(distance)
        if enable_arsenal and _decide_arsenal(distance):
            _move_and_handle_bounces()
            return

    if attack_active:
        if distance > 1.05 and attack_elapsed < float(attack_timing.get("startup", 0.12)):
            _chase_player(to_player, delta)
        else:
            _slow_down(delta)
    elif is_charging_chakra or distance > detection_range:
        _slow_down(delta)
    elif neutral_motion == "retreat" and distance < 6.0:
        _chase_player(-to_player, delta)
    elif neutral_motion == "strafe" and distance > attack_range:
        _chase_player(Vector3(-to_player.z, 0.0, to_player.x) * orbit_side, delta)
    elif distance > attack_range:
        _chase_player(to_player, delta)
    else:
        _slow_down(delta)
        if attack_cooldown <= 0.0 and decision_timer <= decision_interval_min:
            _choose_close_action()

    _move_and_handle_bounces()

func _update_timers(delta: float) -> void:
    arsenal_delay = maxf(arsenal_delay - delta, 0.0)
    jutsu_cooldown = maxf(jutsu_cooldown - delta, 0.0)
    jutsu_timer = maxf(jutsu_timer - delta, 0.0)
    chakra_dash_timer = maxf(chakra_dash_timer - delta, 0.0)
    if dash_hitbox != null and chakra_dash_timer <= 0.0:
        dash_hitbox.call("deactivate")
    if targetable and stagger_timer <= 0.0 and jutsu_timer <= 0.0 and chakra_dash_timer <= 0.0:
        chakra = minf(max_chakra, chakra + delta * (22.0 if is_charging_chakra else 3.0))
    if is_on_floor():
        air_dash_count = 0
    juggle_timer = maxf(juggle_timer - delta, 0.0)
    if juggle_timer <= 0.0:
        juggle_hits = 0
    invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)
    substitution_cooldown = maxf(substitution_cooldown - delta, 0.0)
    guard_regen_delay = maxf(guard_regen_delay - delta, 0.0)
    if guard_regen_delay <= 0.0 and not guarding:
        guard_meter = minf(100.0, guard_meter + delta * 20.0)
    if substitutions < 4:
        substitution_regen += delta
        if substitution_regen >= 8.0:
            substitutions += 1
            substitution_regen = 0.0
    if reaction_timer > 0.0:
        reaction_timer -= delta
        if reaction_timer <= 0.0 and stagger_timer > 0.0:
            _substitute()
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    guard_timer = maxf(guard_timer - delta, 0.0)
    stagger_timer = maxf(stagger_timer - delta, 0.0)
    dodge_timer = maxf(dodge_timer - delta, 0.0)

    if not targetable:
        respawn_timer = maxf(respawn_timer - delta, 0.0)

    if stagger_timer <= 0.0 and is_on_floor():
        wall_bounce_pending = false
        if velocity.y >= -0.1:
            ground_bounce_pending = false

func _update_attack_timeline(delta: float) -> void:
    if not attack_active:
        return

    attack_elapsed += delta

    var startup: float = float(attack_timing.get("startup", 0.12))
    var duration: float = float(attack_timing.get("duration", 0.28))
    if not attack_hit_triggered and attack_elapsed >= startup:
        attack_hit_triggered = true
        rig_adapter.call("snap_attack_hitbox", combo_step, attack_airborne)
        attack_hitbox.call("activate", self, selected_attack.damage * attack_damage / 10.0,
            selected_attack.knockback, selected_attack.launch_force, selected_attack.hitstun,
            float(attack_timing.get("active", 0.09)))

    # Continue only after an actual unblocked collision, inside the manifest window.
    var cancel_open: float = float(attack_timing.get("cancel_open", duration))
    var cancel_close: float = float(attack_timing.get("cancel_close", duration))
    if attack_confirmed and combo_step < 4 and attack_elapsed >= cancel_open and attack_elapsed <= cancel_close:
        combo_step += 1
        _begin_strike()
    elif attack_elapsed >= duration:
        attack_active = false
        attack_hitbox.call("deactivate")

func on_hitbox_contact(_hitbox: Area3D, _victim: Node, damage: float, blocked: bool) -> void:
    if _hitbox == dash_hitbox and chakra_dash_timer > 0.0:
        chakra_dash_timer = 0.0
        dash_hitbox.call("deactivate")
        velocity = -dash_direction * 5.0 if blocked else Vector3.ZERO
        if blocked:
            stagger_timer = 0.22
        else:
            attack_cooldown = 0.0
            _start_attack()
    specials.call("contact", _victim, damage, blocked)
    if attack_active and not blocked and damage > 0.0:
        attack_confirmed = true

func get_animation_state() -> String:
    if not targetable:
        return "defeat"
    if stagger_timer > 0.0:
        return "knockback" if velocity.length() > 6.0 and guard_meter > 0.0 else "hit"
    if dodge_timer > 0.0:
        return "dodge"
    if guarding:
        return "guard"
    if chakra_dash_timer > 0.0:
        return "chakra_dash"
    if jutsu_timer > 0.0:
        return "jutsu"
    if is_charging_chakra:
        return "chakra_charge"
    if attack_active:
        return "air_attack" if attack_airborne else "attack"
    if not is_on_floor():
        return "air"
    return "run" if Vector2(velocity.x, velocity.z).length() > 0.2 else "idle"

func get_attack_animation() -> String:
    return selected_attack.animation_name if selected_attack != null else "attack_1"

func get_combo_step() -> int:
    return combo_step

func get_animation_action_id() -> int:
    return animation_action_id

func _slow_down(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
    velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

func _chase_player(to_player: Vector3, delta: float) -> void:
    if to_player.length_squared() <= 0.001:
        return

    var direction: Vector3 = to_player.normalized()
    velocity.x = move_toward(velocity.x, direction.x * move_speed * float(awakening.call("movement_multiplier")), acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * move_speed * float(awakening.call("movement_multiplier")), acceleration * delta)

func _decide_neutral(distance: float) -> void:
    decision_timer = decision_rng.randf_range(decision_interval_min, decision_interval_max)
    if guard_meter < 25.0 and distance < 6.0:
        neutral_motion = "retreat"
    elif distance > attack_range and distance < 5.0 and decision_rng.randf() < 0.30:
        neutral_motion = "strafe"
        orbit_side = -1.0 if decision_rng.randf() < 0.5 else 1.0
    else:
        neutral_motion = "approach"

func get_cpu_state() -> String:
    if not targetable:
        return "ko"
    if is_instance_valid(cinematic_owner):
        return "cinematic"
    if stagger_timer > 0.0:
        return "recover"
    if dodge_timer > 0.0:
        return "dodge"
    if guarding:
        return "guard"
    if chakra_dash_timer > 0.0:
        return "chase"
    if jutsu_timer > 0.0:
        return "ultimate" if not ultimate.phase.is_empty() else "awakening" if awakening.transforming else "jutsu"
    if is_charging_chakra:
        return "charge"
    if attack_active:
        return "combo" if combo_step > 1 else "attack"
    return neutral_motion

func _choose_close_action() -> void:
    attack_cycle += 1

    if guard_meter > 25.0 and decision_rng.randf() < 0.25:
        guarding = true
        guard_timer = guard_duration
        attack_cooldown = attack_cooldown_time * 0.80
        _update_labels()
        return

    _start_attack()

func _start_attack() -> void:
    attack_cooldown = attack_cooldown_time
    attack_active = true
    attack_elapsed = 0.0
    attack_hit_triggered = false

    combo_step = 1
    attack_airborne = not is_on_floor()
    combo_branch = ["neutral", "up", "down", "side"][decision_rng.randi_range(0, 3)]
    _begin_strike()

func _begin_strike() -> void:
    attack_hitbox.call("deactivate")
    attack_elapsed = 0.0
    attack_hit_triggered = false
    attack_confirmed = false
    animation_action_id += 1
    selected_attack = moveset.attack(combo_step, attack_airborne, combo_branch)
    attack_timing = selected_attack.animation_timing(rig_adapter.manifest)

func _face_direction(direction: Vector3, delta: float, speed: float = 10.0) -> void:
    var flat: Vector3 = direction
    flat.y = 0.0

    if flat.length_squared() <= 0.001:
        return

    var target_yaw: float = atan2(flat.x, flat.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, minf(speed * delta, 1.0))

func _move_and_handle_bounces() -> void:
    var was_on_floor: bool = is_on_floor()
    var pre_move_velocity: Vector3 = velocity
    move_and_slide()

    if (
        ground_bounce_pending
        and not was_on_floor
        and is_on_floor()
        and pre_move_velocity.y < -5.0
    ):
        ground_bounce_pending = false
        velocity.y = ground_bounce_velocity
        stagger_timer = maxf(stagger_timer, 0.34)
        _trigger_bounce_feedback("ground")

    if wall_bounce_pending and is_on_wall():
        var horizontal_speed: float = Vector2(pre_move_velocity.x, pre_move_velocity.z).length()
        if horizontal_speed >= 4.0:
            _apply_wall_bounce(pre_move_velocity)

func _apply_wall_bounce(pre_move_velocity: Vector3) -> void:
    var collision_count: int = get_slide_collision_count()

    for index: int in range(collision_count):
        var collision: KinematicCollision3D = get_slide_collision(index)
        var normal: Vector3 = collision.get_normal()

        if absf(normal.y) > 0.55:
            continue

        var reflected: Vector3 = pre_move_velocity.bounce(normal) * wall_bounce_strength
        velocity.x = reflected.x
        velocity.z = reflected.z
        velocity.y = maxf(velocity.y, 2.2)
        wall_bounce_pending = false
        stagger_timer = maxf(stagger_timer, 0.38)
        _trigger_bounce_feedback("wall")
        return

func _trigger_bounce_feedback(_bounce_kind: String) -> void:
    if is_instance_valid(combat_feedback):
        if combat_feedback.has_method("spawn_impact"):
            combat_feedback.call(
                "spawn_impact",
                global_position + Vector3.UP * 0.45,
                "bounce"
            )
        if combat_feedback.has_method("hit_stop"):
            combat_feedback.call("hit_stop", 0.045, 0.14)

    if is_instance_valid(player) and player.has_method("extend_combo_feedback"):
        player.call("extend_combo_feedback", 0.85)

func is_defeated() -> bool:
    return not targetable

func get_damage_multiplier() -> float:
    return float(awakening.call("damage_multiplier")) * float(ninja_tools.call("damage_multiplier"))

func is_targetable() -> bool:
    return targetable

func set_locked(value: bool) -> void:
    lock_label.visible = value and targetable

func receive_combat_hit(
    damage: float,
    direction: Vector3,
    knockback: float,
    launch_velocity: float,
    hitstun: float
) -> float:
    if not targetable or invulnerable_timer > 0.0:
        return 0.0

    if not guarding:
        juggle_timer = 1.5
        juggle_hits += 1
        if juggle_hits > 12:
            juggle_hits = 0
            invulnerable_timer = 0.65
            stagger_timer = 0.0
            velocity.y = -5.0
            return 0.0
    var applied_damage: float = damage
    var applied_knockback: float = knockback

    if guarding:
        guard_meter = maxf(guard_meter - damage * 1.8 - knockback, 0.0)
        guard_regen_delay = 1.2
        guard_timer = maxf(guard_timer, 0.14)
        if guard_meter <= 0.0:
            guarding = false
            guard_timer = 0.0
            stagger_timer = 1.0
        applied_damage *= 0.22
        applied_knockback *= 0.18
        launch_velocity *= 0.15
        ground_bounce_pending = false
        wall_bounce_pending = false
    else:
        _cancel_abilities()
        attack_active = false
        attack_hitbox.call("deactivate")
        stagger_timer = hitstun
        if reactive_substitution and reaction_timer <= 0.0 and substitutions > 0 and substitution_cooldown <= 0.0 and randf() < 0.18:
            reaction_timer = randf_range(0.10, 0.18)
        wall_bounce_pending = applied_knockback >= 4.0
        ground_bounce_pending = launch_velocity < -2.0

    health = maxf(health - applied_damage, 0.0)

    var push: Vector3 = direction
    push.y = 0.0
    if push.length_squared() > 0.001:
        velocity.x = push.normalized().x * applied_knockback
        velocity.z = push.normalized().z * applied_knockback

    if absf(launch_velocity) > 0.01:
        velocity.y = launch_velocity

    hit_cycle += 1
    if false and hit_cycle % 4 == 0 and health > 0.0 and not guarding and is_on_floor():
        _start_reaction_dodge(direction)

    animation_action_id += 1
    _update_labels()

    if health <= 0.0:
        _knock_out()

    return applied_damage

func on_attack_connected(target: Node, _actual_damage: float, _launch_velocity: float) -> void:
    var impact_kind: String = "normal"
    if target.has_method("get_is_guarding") and bool(target.call("get_is_guarding")):
        impact_kind = "guard"

    if is_instance_valid(combat_feedback):
        if combat_feedback.has_method("spawn_impact") and target is Node3D:
            var target_3d: Node3D = target as Node3D
            combat_feedback.call(
                "spawn_impact",
                target_3d.global_position + Vector3.UP * 0.75,
                impact_kind
            )
        if combat_feedback.has_method("hit_stop"):
            combat_feedback.call("hit_stop", 0.030, 0.14)

func take_hit(damage: float, knockback: float, direction: Vector3, combo_step: int) -> void:
    var launch_velocity: float = 0.0
    if combo_step >= 4:
        launch_velocity = 8.5
    receive_combat_hit(damage, direction, knockback, launch_velocity, 0.28)

func _start_reaction_dodge(incoming_direction: Vector3) -> void:
    var side: Vector3 = Vector3(-incoming_direction.z, 0.0, incoming_direction.x)
    if side.length_squared() <= 0.001:
        side = global_basis.x

    dodge_direction = side.normalized()
    dodge_timer = 0.22
    stagger_timer = 0.0

func _update_labels() -> void:
    var state: String = ""
    if guarding:
        state = "  [DEF]"
    elif not is_on_floor():
        state = "  [AR]"

    health_label.text = "%s %d/%d%s" % [character_definition.display_name, int(health), int(max_health), state]

func _knock_out() -> void:
    _cancel_abilities()
    awakening.call("stop")
    targetable = false
    guarding = false
    attack_active = false
    attack_hitbox.call("deactivate")
    ground_bounce_pending = false
    wall_bounce_pending = false
    lock_label.visible = false
    health_label.text = "K.O."
    respawn_timer = recovery_delay

func _respawn() -> void:
    _cancel_abilities()
    awakening.call("reset")
    ninja_tools.call("reset")
    ultimate.cooldown = 0.0
    chakra = max_chakra
    arsenal_delay = 2.0
    cinematic_owner = null
    global_position = spawn_position
    velocity = Vector3.ZERO
    health = max_health
    guard_meter = 100.0
    substitutions = 4
    invulnerable_timer = 0.0
    reaction_timer = 0.0
    targetable = true
    guarding = false
    ground_bounce_pending = false
    wall_bounce_pending = false
    attack_active = false
    attack_hitbox.call("deactivate")
    stagger_timer = 0.0
    dodge_timer = 0.0
    guard_timer = 0.0
    attack_cooldown = 0.8
    neutral_motion = "approach"
    decision_timer = 0.20
    _update_labels()

func get_is_guarding() -> bool:
    return guarding

func is_airborne() -> bool:
    return not is_on_floor()

func _substitute() -> void:
    if not targetable or substitutions <= 0 or substitution_cooldown > 0.0:
        return
    _cancel_abilities()
    combat_feedback.call("spawn_substitution", global_position)
    substitutions -= 1
    substitution_cooldown = 0.65
    substitution_regen = 0.0
    invulnerable_timer = 0.4
    stagger_timer = 0.0
    attack_active = false
    attack_hitbox.call("deactivate")
    velocity = Vector3.ZERO
    global_position = player.global_position - player.global_basis.z * 2.3
    global_position.x = clampf(global_position.x, -27.5, 27.5)
    global_position.z = clampf(global_position.z, -27.5, 27.5)
    combat_feedback.call("spawn_substitution", global_position)

func begin_cinematic_lock(requester: Node) -> bool:
    if not targetable or (is_instance_valid(cinematic_owner) and cinematic_owner != requester):
        return false
    _cancel_abilities()
    cinematic_owner = requester
    cinematic_watchdog = 0.5
    attack_active = false
    attack_hitbox.call("deactivate")
    guarding = false
    guard_timer = 0.0
    velocity = Vector3.ZERO
    return true

func refresh_cinematic_lock(requester: Node) -> bool:
    if cinematic_owner != requester or not targetable:
        return false
    cinematic_watchdog = 0.5
    return true

func end_cinematic_lock(requester: Node) -> void:
    if cinematic_owner == requester:
        cinematic_owner = null
        cinematic_watchdog = 0.0

func _ability(title: String, script: Script) -> Node3D:
    var ability: Node3D = Node3D.new()
    ability.name = title
    ability.set_script(script)
    add_child(ability)
    return ability

func is_cpu_controlled() -> bool:
    return true

func get_special_animation() -> String:
    return ultimate.call("animation_clip") if not ultimate.phase.is_empty() else "chakra_charge" if awakening.transforming else specials.call("animation_clip")

func _can_use_movement_action() -> bool:
    return targetable and not is_instance_valid(cinematic_owner) and not attack_active and stagger_timer <= 0.0 and dodge_timer <= 0.0 and jutsu_timer <= 0.0 and chakra_dash_timer <= 0.0 and not guarding

func _cancel_abilities() -> void:
    if specials != null:
        specials.call("cancel")
        ultimate.call("cancel", "interrupted")
        ninja_tools.call("cancel")
    chakra_dash_timer = 0.0
    is_charging_chakra = false
    if dash_hitbox != null:
        dash_hitbox.call("deactivate")

func _start_chakra_dash() -> bool:
    if not _can_use_movement_action() or chakra < 18.0 or not is_instance_valid(player) or player.defeated or (not is_on_floor() and air_dash_count >= 2):
        return false
    var aim: Vector3 = player.global_position - global_position
    if aim.length_squared() <= 0.001:
        return false
    if not is_on_floor():
        air_dash_count += 1
    chakra -= 18.0
    is_charging_chakra = false
    dash_direction = aim.normalized()
    chakra_dash_timer = 0.55
    dash_elapsed = 0.0
    dash_speed = 0.0
    animation_action_id += 1
    combat_feedback.call("spawn_dash_burst", global_position)
    return true

func _dash_motion(delta: float) -> void:
    dash_elapsed += delta
    var aim: Vector3 = player.global_position - global_position
    if aim.length_squared() > 0.001:
        dash_direction = dash_direction.slerp(aim.normalized(), minf(delta * 9.0, 1.0)).normalized()
    if dash_elapsed >= 0.06:
        if dash_hitbox.remaining_time <= 0.0:
            dash_hitbox.call("activate", self, 0.0, 0.0, 0.0, 0.16, 0.5)
        dash_speed = move_toward(dash_speed, 24.0 * float(awakening.call("movement_multiplier")), delta * 100.0)
    velocity = dash_direction * dash_speed
    dash_hitbox.position = Vector3(0, 0.15, 0.4)
    _face_direction(dash_direction, delta, 24.0)
    if is_on_wall():
        chakra_dash_timer = 0.0
        dash_hitbox.call("deactivate")
        stagger_timer = 0.16

func _decide_arsenal(distance: float) -> bool:
    if arsenal_delay > 0.0 or not _can_use_movement_action() or distance > detection_range:
        return false
    is_charging_chakra = false
    if health <= max_health * 0.30 and character_definition.has_awakening and chakra >= max_chakra and decision_rng.randf() < 0.40:
        arsenal_delay = 1.0
        return awakening.call("start")
    if chakra < 32.0 and distance > 5.0:
        is_charging_chakra = true
        neutral_motion = "retreat"
        return false
    var roll: float = decision_rng.randf()
    arsenal_delay = decision_rng.randf_range(1.2, 2.2)
    if distance > 3.0 and distance < 10.0 and chakra >= 80.0 and character_definition.has_ultimate and roll < 0.12:
        specials.call("warm_clone_pool")
        return ultimate.call("start")
    if distance > 2.0 and distance < 12.0 and roll < 0.48:
        var choice: String = character_definition.jutsus[decision_rng.randi_range(0, character_definition.jutsus.size() - 1)]
        return specials.call("start", choice)
    if distance > 4.0 and roll < 0.78:
        return _start_chakra_dash()
    if distance > 3.0:
        ninja_tools.selected = 0
        return ninja_tools.call("use")
    return false
