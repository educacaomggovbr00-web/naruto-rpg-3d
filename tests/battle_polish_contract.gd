extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int) -> void:
    while root.get_node("GameFlow").busy: await process_frame
    for index: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    var fixture: Node = preload("res://scripts/combat_settings.gd").new()
    var preference_path: String = "user://battle_polish_preferences_test.json"
    fixture.camera_fov = 68.0
    fixture.camera_shake = .25
    fixture.camera_motion = false
    check(fixture.save_preferences(preference_path) == OK,"Camera preferences save atomically in separate fixture")
    fixture.camera_fov = 60
    fixture.camera_shake = 1
    fixture.camera_motion = true
    fixture._load_preferences(preference_path)
    check(fixture.camera_fov == 68 and fixture.camera_shake == .25 and not fixture.camera_motion,"Camera preferences survive reload")
    var legacy: FileAccess = FileAccess.open(preference_path,FileAccess.WRITE)
    legacy.store_string(JSON.stringify({"version":1,"difficulty":1,"deadzone":.18,"volume":.8}))
    legacy.close()
    fixture._load_preferences(preference_path)
    check(fixture.writable and fixture.camera_fov == 60 and fixture.camera_shake == 1 and fixture.camera_motion,"Old preference file gains defaults without losing compatibility")
    DirAccess.remove_absolute(preference_path)
    fixture.free()
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1280,720)
    var settings: Node = root.get_node("CombatSettings")
    var previous: Array = [settings.camera_fov,settings.camera_shake,settings.camera_motion]
    var flow: Node = root.get_node("GameFlow")
    flow.configure_teams(false,[],[])
    flow.start_arcade("training","henrique","naruto","training")
    await frames(20)
    var fighter: Node3D = current_scene.get_node("Player")
    var enemy: Node3D = current_scene.get_node("EnemyDummy")
    var coach: Node = current_scene.get_node("BattleBridge/TrainingCoach")
    var metrics: Node = current_scene.get_node("BattleMetrics")
    var menu: Node = current_scene.get_node("BattlePause")
    var controls: Node = current_scene.get_node("HUD/MobileControls")
    current_scene.get_node("CombatFeedback").hit_stop_enabled = false
    check(coach.panel.get_global_rect().end.y < 485,"Scrollable guide does not cover movement controls")
    check(enemy.training_behavior == 0 and enemy.is_physics_processing(),"Training dummy keeps physics and timers without AI")
    enemy.stagger_timer = .15
    enemy.invulnerable_timer = .15
    await frames(15)
    check(enemy.stagger_timer <= 0 and enemy.invulnerable_timer <= 0,"Training dummy recovers from contact timers")
    coach.set_dummy_mode(1)
    await frames(12) # Ordinary guard probe occurs after the perfect-guard window.
    check(enemy.guarding and not enemy.enable_arsenal,"Training mode can practice guard without enemy offense")
    metrics.reset()
    var actual_hp: float = enemy.health
    fighter.attack_hitbox.activate(fighter,4.0,0,0,.1,.1)
    fighter.attack_hitbox.try_hit(enemy)
    fighter.attack_hitbox.deactivate()
    check(is_equal_approx(metrics.damage,actual_hp-enemy.health) and metrics.guarded_hits == 1,"Metrics report actual hitbox damage after guard reduction")
    metrics.reset()
    fighter.on_attack_connected(enemy,2.5,0)
    check(metrics.damage == 2.5 and metrics.guarded_hits == 1 and metrics.hits == 0,"Confirmed guarded contact is classified separately")
    coach.set_dummy_mode(0)
    await frames(15) # Let the real guard-contact recovery finish before unguarded probes.
    fighter.on_attack_connected(enemy,10,0)
    fighter.on_attack_connected(enemy,5,0)
    check(metrics.hits == 2 and metrics.best_combo == 2 and metrics.damage == 17.5,"Confirmed contacts accumulate real damage and sequence")
    fighter.on_attack_connected(enemy,0,0)
    check(metrics.hits == 2,"No damage does not count as a hit")
    enemy.on_attack_connected(fighter,4,0)
    check(metrics.received == 4,"Incoming confirmed damage is recorded")
    metrics._physics_process(2.0)
    fighter.on_attack_connected(enemy,3,0)
    check(metrics.combo == 1 and metrics.best_combo == 2,"Idle gaps break current sequence but preserve best")
    controls.attack_queue = 2
    controls.guard_touch = 17
    controls.move_vector = Vector2.ONE
    menu.toggle()
    check(paused and menu.owns_pause and menu.overlay.visible,"Pause freezes battle and displays actions")
    check(controls.attack_queue == 0 and controls.guard_touch == -1 and controls.move_vector == Vector2.ZERO,"Pause releases touch input and queued attacks")
    var hp: float = enemy.health
    var time: float = metrics.elapsed
    await frames(6)
    check(metrics.elapsed == time and enemy.health == hp,"Combat clocks and HP stay frozen in pause")
    menu.resume()
    await frames(4)
    check(not paused and metrics.elapsed > time,"Resume restores combat clocks")
    fighter.locked_target = enemy
    enemy.global_position = fighter.global_position+Vector3(0,5,8)
    fighter.camera_rig._process(.3)
    check(fighter.camera_rig.pitch > fighter.camera_rig.lock_pitch,"Camera frames aerial opponent vertically")
    settings.camera_shake = 0
    settings.camera_motion = false
    fighter.camera_rig.add_combat_impact(.3,5)
    fighter.camera_rig._process(.3)
    check(fighter.camera_rig.spring_arm.position == Vector3.ZERO and is_zero_approx(fighter.camera_rig.fov_kick),"Reduced camera effects remove shake and impact zoom")
    coach.set_dummy_mode(2)
    check(enemy.training_behavior == -1 and enemy.enable_arsenal,"Training can enable full CPU decisions")
    coach.set_dummy_mode(0)
    metrics.reset()
    check(metrics.hits == 0 and metrics.damage == 0 and metrics.received == 0,"Training analysis can reset without touching progression")
    menu.toggle()
    flow.enter_selection()
    # The outgoing scene frees its pause owner even when navigation happens elsewhere.
    for index: int in range(20): await process_frame
    await frames(6)
    check(not paused and current_scene.scene_file_path == "res://selection.tscn","Scene navigation does not leave a paused menu")
    settings.camera_fov = previous[0]
    settings.camera_shake = previous[1]
    settings.camera_motion = previous[2]
    print("BATTLE POLISH CONTRACT: "+("PASS" if failures == 0 else "FAIL")+" (%d checks)" % checks)
    quit(0 if failures == 0 else 1)
