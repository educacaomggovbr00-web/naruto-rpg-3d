extends SceneTree
var failures := 0
var checks := 0
func _initialize():call_deferred("run")
func check(ok: bool, message: String):
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int):
    var pending_flow: Node = root.get_node("GameFlow")
    while pending_flow.busy:
        await process_frame
    for i in range(count):
        await physics_frame
        await process_frame
func run():
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1280,720)
    var settings = root.get_node("CombatSettings")
    var old_difficulty = settings.difficulty
    var source = AIProfileDefinition.new()
    var probabilities: Array[float] = []
    for level in range(4):
        settings.difficulty = level
        var profile = settings.profile_for(source)
        probabilities.append(profile.projectile_reaction)
        check(profile.substitution_chance >= 0 and profile.reaction_delay >= .1,"Reaction parameters remain bounded")
    check(probabilities[0] < probabilities[1] and probabilities[1] < probabilities[2] and probabilities[2] < probabilities[3],"Projectile reactions increase with difficulty")
    settings.difficulty = 2
    var flow = root.get_node("GameFlow")
    check(flow.start_versus("henrique","naruto","training") == OK,"Repaired battle loads")
    await frames(12)
    var fighter = current_scene.get_node("Player")
    var cpu = current_scene.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    for actor in [fighter,cpu]:
        check(actor.rig_adapter.resolved_model_path.begins_with("res://assets/characters/repaired/"),"Both combatants use corrected source-pose skins")
        check(actor.rig_adapter.real_animation_count == 127,"Combat library retained")
    fighter.is_guarding = true
    cpu.decision_rng.seed = 743
    var pressure = 0
    var hp = fighter.health
    for attempt in range(40):
        cpu.guarding = false
        cpu.guard_timer = 0
        cpu.dodge_timer = 0
        cpu.attack_active = false
        cpu._choose_close_action()
        if cpu.attack_active and cpu.combo_step == 4:
            pressure += 1
            check(cpu.attack_timing.startup > 0 and not cpu.attack_hit_triggered,"Heavy guard pressure respects startup")
    check(pressure > 0 and fighter.health == hp,"Higher difficulty pressures guard without instant damage")
    check(flow.enter_selection() == OK,"Selection loads")
    await frames(5)
    var menu = current_scene
    check(menu.difficulty_pick.item_count == 4,"Four difficulties selectable before fighting")
    var data = menu.preview.fighters[0].definition.find_jutsu(String(menu.technique_pick.get_item_metadata(0)))
    check(menu.description.text.contains("Chakra %d" % int(data.chakra_cost)),"Technique displays actual chakra cost")
    check(menu.start_button.get_global_rect().end.y <= 720 and menu.difficulty_pick.get_global_rect().end.x <= 1280,"New menu controls fit 720p")
    check(flow.enter_world() == OK,"Exploration loads")
    await frames(10)
    var village = current_scene
    var npc = village.get_node("ramen_host")
    village.actor.global_position = npc.global_position + Vector3(0,0,2)
    village.actor.set_physics_process(false)
    village.interact()
    check(village.story_dialogue.active and paused,"Talk NPC opens paused conversation")
    check(village.story_dialogue.lines.size() == 2 and village.story_dialogue.progress_label.text == "1 / 2","NPC dialogue includes mission context and progress")
    village.story_dialogue.close()
    check(not paused,"Conversation restores world controls")
    settings.difficulty = old_difficulty
    current_scene.queue_free()
    await frames(4)
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        await process_frame
    print("FIGHTER POLISH CONTRACT: ","PASS" if failures == 0 else "FAIL"," (",checks," checks)")
    quit(1 if failures else 0)
