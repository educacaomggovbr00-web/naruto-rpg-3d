extends Node3D
## Naruto Storm 1 slots: ramen, food pills, kunai rain, bomb ball.
const SLOTS: Array[String] = ["shuriken", "ramen", "food_pills", "kunai_rain", "bomb"]
var fighter: CharacterBody3D
var stock: Dictionary = {"ramen": 1, "food_pills": 2, "kunai_rain": 2, "bomb": 2}
var selected: int = 0
var cooldown: float = 0.0
var buff_remaining: float = 0.0
var pending: String = ""
var startup_remaining: float = 0.0
var projectiles: Array[Node3D] = []

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D
    process_physics_priority = 15
    call_deferred("warm_pool")

func warm_pool() -> void:
    for i: int in range(6):
        var projectile: Node3D = Node3D.new()
        projectile.set_script(preload("res://scripts/ninja_tool_projectile.gd"))
        fighter.get_parent().add_child(projectile)
        projectiles.append(projectile)

func cycle() -> void:
    selected = (selected + 1) % SLOTS.size()

func use() -> bool:
    var item: String = SLOTS[selected]
    if cooldown > 0.0 or not pending.is_empty() or not fighter.call("_can_use_movement_action") or fighter.attack_cooldown > 0.0:
        return false
    if item != "shuriken" and int(stock[item]) <= 0:
        return false
    var count: int = 3 if item == "kunai_rain" else 1 if item in ["shuriken", "bomb"] else 0
    var free: int = 0
    for projectile: Node3D in projectiles:
        if not projectile.active:
            free += 1
    if free < count:
        return false
    if item != "shuriken":
        stock[item] = int(stock[item]) - 1
    pending = item
    startup_remaining = float(fighter.rig_adapter.manifest["clips"]["jutsu"].get("impact", 0.24))
    cooldown = 0.6
    fighter.jutsu_timer = 0.45
    fighter.animation_action_id += 1
    fighter.is_guarding = false
    fighter.is_charging_chakra = false
    return true

func _physics_process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)
    buff_remaining = maxf(buff_remaining - delta, 0.0)
    if pending.is_empty():
        return
    if fighter.defeated or fighter.stagger_timer > 0.0 or fighter.jutsu_timer <= 0.0:
        pending = ""
        return
    startup_remaining -= delta
    if startup_remaining > 0.0:
        return
    var item: String = pending
    pending = ""
    if item == "ramen":
        fighter.chakra = minf(fighter.max_chakra, fighter.chakra + fighter.max_chakra * 0.30)
    elif item == "food_pills":
        buff_remaining = 20.0
    else:
        var count: int = 3 if item == "kunai_rain" else 1
        for i: int in range(count):
            for projectile: Node3D in projectiles:
                if not projectile.active:
                    var direction: Vector3 = fighter.global_basis.z
                    if is_instance_valid(fighter.locked_target):
                        direction = (fighter.locked_target.global_position - fighter.global_position).normalized()
                    direction = direction.rotated(Vector3.UP, (float(i) - float(count - 1) * 0.5) * 0.10)
                    var kind: String = "kunai" if item == "kunai_rain" else "wind" if fighter.awakening.active and item == "shuriken" else item
                    projectile.call("launch", fighter, fighter.locked_target, fighter.rig_adapter.call("get_hand_world_position"), direction, kind)
                    break

func cancel() -> void:
    pending = ""

func reset() -> void:
    pending = ""
    cooldown = 0.0
    buff_remaining = 0.0
    stock = {"ramen": 1, "food_pills": 2, "kunai_rain": 2, "bomb": 2}
    for projectile: Node3D in projectiles:
        projectile.call("recycle")

func damage_multiplier() -> float:
    return 1.2 if buff_remaining > 0.0 else 1.0

func _exit_tree() -> void:
    for projectile: Node3D in projectiles:
        if is_instance_valid(projectile):
            projectile.queue_free()
