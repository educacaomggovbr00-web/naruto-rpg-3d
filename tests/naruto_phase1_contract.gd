extends SceneTree

var failures: int = 0
var checks: int = 0
var game: Node3D
var fighter: CharacterBody3D
var enemy: CharacterBody3D
var ultimate: Node3D
var awakening: Node3D
var tools: Node3D
var controls: Node

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for i: int in range(count):
        await physics_frame

func reset(distance: float = 1.1) -> void:
    fighter.call("_respawn")
    enemy.call("_respawn")
    enemy.reactive_substitution = false
    enemy.set_physics_process(false)
    fighter.global_position = Vector3(0, 0.91, 0)
    fighter.rotation.y = 0.0
    fighter.chakra = 100.0
    fighter.invulnerable_timer = 0.0
    fighter.locked_target = enemy
    enemy.global_position = Vector3(0, 0.96, distance)
    enemy.invulnerable_timer = 0.0
    enemy.juggle_hits = 0
    enemy.juggle_timer = 0.0
    controls.move_vector = Vector2.ZERO
    for clone: CharacterBody3D in fighter.specials.clones:
        clone.call("recycle")

func await_clash() -> void:
    for i: int in range(60):
        await physics_frame
        if ultimate.phase == "clash" or ultimate.phase.is_empty():
            return

func run() -> void:
    game = load("res://main.tscn").instantiate() as Node3D
    root.add_child(game)
    game.get_node("CombatFeedback").hit_stop_enabled = false
    fighter = game.get_node("Player")
    enemy = game.get_node("EnemyDummy")
    ultimate = fighter.ultimate
    awakening = fighter.awakening
    tools = fighter.ninja_tools
    controls = game.get_node("HUD/MobileControls")
    await frames(8)
    reset(6.0)
    await frames(3)
    check(tools.projectiles.size() == 6, "Tool pool must be fixed and prewarmed")
    enemy.set_physics_process(true)
    fighter.chakra = 79.0
    check(not ultimate.start(), "Ultimate must require configured chakra")
    fighter.chakra = 100.0
    check(ultimate.start(), "Ultimate must accept neutral with enough chakra")
    check(is_equal_approx(fighter.chakra, 20.0), "Ultimate must consume resource on startup")
    await frames(10)
    check(enemy.health == enemy.max_health and not ultimate.cinematic_started, "Startup cannot apply damage or open cinematic")
    await await_clash()
    check(ultimate.phase == "clash" and ultimate.cinematic_started, "Thrown clone must physically confirm at range")
    check(is_instance_valid(enemy.cinematic_owner), "Confirmed target must be temporarily controlled")
    check(enemy.health < enemy.max_health, "Entry collision must deal actual damage")
    # The touch ATK button must drive the QTE, not buffered normal attacks.
    for i: int in range(8):
        ultimate.last_press_msec = -1000
        controls.attack_queue += 1
        await frames(4)
    check(ultimate.presses >= 8 and not fighter.attack_active, "Multitouch ATK must count QTE presses")
    await frames(220)
    check(ultimate.phase.is_empty(), "Successful Ultimate must return to gameplay")
    check(enemy.health <= enemy.max_health - 30.0, "Intermediate and final strikes must connect physically")
    check(enemy.cinematic_owner == null and fighter.jutsu_timer == 0.0, "Target/control locks must be released")
    check(fighter.camera_rig.cinematic_target == null and fighter.camera_rig.sequence_shot.is_empty(), "Camera must recover after Ultimate")
    for clone: CharacterBody3D in fighter.specials.clones:
        check(not clone.active, "Ultimate clones must recycle")
    check(not ultimate.start(), "Ultimate cooldown must prevent immediate reuse")
    # Whiff, guard, guard break and invulnerability never start a cinematic.
    reset(20.0)
    await frames(3)
    ultimate.start()
    await frames(80)
    check(enemy.health == enemy.max_health and not ultimate.cinematic_started, "Ultimate whiff cannot damage by distance")
    reset(2.5)
    await frames(3)
    enemy.guarding = true
    ultimate.start()
    await frames(80)
    check(not ultimate.cinematic_started and enemy.cinematic_owner == null, "Guarded entry cannot start cinematic")
    reset(2.5)
    await frames(3)
    enemy.guarding = true
    enemy.guard_meter = 1.0
    ultimate.start()
    await frames(80)
    check(not ultimate.cinematic_started, "Entry that breaks guard is still a blocked entry")
    reset(2.5)
    await frames(3)
    enemy.invulnerable_timer = 10.0
    ultimate.start()
    await frames(80)
    check(enemy.health == enemy.max_health and not ultimate.cinematic_started, "Invulnerable entry cannot confirm")
    # Terrain must stop the thrown clone before the opponent.
    reset(6.0)
    await frames(3)
    var wall: StaticBody3D = StaticBody3D.new()
    var collision: CollisionShape3D = CollisionShape3D.new()
    var wall_shape: BoxShape3D = BoxShape3D.new()
    wall_shape.size = Vector3(4, 4, 0.4)
    collision.shape = wall_shape
    wall.add_child(collision)
    game.add_child(wall)
    wall.global_position = Vector3(0, 1, 2.0)
    await frames(3)
    ultimate.start()
    await frames(80)
    check(enemy.health == enemy.max_health and not ultimate.cinematic_started, "Scenery must intercept Ultimate clone")
    check(ultimate.last_result == "scenery", "Scenery impact must clean up entry")
    wall.queue_free()
    await frames(3)
    # Identical CPU rhythm with different player scores proves no input reading.
    ultimate.clash_rng.seed = 1234
    ultimate.cpu_press_timer = 0.1
    ultimate.cpu_presses = 0
    ultimate.presses = 0
    ultimate.call("_advance_cpu_clash", 0.8)
    var independent_score: int = ultimate.cpu_presses
    ultimate.clash_rng.seed = 1234
    ultimate.cpu_press_timer = 0.1
    ultimate.cpu_presses = 0
    ultimate.presses = 99
    ultimate.call("_advance_cpu_clash", 0.8)
    check(independent_score > 0 and ultimate.cpu_presses == independent_score, "CPU QTE rhythm must not read player presses")
    reset(3.0)
    await frames(3)
    ultimate.start()
    await await_clash()
    check(ultimate.presses == 0 and ultimate.cpu_presses == 0, "New clash must reset both scores")
    ultimate.last_press_msec = -1000
    ultimate.press_attack()
    ultimate.press_attack()
    check(ultimate.presses == 1, "Duplicate same-frame ATK must not inflate QTE score")
    ultimate.presses = 4
    ultimate.cpu_presses = 4
    ultimate.cpu_press_timer = 10.0
    var tied_hp: float = enemy.health
    await frames(65)
    check(ultimate.last_result == "clash_lost" and enemy.health == tied_hp, "Tie cannot start follow-up despite reaching minimum presses")
    check(enemy.cinematic_owner == null and fighter.camera_rig.cinematic_target == null, "Lost race must release camera and control")
    reset(3.0)
    await frames(3)
    ultimate.start()
    await await_clash()
    ultimate.presses = 4
    ultimate.cpu_presses = 6
    ultimate.cpu_press_timer = 10.0
    await frames(65)
    check(ultimate.last_result == "clash_lost", "Minimum presses must still lose to faster CPU")
    # Lost QTE and substitution restore everything without follow-up damage.
    reset(3.0)
    await frames(3)
    ultimate.start()
    await await_clash()
    var entry_hp: float = enemy.health
    await frames(75)
    check(ultimate.last_result == "clash_lost" and enemy.health == entry_hp, "Lost QTE cannot launch follow-up hits")
    reset(3.0)
    await frames(3)
    ultimate.start()
    await await_clash()
    enemy.call("_substitute")
    await frames(3)
    check(ultimate.phase.is_empty() and ultimate.last_result == "substitution", "Substitution must escape confirmed Ultimate")
    check(enemy.cinematic_owner == null and fighter.camera_rig.cinematic_target == null, "Escape must release camera and target")
    # Target KO and attacker KO; scene removal cannot strand pooled siblings.
    reset(3.0)
    await frames(3)
    ultimate.start()
    await await_clash()
    enemy.call("_knock_out")
    await frames(3)
    check(ultimate.phase.is_empty() and enemy.cinematic_owner == null, "Target KO must safely cancel Ultimate")
    reset(3.0)
    await frames(3)
    ultimate.start()
    await await_clash()
    fighter.call("_defeat")
    await frames(3)
    check(ultimate.phase.is_empty() and enemy.cinematic_owner == null, "Attacker KO must safely cancel Ultimate")
    reset(6.0)
    await frames(3)
    enemy.set_physics_process(true)
    enemy.call("begin_cinematic_lock", ultimate)
    await frames(35)
    check(enemy.cinematic_owner == null, "Watchdog must release an abandoned cinematic lock")
    enemy.set_physics_process(false)
    # Shared clone pool: interruption removes only the cancelling sequence's actors.
    reset(3.0)
    await frames(3)
    check(fighter.specials.summon_clone(enemy, Vector3(0, 0, -0.7), 0.5, "attack_2"), "Clone attack must reserve a pooled actor")
    var special_clone: CharacterBody3D = fighter.specials.clones[0]
    check(special_clone.active and special_clone.sequence_owner == fighter.specials, "Clone activation must record sequence ownership")
    fighter.specials.cancel(false)
    check(special_clone.active, "Normal jutsu recovery must let released clone finish")
    var interrupted_hp: float = enemy.health
    fighter.specials.cancel()
    check(not special_clone.active and special_clone.sequence_owner == null, "Interruption must recycle pending clone and clear its owner")
    await frames(65)
    check(enemy.health == interrupted_hp, "Cancelled clone cannot deliver a delayed ghost hit")
    special_clone.call("present", fighter.global_position, 0.0, 1.0, "guard", ultimate)
    fighter.specials.cancel()
    check(special_clone.active and special_clone.sequence_owner == ultimate, "Jutsu cleanup cannot recycle an Ultimate-owned pool actor")
    special_clone.call("recycle")
    check(special_clone.sequence_owner == null, "Recycling must not retain ownership across pool reuse")
    # Awakening: full chakra + low HP, vulnerable transition, non-stacking stats.
    reset()
    await frames(3)
    fighter.health = 100.0
    check(not awakening.start(), "Awakening must require low health")
    fighter.health = 20.0
    fighter.chakra = 90.0
    check(not awakening.start(), "Awakening must require full chakra")
    fighter.chakra = 100.0
    check(awakening.start(), "Low health + full chakra must allow transformation")
    check(not awakening.active and awakening.transforming, "Awakening must have transition")
    fighter.call("receive_combat_hit", 1.0, Vector3.BACK, 0.0, 0.0, 0.2)
    await frames(2)
    check(not awakening.active and not awakening.transforming, "Hit must interrupt vulnerable transformation")
    reset()
    await frames(3)
    fighter.health = 20.0
    fighter.chakra = 100.0
    var base_speed: float = fighter.move_speed
    awakening.start()
    await frames(65)
    check(awakening.active and awakening.tail.visible, "One-tail mode must activate after transition")
    check(fighter.get_damage_multiplier() > 1.0 and fighter.move_speed == base_speed, "Buffs must not mutate/stack base stats")
    check(fighter.receive_tool_hit(3.0, Vector3.BACK, 1.0, 0.0, 0.2) == 0.0, "One-tail mode must reject ninja tools")
    check(not ultimate.start(), "Handbook cannot silently substitute for awakened Sealed Power")
    fighter.jutsu_cooldown = 0.0
    fighter.chakra = 100.0
    fighter.specials.start("demon")
    check(fighter.specials.current == "rasengan", "Awakened ninjutsu must override selected jutsu")
    fighter.specials.cancel()
    awakening.remaining = 0.01
    await frames(2)
    check(not awakening.active and not awakening.tail.visible and fighter.get_damage_multiplier() == 1.0, "Awakening expiry must restore base state")
    # Profile controls must bound orbit instances and transparent passes.
    var orb: MeshInstance3D = fighter.specials.sphere_visual
    orb.call("set_quality", 0)
    check(orb.orbits.multimesh.visible_instance_count == 4 and not orb.shell.visible, "LOW must disable additive shell")
    orb.call("set_quality", 2)
    check(orb.orbits.multimesh.visible_instance_count == 12, "HIGH must retain bounded VFX budget")
    var quality: Node = game.get_node("MobileQuality")
    var hp_before: float = fighter.health
    quality.call("apply", 0, false)
    check(game.get_node("CombatFeedback").effect_budget == 12 and not game.get_node("Sun").shadow_enabled, "LOW must lower effects and shadows")
    check(is_equal_approx(root.scaling_3d_scale, 0.70), "LOW must scale 3D while preserving touch viewport")
    quality.call("apply", 2, false)
    check(game.get_node("CombatFeedback").effect_budget == 32 and orb.orbits.multimesh.visible_instance_count == 12, "HIGH must restore bounded budgets")
    check(fighter.health == hp_before and fighter.rig_adapter.real_animation_count == 27, "Quality changes cannot alter combat or clips")
    # Inventory, startup, physical tools, buffs, healing chakra and lifecycle.
    reset(6.0)
    await frames(3)
    tools.selected = 0
    check(tools.use(), "Shuriken must be available")
    check(enemy.health == enemy.max_health, "Tool startup cannot deal damage")
    await frames(45)
    check(enemy.health < enemy.max_health, "Shuriken must collide with hurtbox")
    reset(6.0)
    await frames(3)
    tools.selected = 3
    tools.use()
    check(tools.stock.kunai_rain == 1, "Kunai rain must consume finite stock")
    await frames(18)
    var knives: int = 0
    for projectile: Node3D in tools.projectiles:
        if projectile.active and projectile.kunai.visible and not projectile.shuriken.visible:
            knives += 1
    check(knives == 3, "Kunai rain must use knife silhouettes instead of shuriken meshes")
    await frames(30)
    check(enemy.health <= enemy.max_health - 6.0, "Kunai rain must fire separate physical projectiles")
    reset(4.0)
    await frames(3)
    tools.selected = 4
    tools.use()
    await frames(45)
    check(enemy.health == enemy.max_health - 9.0, "Bomb must damage once through explosion volume")
    reset(20.0)
    await frames(3)
    tools.selected = 0
    fighter.locked_target = null
    enemy.global_position.x = 15.0
    tools.use()
    await frames(110)
    check(enemy.health == enemy.max_health, "Missed tool cannot apply distance damage")
    for projectile: Node3D in tools.projectiles:
        check(not projectile.active, "Tool timeout must recycle")
    reset()
    await frames(3)
    fighter.chakra = 30.0
    tools.selected = 1
    tools.use()
    await frames(20)
    check(fighter.chakra >= 60.0 and tools.stock.ramen == 0, "Ramen must restore chakra and consume stock")
    tools.cooldown = 0.0
    fighter.jutsu_timer = 0.0
    check(not tools.use(), "Empty inventory cannot be used")
    tools.selected = 2
    tools.use()
    await frames(20)
    check(tools.buff_remaining > 19.0 and is_equal_approx(fighter.get_damage_multiplier(), 1.2), "Food pill must grant finite attack buff")
    tools.buff_remaining = 0.01
    await frames(2)
    check(fighter.get_damage_multiplier() == 1.0, "Food pill must expire without mutating base damage")
    fighter.call("_respawn")
    check(tools.stock.ramen == 1 and tools.buff_remaining == 0.0, "New training round must restore inventory")
    controls.charge_touch = 1
    controls.guard_touch = 2
    controls.joystick_touch = 3
    controls.move_vector = Vector2.ONE
    controls.ultimate_queue = 1
    controls.call("_notification", Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(controls.charge_touch == -1 and controls.guard_touch == -1 and controls.move_vector == Vector2.ZERO and controls.ultimate_queue == 0, "Focus loss must release multitouch holds and queued actions")
    reset(3.0)
    await frames(3)
    ultimate.start()
    await await_clash()
    ultimate.presses = 8
    await frames(65)
    check(ultimate.phase == "dogpile", "Scene cleanup must be exercised during active clone sequence")
    var pool_count: int = tools.projectiles.size()
    game.queue_free()
    await frames(4)
    check(root.get_child_count() == 0, "Scene removal must destroy sibling pools and control locks")
    check(pool_count == 6, "Tool pool cannot grow during battle")
    print("NARUTO PHASE 1 CONTRACT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
    quit(1 if failures > 0 else 0)
