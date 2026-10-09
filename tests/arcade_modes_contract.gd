extends SceneTree
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int) -> void:
    var pending_flow: Node = root.get_node("GameFlow")
    while pending_flow.busy:
        await process_frame
    for index: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    var flow: Node = root.get_node("GameFlow")
    var initial: int = root.get_child_count()
    check(flow.start_arcade("invalid", "henrique", "naruto", "training") == ERR_INVALID_PARAMETER, "Invalid modes rejected")
    check(flow.start_arcade("training", "henrique", "naruto", "training") == OK, "Training starts")
    await frames(8)
    var enemy: CharacterBody3D = current_scene.get_node("EnemyDummy")
    check(enemy.is_physics_processing() and enemy.training_behavior == 0 and not enemy.reactive_substitution, "Training dummy waits for practice")
    enemy.targetable = false
    enemy.health = 0.0
    await frames(2)
    check(enemy.targetable and enemy.health == enemy.max_health and not flow.battle_finished, "Training dummy resets after KO")
    flow.enter_selection()
    await frames(6)
    check(flow.arcade_mode.is_empty(), "Leaving series clears its state")
    check(flow.start_arcade("survival", "henrique", "naruto", "training") == OK, "Survival starts")
    await frames(8)
    current_scene.get_node("Player").health = 32.0
    check(flow.finish_battle(true), "Survival round finishes once")
    check(not flow.finish_battle(true) and flow.arcade_wins == 1, "Repeated completion cannot add wins")
    check(flow.arcade_next_available and is_equal_approx(flow.arcade_health, 32.0 + current_scene.get_node("Player").max_health*.20), "Survival preserves HP plus bounded recovery")
    check(flow.advance_arcade() == OK, "Next survival opponent starts")
    await frames(8)
    check(flow.arcade_round == 1 and flow.cpu_character.character_id != "naruto", "Series advances to another fighter")
    check(current_scene.get_node("Player").health <= flow.arcade_health, "Remaining HP carries into next round")
    flow.enter_selection()
    await frames(6)
    check(flow.start_arcade("tournament", "henrique", "naruto", "training") == OK, "Solo tournament starts")
    await frames(8)
    check(flow.arcade_opponents.size() == 3, "Solo tournament contains three elimination duels")
    for round_index: int in range(3):
        check(flow.finish_battle(true), "Tournament victory records")
        if round_index < 2:
            check(flow.advance_arcade() == OK, "Tournament advances")
            await frames(8)
    check(not flow.arcade_next_available and flow.arcade_wins == 3, "Final ends tournament without fourth duel")
    flow.enter_selection()
    await frames(6)
    check(flow.start_arcade("boss", "henrique", "naruto", "training") == OK, "Boss challenge starts")
    await frames(8)
    enemy = current_scene.get_node("EnemyDummy")
    check(enemy.max_health > flow.cpu_character.max_health and flow.arcade_opponents.size() == 3, "Boss challenge has three durable opponents")
    enemy.health = enemy.max_health * 0.3
    await frames(2)
    check(current_scene.get_node("BattleBridge").boss_phase_triggered, "Boss challenge enters second AI phase")
    flow.enter_selection()
    await frames(6)
    current_scene.queue_free()
    await frames(4)
    check(root.get_child_count() == initial, "Modes leave no scene objects behind")
    print("ARCADE MODES CONTRACT: " + ("PASS" if failures == 0 else "FAIL"))
    quit(0 if failures == 0 else 1)
