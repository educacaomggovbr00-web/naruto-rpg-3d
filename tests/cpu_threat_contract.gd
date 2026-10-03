extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int) -> void:
    for index: int in range(count):
        await physics_frame
func run() -> void:
    var arena: Node3D = load("res://main.tscn").instantiate()
    root.add_child(arena)
    var fighter: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    cpu.enable_arsenal = false
    cpu.react_to_projectiles = false
    await frames(8)
    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    arena.get_node("CombatFeedback").hit_stop_enabled = false
    cpu.global_position = Vector3(0, 0.96, 0)
    fighter.global_position = Vector3(0, 0.96, -8)
    await frames(2)
    var flame: Node3D = Node3D.new()
    flame.set_script(preload("res://scripts/fireball_projectile.gd"))
    arena.add_child(flame)
    flame.set_physics_process(false)
    flame.launch(fighter, cpu, Vector3(0, 0.96, -4), Vector3.BACK)
    check(cpu._observe_projectile() == flame, "Incoming released projectile must be observable")
    flame.direction = Vector3.FORWARD
    check(cpu._observe_projectile() == null, "Outbound projectile is not a threat")
    flame.direction = Vector3.BACK
    flame.global_position.x = 4.0
    check(cpu._observe_projectile() == null, "Trajectory that misses CPU must not trigger perfect defense")
    flame.global_position = Vector3(0, 0.96, -20)
    check(cpu._observe_projectile() == null, "CPU cannot react across the entire arena")
    flame.global_position = Vector3(0, 0.96, -4)
    flame.owner_fighter = cpu
    flame.hit_mask = 8
    check(cpu._observe_projectile() == null, "Friendly projectiles must be ignored")
    flame.owner_fighter = fighter
    flame.hit_mask = 16
    flame.active = false
    check(cpu._observe_projectile() == null, "Recycled projectiles must not trigger defense")
    flame.active = true
    cpu.stagger_timer = 0.2
    check(not cpu._react_to_projectile(), "Projectile reaction cannot cancel hitstun")
    cpu.stagger_timer = 0.0
    cpu.attack_active = true
    check(not cpu._react_to_projectile(), "Projectile reaction cannot escape attack recovery for free")
    cpu.attack_active = false
    cpu.decision_rng.seed = 179
    var guards: int = 0
    var dodges: int = 0
    var missed: int = 0
    for attempt: int in range(50):
        cpu.guarding = false
        cpu.guard_timer = 0.0
        cpu.dodge_timer = 0.0
        cpu.invulnerable_timer = 0.0
        cpu.guard_meter = 100.0
        var reacted: bool = cpu._react_to_projectile()
        if not reacted:
            missed += 1
        elif cpu.guarding:
            guards += 1
        elif cpu.dodge_timer > 0.0:
            dodges += 1
    check(guards > 0 and dodges > 0 and missed > 0, "CPU must use guard/dodge and retain chance of failure")
    check(guards + dodges + missed == 50, "Each neutral observation yields at most one reaction")
    cpu.guarding = false
    cpu.guard_timer = 0.0
    cpu.dodge_timer = 0.0
    cpu.guard_meter = 10.0
    cpu.decision_rng.seed = 179
    for attempt: int in range(20):
        if cpu._react_to_projectile():
            break
    check(not cpu.guarding and cpu.dodge_timer > 0.0, "Low guard resource favors real dodge")
    check(cpu.invulnerable_timer > 0.0 and cpu.dodge_direction.length() > 0.99, "Dodge must create bounded invulnerability and actual movement")
    check(absf(cpu.dodge_direction.dot(Vector3.BACK)) < 0.1, "Dodge moves across the projectile path")
    var health: float = cpu.health
    flame.global_position = cpu.global_position - Vector3.BACK * 0.6
    flame._physics_process(0.04)
    check(cpu.health == health and not flame.active, "Invulnerability must prevent damage from a real swept contact")
    cpu.dodge_timer = 0.0
    cpu.invulnerable_timer = 0.0
    cpu.decision_rng.seed = 179
    fighter.mobile_controls.jutsu_queue = 999
    check(cpu._observe_projectile() == null, "Queued player input without a launched entity is not a threat")
    fighter.mobile_controls.jutsu_queue = 0
    arena.queue_free()
    await frames(4)
    check(root.get_child_count() == 1, "Threat handling must not leak entities")
    print("CPU THREAT CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
