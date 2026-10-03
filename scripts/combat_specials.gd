extends Node3D

var projectiles: Array[Node3D] = []
var selected: String = "demon"
var current: String = ""
var elapsed: float = 0.0
var duration: float = 0.0
var released: bool = false
var owner_fighter: CharacterBody3D

func _ready() -> void:
    owner_fighter = get_parent() as CharacterBody3D
    process_physics_priority = 5
    for i: int in range(3):
        var projectile: Node3D = Node3D.new()
        projectile.set_script(preload("res://scripts/chakra_projectile.gd"))
        get_tree().current_scene.add_child.call_deferred(projectile)
        projectiles.append(projectile)

func start(kind: String = "") -> bool:
    var move: String = selected if kind.is_empty() else kind
    if not current.is_empty() or owner_fighter.defeated or owner_fighter.stagger_timer > 0.0 or owner_fighter.attack_active or owner_fighter.dodge_timer > 0.0 or owner_fighter.chakra_dash_timer > 0.0 or owner_fighter.jutsu_cooldown > 0.0:
        return false
    if owner_fighter.chakra < 32.0:
        return false
    owner_fighter.chakra -= 32.0
    owner_fighter.jutsu_cooldown = 1.5
    owner_fighter.jutsu_timer = 0.65
    owner_fighter.is_guarding = false
    owner_fighter.is_charging_chakra = false
    owner_fighter.animation_action_id += 1
    current = move
    elapsed = 0.0
    duration = 0.65
    released = false
    return true

func _physics_process(delta: float) -> void:
    if current.is_empty():
        return
    if owner_fighter.defeated or owner_fighter.stagger_timer > 0.0 or owner_fighter.jutsu_timer <= 0.0:
        cancel()
        return
    elapsed += delta
    if not released and elapsed >= 0.24:
        released = true
        for projectile: Node3D in projectiles:
            if projectile.is_inside_tree() and not projectile.active:
                projectile.call("launch", owner_fighter, owner_fighter.locked_target, owner_fighter.global_position + Vector3.UP * 0.25 + owner_fighter.global_basis.z * 0.8, owner_fighter.global_basis.z)
                break
    if elapsed >= duration:
        cancel()

func cancel() -> void:
    current = ""
    owner_fighter.jutsu_timer = 0.0

func demon_confirm(_target: Node) -> void:
    pass # Clone follow-through added after the reusable clone pool.

func _exit_tree() -> void:
    for projectile: Node3D in projectiles:
        if is_instance_valid(projectile):
            projectile.queue_free()
