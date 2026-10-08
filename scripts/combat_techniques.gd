extends Node3D
## Shared grab/perfect-guard rules. Uses existing clips until dedicated choreography exists.
var fighter: CharacterBody3D
var grab_box: Area3D
var elapsed: float = 0.0
var active: bool = false
var released: bool = false
var cooldown: float = 0.0
var guard_age: float = 1.0
var was_guarding: bool = false
var counter_cooldown: float = 0.0
var feedback_text: String = ""
var feedback_timer: float = 0.0

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D
    process_physics_priority = 5
    grab_box = Area3D.new()
    grab_box.set_script(preload("res://scripts/combat_hitbox.gd"))
    grab_box.collision_layer = 0
    grab_box.collision_mask = 16 if fighter.name == "Player" else 8
    grab_box.guard_piercing = true
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = 0.55
    collision.shape = shape
    grab_box.add_child(collision)
    grab_box.position = Vector3(0, 0.15, 0.90)
    add_child(grab_box)

func _physics_process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)
    counter_cooldown = maxf(counter_cooldown - delta, 0.0)
    feedback_timer = maxf(feedback_timer - delta, 0.0)
    var guarding: bool = bool(fighter.call("get_is_guarding"))
    guard_age = guard_age + delta if guarding and was_guarding else 0.0 if guarding else 1.0
    was_guarding = guarding
    if not active:
        return
    elapsed += delta
    if fighter.defeated or fighter.stagger_timer > 0.0 or fighter.invulnerable_timer > 0.0:
        cancel()
        return
    if elapsed >= 0.18 and not released:
        released = true
        grab_box.call("activate", fighter, 12.0, 7.0, -3.0, 0.45, 0.10)
    if elapsed >= 0.58:
        cancel()

func start_grab() -> bool:
    if active or cooldown > 0.0 or not fighter.is_on_floor() or fighter.defeated or fighter.stagger_timer > 0.0 or fighter.dodge_timer > 0.0 or fighter.attack_active or fighter.jutsu_timer > 0.0 or fighter.chakra_dash_timer > 0.0 or is_instance_valid(fighter.cinematic_owner):
        return false
    active = true
    released = false
    elapsed = 0.0
    cooldown = 1.1
    fighter.is_guarding = false
    fighter.jutsu_timer = 0.58
    fighter.animation_action_id += 1
    return true

func try_perfect_guard(attacker: Node3D, damage: float) -> bool:
    if damage <= 0.0 or guard_age > 0.12 or counter_cooldown > 0.0 or not bool(fighter.call("get_is_guarding")) or fighter.invulnerable_timer > 0.0:
        return false
    counter_cooldown = 0.8
    fighter.guard_meter = minf(fighter.guard_meter + 8.0, 100.0)
    fighter.chakra = minf(fighter.chakra + 5.0, fighter.max_chakra)
    if attacker.has_method("_cancel_abilities"):
        attacker.call("_cancel_abilities")
        attacker.attack_active = false
        attacker.attack_hitbox.call("deactivate")
    else:
        attacker.call("_cancel_attack")
        attacker.call("_cancel_jutsu")
    attacker.stagger_timer = maxf(attacker.stagger_timer, 0.32)
    attacker.combat_state.call("mark_hit", 0.0, 0.0, 0.32, false)
    feedback_text = "DEFESA PERFEITA"
    feedback_timer = 0.8
    var feedback: Node = fighter.get_parent().get_node_or_null("CombatFeedback")
    if feedback != null:
        feedback.call("spawn_impact", fighter.global_position + Vector3.UP * 0.5, "guard")
    return true

func cancel() -> void:
    if active:
        fighter.jutsu_timer = 0.0
    active = false
    released = false
    if is_instance_valid(grab_box):
        grab_box.call("deactivate")
