extends SceneTree

var failures: int = 0
var checks: int = 0
var game: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D
var specials: Node3D
var adapter: Node3D

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
    specials.call("cancel")
    for clone: CharacterBody3D in specials.clones:
        clone.call("recycle")
    for projectile: Node3D in specials.projectiles:
        projectile.call("recycle")
    player.call("_respawn")
    enemy.call("_respawn")
    enemy.reactive_substitution = false
    enemy.juggle_hits = 0
    enemy.juggle_timer = 0.0
    enemy.set_physics_process(false)
    player.invulnerable_timer = 10.0
    player.global_position = Vector3(0, 0.91, 0)
    player.rotation.y = 0.0
    player.chakra = 100.0
    player.locked_target = enemy
    player.jutsu_cooldown = 0.0
    player.attack_cooldown = 0.0
    enemy.global_position = Vector3(0, 0.96, distance)
    enemy.guarding = false
    enemy.invulnerable_timer = 0.0
    game.get_node("HUD/MobileControls").move_vector = Vector2.ZERO

func run() -> void:
    game = load("res://main.tscn").instantiate() as Node3D
    root.add_child(game)
    game.get_node("CombatFeedback").hit_stop_enabled = false
    player = game.get_node("Player") as CharacterBody3D
    enemy = game.get_node("EnemyDummy") as CharacterBody3D
    specials = player.get_node("CombatSpecials") as Node3D
    adapter = player.get_node("RiggedCharacterAdapter") as Node3D
    await frames(8)
    reset()
    check(specials.clones.size() == 3 and specials.projectiles.size() == 3, "Fixed pools must prewarm")
    check(game.get_node("CombatFeedback").flashes.size() == 32, "VFX pool is bounded")
    for clone: CharacterBody3D in specials.clones:
        check(clone.skeleton != adapter.skeleton, "Clone skeleton must be independent")
        check(clone.animation_player.has_animation(&"combat/attack_4"), "Clone must reuse real clips")
    # Analog magnitude and orbit basis: lateral movement preserves radial distance.
    player.set_physics_process(false)
    var controls: Node = game.get_node("HUD/MobileControls")
    controls.move_vector = Vector2(0.4, 0)
    player.call("_apply_movement", 0.05)
    check(absf(player.velocity.x) > 0.0 and absf(player.velocity.z) < 0.1, "Lock movement must be tangent")
    controls.move_vector = Vector2(0.2, 0)
    player.velocity = Vector3.ZERO
    player.call("_apply_movement", 1.0)
    check(player.velocity.length() < 2.0, "Stick magnitude must scale speed")
    player.set_physics_process(true)
    reset()
    await frames(3)
    # Whiff denies dash cancel; hit permits after active window.
    enemy.global_position.z = 15.0
    player.call("_try_attack")
    await frames(10)
    player.call("_start_chakra_dash")
    check(player.chakra_dash_timer == 0.0, "Whiff must not allow confirmed dash cancel")
    player.call("_cancel_attack")
    player.attack_cooldown = 0.0
    enemy.global_position.z = 1.1
    player.call("_try_attack")
    await frames(15)
    check(player.attack_confirmed, "Bone strike must confirm")
    player.call("_start_chakra_dash")
    check(player.chakra_dash_timer > 0.0, "Confirmed recovery may cancel into dash")
    # Physical dash contact, no damage and guard recoil.
    reset(3.0)
    await frames(3)
    player.call("_start_chakra_dash")
    var hp: float = enemy.health
    await frames(22)
    check(enemy.health == hp, "Dash must not deal HP damage")
    check(player.chakra_dash_timer <= 0.0, "Dash must stop on hurtbox contact")
    reset(3.0)
    enemy.guarding = true
    player.call("_start_chakra_dash")
    await frames(13)
    check(player.stagger_timer > 0.0, "Guard must recoil a colliding dash")
    # Guard break and delayed regeneration.
    reset()
    player.set_physics_process(false)
    player.invulnerable_timer = 0.0
    player.is_guarding = true
    player.guard_meter = 10.0
    player.call("receive_combat_hit", 12.0, Vector3.BACK, 2.0, 0.0, 0.2)
    check(player.guard_meter == 0.0 and player.stagger_timer >= 0.9, "Guard exhaustion must stun")
    player.call("_update_timers", 0.5)
    check(player.guard_meter == 0.0, "Guard cannot instantly regenerate")
    player.call("_update_timers", 1.0)
    check(player.guard_meter > 0.0, "Guard must recover after delay")
    player.substitutions = 2
    player.call("_update_timers", 8.0)
    check(player.substitutions == 3, "Substitution charge must regenerate")
    player.set_physics_process(true)
    # Demon projectile: startup, contact, clone continuation, whiff, environment.
    reset(5.0)
    specials.call("start", "demon")
    check(enemy.health == 120.0 and player.chakra == 68.0, "Demon startup consumes chakra without damage")
    await frames(55)
    check(enemy.health < 120.0, "Demon must damage through collision")
    check(player.combo_hits > 1, "Demon confirm must produce clone follow-through")
    reset(5.0)
    enemy.global_position.x = 15.0
    player.locked_target = null
    specials.call("start", "demon")
    await frames(125)
    check(enemy.health == 120.0, "Projectile whiff cannot deal distance damage")
    for projectile: Node3D in specials.projectiles:
        check(not projectile.active, "Missed projectile must recycle")
    reset(5.0)
    var wall: StaticBody3D = StaticBody3D.new()
    var obstruction: CollisionShape3D = CollisionShape3D.new()
    var box: BoxShape3D = BoxShape3D.new()
    box.size = Vector3(4, 4, 0.4)
    obstruction.shape = box
    wall.add_child(obstruction)
    game.add_child(wall)
    wall.global_position = Vector3(0, 1, 2.5)
    await frames(3)
    specials.call("start", "demon")
    await frames(65)
    check(enemy.health == 120.0, "Demon cannot pass through scenario")
    wall.queue_free()
    await frames(3)
    # Hand-bound Rasengan hit, no hit out of trajectory, cancellation.
    reset(3.5)
    specials.call("start", "rasengan")
    await frames(13)
    check(enemy.health == 120.0, "Rasengan startup cannot damage")
    await frames(10)
    check(specials.rasengan_hitbox.global_position.distance_to(adapter.call("get_hand_world_position")) < 0.25, "Rasengan must follow hand bone")
    await frames(45)
    check(enemy.health < 120.0, "Rasengan must collide during active window")
    check(not specials.sphere_visual.visible and specials.rasengan_hitbox.remaining_time == 0.0, "Rasengan must dissipate and close")
    reset()
    enemy.global_position.x = 10.0
    player.locked_target = null
    specials.call("start", "rasengan")
    await frames(65)
    check(enemy.health == 120.0, "Rasengan whiff must not damage by range")
    reset()
    specials.call("start", "rasengan")
    player.invulnerable_timer = 0.0
    player.call("receive_combat_hit", 4.0, Vector3.BACK, 1.0, 0.0, 0.4)
    check(specials.current.is_empty() and specials.rasengan_hitbox.remaining_time == 0.0, "Hit must interrupt Rasengan")
    # Clone jutsu, bounded reuse and smoke/destruction.
    reset(3.0)
    specials.call("start", "clones")
    await frames(95)
    check(enemy.health < 120.0, "Charging Bullet clone strikes must connect")
    for clone: CharacterBody3D in specials.clones:
        check(not clone.active and not clone.visible, "Clones must return to pool")
    # Barrage whiff must not start camera sequence or summon offensive clones.
    reset(15.0)
    specials.call("start", "barrage")
    await frames(35)
    check(enemy.health == 120.0 and player.camera_rig.cinematic_remaining == 0.0, "Barrage miss cannot start cinematic")
    reset()
    specials.call("start", "barrage")
    await frames(18)
    check(is_instance_valid(specials.confirmed_target), "Barrage first bone hit must confirm")
    check(player.camera_rig.cinematic_remaining > 0.0, "Confirmed Barrage must frame sequence")
    await frames(105)
    check(enemy.health < 105.0, "Barrage must include intermediate and final real hits")
    check(enemy.velocity.y < 0.0, "Barrage final hit must apply slam")
    check(player.camera_rig.cinematic_remaining == 0.0 and specials.current.is_empty(), "Barrage must restore gameplay camera/control")
    # Actual launched fighter moves under gravity; final slam must still connect.
    reset()
    enemy.detection_range = 0.0
    enemy.attack_cooldown = 100.0
    enemy.set_physics_process(true)
    specials.call("start", "barrage")
    var saw_slam: bool = false
    for tick: int in range(75):
        await frames(1)
        if enemy.velocity.y < -10.0:
            saw_slam = true
    check(saw_slam, "Barrage must slam a physically launched target before ground bounce")
    check(enemy.health <= 94.0, "Moving target must receive the intermediate clone strike too")
    # Cancellation/KO safe and repeated pool use does not allocate more actors.
    reset()
    specials.call("start", "barrage")
    await frames(15)
    player.call("_try_substitution")
    check(specials.current.is_empty() and player.camera_rig.cinematic_remaining == 0.0, "Substitution must exit sequence safely")
    check(specials.clones.size() == 3 and specials.projectiles.size() == 3, "Pool capacity must remain fixed")
    # Blocked entry, aerial clone slam, anti-infinite and CPU reaction.
    reset()
    enemy.guarding = true
    specials.call("start", "barrage")
    await frames(30)
    check(player.camera_rig.cinematic_remaining == 0.0, "Blocked Barrage cannot enter sequence")
    reset(1.5)
    player.global_position.y = 3.0
    enemy.global_position.y = 3.0
    specials.call("start", "whirlwind")
    await frames(70)
    check(enemy.velocity.y < 0.0, "Whirlwind must end with clone slam")
    reset()
    for hit: int in range(13):
        enemy.call("receive_combat_hit", 1.0, Vector3.BACK, 0.0, 1.0, 0.4)
    check(enemy.invulnerable_timer > 0.0 and enemy.stagger_timer == 0.0, "Long hit chains must force recovery")
    reset()
    enemy.stagger_timer = 0.5
    enemy.reaction_timer = 0.1
    enemy.call("_update_timers", 0.12)
    check(enemy.substitutions == 3 and enemy.invulnerable_timer > 0.0, "CPU substitution must react after a decision delay")
    reset(5.0)
    await frames(3)
    var projectile: Node3D = specials.projectiles[0]
    projectile.call("launch", player, enemy, player.global_position + Vector3.UP * 0.25 + Vector3.BACK * 0.8, Vector3.BACK)
    projectile.call("_physics_process", 0.3)
    check(enemy.health < 120.0, "Swept projectile must hit across a long physics step")
    reset()
    specials.call("start", "rasengan")
    player.call("_defeat")
    check(specials.current.is_empty() and not specials.sphere_visual.visible, "KO must close specials and VFX")
    check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Mobile renderer must remain compatible")
    Engine.time_scale = 1.0
    print("STORM SLICE CONTRACT: ", "PASS" if failures == 0 else "FAIL", " (", checks, " checks, ", failures, " failures)")
    game.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
