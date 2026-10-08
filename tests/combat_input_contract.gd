extends SceneTree
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int) -> void:
    for i: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    var flow: Node = root.get_node("GameFlow")
    flow.player_character = CharacterCatalog.find("henrique")
    flow.cpu_character = CharacterCatalog.find("naruto")
    flow.versus_mode = true
    var battle: Node = load("res://main.tscn").instantiate()
    root.add_child(battle)
    await frames(30)
    var fighter: Node = battle.get_node("Player")
    var enemy: Node = battle.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    enemy.set_physics_process(false)
    enemy.global_position = Vector3(15, 1, 15)
    fighter._try_attack()
    check(fighter.attack_active and fighter.combo_step == 1, "First attack starts")
    fighter.attack_elapsed = 0.01
    fighter.mobile_controls.move_vector = Vector2.LEFT
    fighter._try_attack()
    check(fighter.attack_buffer > fighter.attack_duration - fighter.attack_elapsed, "Input during startup survives until next strike")
    fighter.mobile_controls.move_vector = Vector2.RIGHT
    fighter._update_attack_timeline(fighter.attack_duration)
    fighter.attack_cooldown = 0
    fighter._try_attack()
    check(fighter.combo_step == 2 and fighter.selected_attack.animation_name == "combat_cross_left", "Buffered direction is frozen at input time")
    check(fighter.moveset.ground[1].animation_name == "combat_cross_center", "Directional attacks never mutate the shared kit")
    fighter._open_attack_hitbox()
    check(fighter.selected_attack.animation_name == "combat_cross_left", "Hitbox timing retains the selected clip")
    fighter._try_attack()
    fighter._cancel_attack()
    check(fighter.attack_buffer == 0.0 and not fighter.has_buffered_variant, "Interruption clears queued attacks")
    fighter.attack_cooldown = 0
    fighter.combo_timer = 0
    fighter.mobile_controls.move_vector = Vector2.DOWN
    fighter._try_attack()
    check(fighter.selected_attack.animation_name == "combat_jab_low", "Low input selects a distinct baked clip")
    fighter._update_animation_state()
    await frames(2)
    check(fighter.rig_adapter.playback.get_current_node() == &"combat_jab_low", "Directional clip really plays")
    check(fighter.rig_adapter.animation_tree.tree_root.get_transition_count() < 2500, "Expanded gameplay graph remains bounded")
    fighter.defeated = true
    fighter._update_animation_state()
    await frames(1)
    check(fighter.rig_adapter.playback.get_current_node() == &"defeat", "KO interrupts a directional attack without an idle detour")
    fighter.defeated = false
    fighter._cancel_attack()
    fighter.jutsu_timer = 0
    fighter.jutsu_cooldown = 0
    fighter.chakra = 100
    check(fighter.specials.start("henrique_nagashi"), "Nagashi starts")
    fighter.specials._physics_process(fighter.specials.release_time() + 0.01)
    check(fighter.specials.chidori_visual.visible and not fighter.specials.style_visual.visible, "Nagashi uses radial electric forks instead of a solid sphere")
    fighter.specials.cancel()
    check(not fighter.specials.chidori_visual.visible, "Interrupted pulse cleans up")
    battle.queue_free()
    await frames(4)
    check(flow.start_arcade("training", "henrique", "naruto", "training") == OK, "Guided training starts through existing mode")
    await frames(30)
    var actor: Node = current_scene.get_node("Player")
    actor.set_physics_process(false)
    var coach: Node = current_scene.find_child("TrainingCoach", true, false)
    check(coach != null and coach.step == 0, "Guide is only created for training")
    var health: float = actor.health
    coach.prepare_awakening()
    check(actor.health == health, "Preparation cannot alter health before its training objective")
    actor.global_position += Vector3.RIGHT * 2
    coach._process(0.1)
    check(coach.step == 1, "Moving advances first objective")
    actor.combo_hits = 3
    coach._process(0.1)
    check(coach.step == 2, "Connected combo advances the combat objective")
    actor.is_guarding = true
    coach._process(0.6)
    actor.is_guarding = false
    actor.chakra_dash_timer = 0.2
    coach._process(0.1)
    actor.substitution_cooldown = 0.2
    coach._process(0.1)
    actor.specials.current = "henrique_katon"
    coach._process(0.1)
    check(coach.step == 6 and coach.prepare.visible, "Guide reaches the explicit awakening preparation")
    actor.specials.cancel()
    coach.prepare_awakening()
    check(actor.health <= actor.max_health * 0.5 and actor.chakra == actor.max_chakra, "Training preparation creates normal awakening conditions")
    current_scene.queue_free()
    current_scene = null
    flow._clear_pending_battle()
    await frames(4)
    print("COMBAT INPUT CONTRACT: ", "PASS" if failures == 0 else "FAIL")
    quit(0 if failures == 0 else 1)
