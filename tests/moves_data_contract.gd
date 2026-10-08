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
    root.get_node("GameFlow").player_character = CharacterCatalog.NARUTO
    var arena: Node3D = load("res://main.tscn").instantiate()
    root.add_child(arena)
    await frames(8)
    var fighter: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    var controls: Control = arena.get_node("HUD/MobileControls")
    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    cpu.reactive_substitution = false
    arena.get_node("CombatFeedback").hit_stop_enabled = false
    check(fighter.moveset == cpu.moveset, "Both fighters must use the shared moveset resource")
    for air: bool in [false, true]:
        for step: int in range(1, 5):
            var attack: AttackDefinition = fighter.moveset.attack(step, air)
            var timing: Dictionary = attack.animation_timing(fighter.rig_adapter.manifest)
            check(not timing.is_empty() and timing.has("startup") and timing.has("active") and timing.has("recovery"), "Every attack needs real baked timing")
    fighter._respawn()
    fighter.global_position = Vector3(0, 0.91, 0)
    cpu.global_position = Vector3(0, 0.96, 1.1)
    fighter.set_physics_process(true)
    await frames(8)
    fighter.set_physics_process(false)
    check(fighter.is_on_floor(), "Branch fixture must stand on physical floor")
    for branch: String in ["neutral", "up", "down", "side"]:
        fighter._cancel_attack()
        fighter.attack_cooldown = 0.0
        fighter.combo_step = 2
        fighter.combo_timer = 1.0
        fighter.stagger_timer = 0.0
        controls.move_vector = Vector2(0, -1) if branch == "up" else Vector2(0, 1) if branch == "down" else Vector2(1, 0) if branch == "side" else Vector2.ZERO
        fighter._try_attack()
        check(fighter.combo_branch == branch, "Direction must be sampled after the two intro hits")
        fighter.combo_step = 4
        fighter._open_attack_hitbox()
        var hitbox: Area3D = fighter.attack_hitbox
        check(hitbox.launch_velocity > 0.0 if branch == "up" else hitbox.launch_velocity < 0.0 if branch == "down" else is_zero_approx(hitbox.launch_velocity) if branch == "neutral" else hitbox.knockback == 10.0, "Each ground branch needs its distinct physical finisher")
    fighter._cancel_attack()
    fighter.attack_cooldown = 0.0
    fighter.combo_step = 1
    fighter.combo_timer = 0.0
    controls.move_vector = Vector2(0, -1)
    fighter._try_attack()
    check(fighter.combo_branch == "neutral", "First input cannot prematurely lock the directional branch")
    fighter.combo_step = 2
    fighter.attack_elapsed = 0.15
    fighter.attack_startup = 0.12
    fighter._try_attack()
    controls.move_vector = Vector2.ZERO
    fighter.attack_active = false
    fighter.attack_cooldown = 0.0
    fighter._try_attack()
    check(fighter.combo_branch == "up", "Queued direction must survive releasing the touchscreen stick")
    # A block that breaks the meter is still a block, not a hit confirm.
    fighter.attack_confirmed = false
    cpu.guarding = true
    cpu.guard_meter = 1.0
    cpu.invulnerable_timer = 0.0
    fighter.attack_hitbox.activate(fighter, 10.0, 1.0, 0.0, 0.2, 0.09)
    fighter.attack_hitbox.try_hit(cpu)
    check(cpu.guard_meter == 0.0 and not fighter.attack_confirmed, "Guard break must retain pre-hit blocked classification")
    var projectile: Node3D = fighter.specials.projectiles[0]
    check(projectile.definition is ProjectileDefinition, "Demon Wind must consume a projectile Resource")
    var custom: ProjectileDefinition = projectile.definition.duplicate()
    custom.radius = 0.25
    custom.lifetime = 0.3
    projectile.definition = custom
    projectile.launch(fighter, cpu, Vector3(0, 4, 0), Vector3.BACK)
    check(projectile.remaining == 0.3 and projectile.shape.radius == 0.25, "Projectile runtime must read configuration, not constants")
    projectile.recycle()
    fighter._cancel_attack()
    controls.move_vector = Vector2.ZERO
    arena.queue_free()
    await frames(4)
    check(root.get_child_count() == 1, "Data-driven fighters/projectiles must clean up")
    print("MOVES DATA CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
