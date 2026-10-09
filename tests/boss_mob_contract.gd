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
func frames(count: int = 4) -> void:
    var flow: Node = root.get_node("GameFlow")
    while flow.busy:
        await process_frame
    for index: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    var initial: int = root.get_child_count()
    var flow: Node = root.get_node("GameFlow")
    flow.save_path = "user://boss_mob_fixture.json"
    flow.team_enabled = false
    flow.battle_rules_enabled = true
    check(flow.start_arcade("boss", "henrique", "itachi", "ruins") == OK, "Boss challenge starts with expanded interactions")
    await frames(12)
    var fighter: CharacterBody3D = current_scene.get_node("Player")
    var boss: CharacterBody3D = current_scene.get_node("EnemyDummy")
    var bridge: Node = current_scene.get_node("BattleBridge")
    var encounter: Node = bridge.boss_encounter
    current_scene.get_node("CombatFeedback").hit_stop_enabled = false
    fighter.set_physics_process(false)
    boss.set_physics_process(false)
    check(encounter != null and encounter.prompts.size() == 3, "Boss has a real three-step QTE")
    boss.health = boss.max_health * .3
    fighter.invulnerable_timer = 0.0
    await frames(3)
    check(bridge.boss_phase_triggered and encounter.phase == "qte" and encounter.giant.visible, "Second phase activates giant technique and cinematic QTE")
    check(fighter.cinematic_owner == encounter and boss.cinematic_owner == encounter, "QTE locks both controllers without pausing the tree")
    encounter.set_physics_process(false)
    bridge.set_physics_process(false)
    var original_scale: float = Engine.time_scale
    encounter.press("ATK")
    encounter.press("DASH")
    encounter.press("SUB")
    check(encounter.last_result == "SUCCESS" and encounter.phase.is_empty(), "Correct sequence wins the QTE")
    check(fighter.cinematic_owner == null and boss.cinematic_owner == null and not paused and Engine.time_scale == original_scale, "Successful QTE releases locks without time-scale side effects")
    boss.stagger_timer = 0.0
    fighter.stagger_timer = 0.0
    check(encounter.start_qte(), "QTE can be safely started for another encounter")
    var before: float = fighter.health
    encounter.press("WRONG")
    encounter.press("WRONG")
    encounter.press("WRONG")
    check(encounter.last_result == "FAILED" and fighter.health < before, "Wrong commands have a bounded gameplay consequence")
    fighter.stagger_timer = 0.0
    boss.stagger_timer = 0.0
    check(encounter.start_qte(), "Timeout sequence starts")
    for index: int in range(3):
        encounter._physics_process(1.81)
    check(encounter.last_result == "FAILED" and encounter.phase.is_empty(), "Missing inputs time out and release the encounter")
    fighter.stagger_timer = 0.0
    boss.stagger_timer = 0.0
    check(encounter.start_qte(), "Cancellation sequence starts")
    encounter.cancel("back")
    check(fighter.cinematic_owner == null and boss.cinematic_owner == null and not encounter.panel.visible, "Cancellation removes QTE UI and fighter locks")
    fighter.invulnerable_timer = 0.0
    fighter.global_position = Vector3(0, 1, 0)
    encounter.hazard_timer = -3.1
    encounter._physics_process(.02)
    check(encounter.hazard.visible and encounter.hazard_timer > 1.0, "Giant boss attack warns before damage")
    before = fighter.health
    fighter.global_position.x = 6.0
    encounter._physics_process(1.2)
    check(fighter.health == before and not encounter.hazard.visible, "Moving out of the telegraph avoids damage")
    fighter.global_position.x = 0.0
    encounter.hazard_timer = -3.1
    encounter._physics_process(.02)
    encounter._physics_process(1.2)
    check(fighter.health < before, "Staying in the announced attack area receives damage")
    fighter.stagger_timer = 0.0
    fighter.global_position = Vector3(26.8, 1, 0)
    check(not encounter.start_wall_run(), "Wall traversal is not a universal free-battle action")
    flow.versus_mode = false
    flow.pending_battle = "story:hc_signal"
    flow.pending_story_id = "hc_signal"
    check(encounter.start_wall_run(), "Scripted story boss situation permits traversal near a wall")
    var origin: Vector3 = fighter.global_position
    encounter._physics_process(.6)
    check(fighter.global_position.y > origin.y + 1.5 and fighter.cinematic_owner == encounter, "Story traversal moves the real actor along a raised wall arc")
    encounter._physics_process(.7)
    check(encounter.phase.is_empty() and fighter.cinematic_owner == null and fighter.global_position.y == origin.y, "Wall traversal lands and releases the controller")
    flow.enter_selection()
    await frames(8)
    flow.configure_teams(true, ["sakura"], [])
    check(flow.start_arcade("mob", "henrique", "naruto", "forest") == OK, "New simultaneous squad battle mode is selectable")
    await frames(12)
    bridge = current_scene.get_node("BattleBridge")
    check(bridge.mob_enemies.size() == 3 and get_nodes_in_group("lock_targets").size() == 3, "Mob battle exposes three simultaneous independently targetable ninjas")
    for actor: CharacterBody3D in bridge.mob_enemies:
        actor.set_physics_process(false)
        check(actor.rig_adapter.real_animation_count == 127 and actor.health > 0.0, "Each mob enemy has a real independent rig and HP")
    bridge.mob_enemies[0].targetable = false
    bridge.mob_enemies[0].health = 0.0
    await frames(2)
    check(not flow.battle_finished, "Defeating one mob enemy cannot finish the mission")
    var player_team: Node = current_scene.get_node("Player").team
    check(player_team.can_act() and player_team._target().is_targetable(), "Team commands retarget living mobs after the original opponent falls")
    for actor: CharacterBody3D in bridge.mob_enemies:
        actor.targetable = false
        actor.health = 0.0
    await frames(2)
    check(flow.battle_finished and current_scene.process_mode == Node.PROCESS_MODE_DISABLED and flow.result_layer != null, "Defeating every enemy finishes once through the standard result screen")
    flow.enter_selection()
    await frames(8)
    check(not paused and Engine.time_scale == 1.0, "Leaving mob result restores normal game state")
    current_scene.queue_free()
    await frames(4)
    check(root.get_child_count() == initial, "Boss avatars, hazards and mobs do not leak outside the scene")
    print("BOSS MOB CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
