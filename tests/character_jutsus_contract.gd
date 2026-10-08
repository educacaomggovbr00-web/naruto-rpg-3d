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
func clear_fighter(fighter: CharacterBody3D) -> void:
    if fighter.has_method("_cancel_jutsu"):
        fighter._cancel_jutsu()
    else:
        fighter._cancel_abilities()
    fighter.jutsu_cooldown = 0.0
    fighter.stagger_timer = 0.0
    fighter.invulnerable_timer = 0.0
    fighter.attack_active = false
    fighter.chakra = fighter.max_chakra
    fighter.velocity = Vector3.ZERO
func run() -> void:
    var persistent_nodes: int = root.get_child_count()
    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("sakura", "kakashi", "training") == OK, "Mixed fighter battle loads")
    await frames(10)
    var arena: Node3D = current_scene
    var player: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    player.set_physics_process(false)
    cpu.set_physics_process(false)
    cpu.enable_arsenal = false
    cpu.react_to_projectiles = false
    arena.get_node("CombatFeedback").hit_stop_enabled = false
    player.specials.set_physics_process(false)
    cpu.specials.set_physics_process(false)
    player.global_position = Vector3(0, 0.96, -6)
    player.rotation.y = 0.0
    cpu.global_position = Vector3(0, 0.96, 5)
    cpu.guarding = false
    cpu.invulnerable_timer = 0.0
    cpu.reactive_substitution = false
    await frames(2)
    player.velocity = Vector3.DOWN * 12.0
    player.move_and_slide()
    await frames(2)
    var data: JutsuDefinition = CharacterCatalog.SAKURA.find_jutsu("booby_trap")
    check(data != null and data.strategy == "trap", "Sakura selects distinct trap strategy")
    check(data.tuning_evidence == "OUR_APPROXIMATION", "Runtime tuning never claims official frame data")
    for definition: CharacterDefinition in CharacterCatalog.READY:
        for id: String in definition.jutsus:
            check(definition.find_jutsu(id) != null, "Every selectable jutsu has reusable data")
    check(player.specials.traps.size() == 3 and cpu.specials.traps.is_empty(), "Pools are allocated only by relevant character")
    clear_fighter(player)
    check(player.specials.start(), "Grounded Sakura starts trap")
    check(player.chakra == 76.0 and player.jutsu_cooldown == data.cooldown, "Trap consumes own cost/cooldown")
    player.specials._physics_process(0.23)
    check(not player.specials.traps[0].active, "No trap before real clip release")
    player.specials.cancel()
    check(not player.specials.traps[0].active, "Interrupted startup cannot leave trap")
    clear_fighter(player)
    player.specials.start()
    player.specials._physics_process(0.25)
    var trap: Node3D = player.specials.traps[0]
    trap.set_physics_process(false)
    check(trap.active and trap.phase == "armed", "Clip release arms reusable world entity")
    player.specials._physics_process(0.50)
    check(trap.active and player.specials.current.is_empty(), "Released trap survives owner's normal recovery")
    var health: float = cpu.health
    trap._physics_process(0.05)
    check(trap.phase == "armed" and cpu.health == health, "No distance-based damage or trigger")
    cpu.global_position = trap.global_position + Vector3.UP * 0.96
    await frames(2)
    trap._physics_process(0.01)
    check(trap.phase == "falling" and cpu.health == health, "Wire contact triggers ball without instant damage")
    for index: int in range(12):
        trap._physics_process(0.03)
    check(cpu.health < health and not trap.active, "Actual swept ball collision damages once and recycles")
    var after_hit: float = cpu.health
    trap._physics_process(1.0)
    check(cpu.health == after_hit, "Recycled ball cannot hit twice")
    clear_fighter(cpu)
    cpu.guarding = false
    cpu.health = cpu.max_health
    cpu.global_position = Vector3(0, 0.96, 5)
    await frames(2)
    check(trap.arm(player, data), "Trap reuses same node")
    cpu.global_position = trap.global_position + Vector3.UP * 0.96
    await frames(2)
    trap._physics_process(0.01)
    cpu.global_position.x += 4.0
    await frames(2)
    for index: int in range(14):
        trap._physics_process(0.03)
    check(cpu.health == cpu.max_health and not trap.active, "Dodging after trigger avoids fixed drop trajectory")
    cpu.global_position = Vector3(0, 0.96, 5)
    await frames(2)
    trap.arm(player, data)
    trap._physics_process(data.trap_lifetime + 0.1)
    check(not trap.active, "Unused trap expires")
    for item: Node3D in player.specials.traps:
        check(item.arm(player, data), "Bounded pool can hold three traps")
        item.set_physics_process(false)
    clear_fighter(player)
    check(not player.specials.start() and player.chakra == player.max_chakra, "Full pool rejects fourth trap before resource consumption")
    player.defeated = true
    for item: Node3D in player.specials.traps:
        item._physics_process(0.01)
        check(not item.active, "Owner KO releases active traps")
    player.defeated = false
    for defense: String in ["guard", "invulnerability"]:
        clear_fighter(cpu)
        cpu.health = cpu.max_health
        cpu.guard_meter = 100.0
        cpu.guarding = defense == "guard"
        cpu.invulnerable_timer = 1.0 if defense == "invulnerability" else 0.0
        cpu.global_position = Vector3(0, 0.96, 5)
        await frames(2)
        trap.arm(player, data)
        cpu.global_position = trap.global_position + Vector3.UP * 0.96
        await frames(2)
        trap._physics_process(0.01)
        for index: int in range(12):
            trap._physics_process(0.03)
        check(not trap.active, "Defended ball recycles")
        if defense == "guard":
            check(cpu.health > cpu.max_health - data.damage and cpu.guard_meter < 100.0, "Guard applies chip and guard damage to physical ball")
        else:
            check(cpu.health == cpu.max_health, "Substitution invulnerability defeats physical ball")
    cpu.guarding = false
    player.global_position = Vector3(0, 0.96, 28.8)
    player.rotation.y = 0.0
    await frames(2)
    check(not trap.arm(player, data), "Wall blocks trap placement rather than spawning through it")
    player.global_position = Vector3(0, 6.0, -6)
    await frames(2)
    check(not trap.arm(player, data), "Trap cannot arm suspended above floor")
    player.global_position = Vector3(0, 0.96, -6)
    await frames(2)
    var lightning: JutsuDefinition = CharacterCatalog.KAKASHI.find_jutsu("raikiri")
    var chidori: JutsuDefinition = CharacterCatalog.SASUKE.find_jutsu("chidori")
    check(lightning != chidori and lightning.damage != chidori.damage and lightning.tracking_strength != chidori.tracking_strength, "Kakashi lightning is independently tuned from Sasuke")
    clear_fighter(cpu)
    check(cpu.specials.start("raikiri"), "CPU uses own Raikiri through shared controller")
    cpu.specials._physics_process(0.37)
    check(not cpu.specials.active_opened, "Raikiri respects real baked startup")
    cpu.specials._physics_process(0.02)
    check(cpu.specials.active_opened and cpu.specials.rasengan_hitbox.collision_mask == 8, "Raikiri opens physical hand hitbox against correct team")
    check(cpu.specials.movement_velocity(0.02).length() <= lightning.movement_speed, "Raikiri movement is bounded by definition")
    cpu.specials.cancel()
    clear_fighter(cpu)
    check(cpu.specials.start("fireball"), "Kakashi can use reference alternate Fireball")
    cpu.specials._physics_process(0.25)
    var projectile: Node3D = cpu.specials.projectiles[0]
    check(projectile.active and projectile.definition.projectile_id == "sasuke_fireball", "Non-default Fireball selection releases correct physical projectile")
    check(not cpu.specials.start("rasengan"), "Kakashi cannot borrow Naruto's arsenal")
    arena.queue_free()
    await frames(5)
    check(root.get_child_count() == persistent_nodes, "New pools release completely on battle exit")
    print("CHARACTER JUTSUS CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
