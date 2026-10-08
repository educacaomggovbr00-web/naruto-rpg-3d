extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(title)
func frames(count: int) -> void:
    while root.get_node("GameFlow").busy: await process_frame
    for i: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    var prefs: Node = preload("res://scripts/combat_settings.gd").new()
    var path: String = "user://integrated_polish_test.json"
    prefs.camera_sensitivity = 1.5
    prefs.touch_deadzone = .2
    prefs.music_volume = .35
    prefs.sfx_volume = .65
    check(prefs.save_preferences(path) == OK,"Integrated preferences save atomically")
    var reloaded: Node = preload("res://scripts/combat_settings.gd").new()
    reloaded._load_preferences(path)
    check(reloaded.camera_sensitivity == 1.5 and reloaded.touch_deadzone == .2 and reloaded.music_volume == .35 and reloaded.sfx_volume == .65,"Controls and mix survive reload")
    check(reloaded.touch_movement(Vector2(.1,0)) == Vector2.ZERO,"Touch deadzone eliminates drift")
    check(is_equal_approx(reloaded.touch_movement(Vector2(.21,0)).length(),.0125),"Analog movement grows continuously outside deadzone")
    check(is_equal_approx(reloaded.touch_movement(Vector2.ONE).length(),1.0),"Diagonal touch input remains normalized")
    DirAccess.remove_absolute(path)
    prefs.free()
    reloaded.free()
    root.size = Vector2i(1280,720)
    var flow: Node = root.get_node("GameFlow")
    var settings: Node = root.get_node("CombatSettings")
    var difficulty: int = settings.difficulty
    settings.difficulty = 2
    flow.start_arcade("training","henrique","naruto","training")
    await frames(24)
    var arena: Node = current_scene
    var hero: Node = arena.get_node("Player")
    var enemy: Node = arena.get_node("EnemyDummy")
    hero.set_physics_process(false)
    enemy.set_physics_process(false)
    hero.combat_state.clear_transient()
    hero.clear_jump_intent()
    hero.jump_requested = true
    hero.velocity.y = -1
    hero._update_jump_intent(.016,false)
    check(hero.jump_buffer > 0 and hero.velocity.y == -1,"Pre-landing jump remains buffered without an air jump")
    hero._update_jump_intent(.016,true)
    check(hero.velocity.y == hero.jump_velocity and hero.jump_buffer == 0,"Buffered jump executes at landing")
    hero.velocity.y = 0
    hero.clear_jump_intent()
    hero._update_jump_intent(.016,true)
    hero.jump_requested = true
    hero._update_jump_intent(.016,false)
    check(hero.velocity.y == hero.jump_velocity,"Coyote window tolerates walking off a ledge")
    hero.stagger_timer = .2
    hero.jump_requested = true
    hero.velocity.y = 0
    hero._update_jump_intent(.016,true)
    check(hero.jump_buffer == 0 and hero.velocity.y == 0,"Hitstun rejects jump commands")
    hero.stagger_timer = 0
    hero.attack_active = true
    hero.attack_confirmed = true
    hero.combo_step = 1
    hero.selected_attack = hero.moveset.attack(1,false,"neutral")
    var timing: Dictionary = hero.selected_attack.animation_timing(hero.rig_adapter.manifest)
    hero.attack_elapsed = float(timing.cancel_open)-.04
    hero.chakra = 100
    hero._start_chakra_dash()
    check(hero.dash_cancel_buffer > 0 and hero.chakra == 100,"Early confirmed dash cancel waits without spending chakra")
    hero.attack_elapsed = float(timing.cancel_open)+.001
    hero._start_chakra_dash(false)
    check(hero.chakra_dash_timer > 0 and hero.dash_cancel_buffer == 0 and hero.chakra == 100-hero.chakra_dash_cost,"Queued cancel respects manifest and spends once")
    hero.chakra_dash_timer = 0
    hero._cancel_attack()
    hero.combat_state.clear_transient()
    hero.attack_active = true
    hero.attack_confirmed = false
    hero.attack_elapsed = float(timing.cancel_open)-.04
    hero._start_chakra_dash()
    check(hero.dash_cancel_buffer == 0,"Whiff cannot queue a confirmed cancel")
    hero.animation_action_id += 1
    enemy.training_behavior = -1
    enemy.ai_profile.guard_bias = 1.0
    enemy.ai_profile.dodge_bias = 0.0
    enemy.ai_profile.reaction_delay = .1
    enemy.guard_meter = 100
    for seed_value: int in range(32):
        enemy.decision_rng.seed = seed_value
        if enemy.decision_rng.randf() < .6:
            enemy.decision_rng.seed = seed_value
            break
    enemy.guarding = false
    var hp: float = enemy.max_health
    check(not enemy._react_to_melee(.016,1.0) and not enemy.guarding,"CPU observes visible attack before reacting")
    check(not enemy._react_to_melee(.05,1.0),"CPU waits its configured reaction delay")
    check(enemy._react_to_melee(.06,1.0) and enemy.guarding,"CPU can guard a delayed melee threat")
    check(enemy.max_health == hp and enemy.pressure_memory <= 3.0,"CPU adaptation stays bounded and never buffs health")
    enemy.guarding = false
    hero.animation_action_id += 1
    settings.difficulty = 0
    check(not enemy._react_to_melee(.5,1.0),"Training difficulty has no reactive melee defense")
    hero._cancel_attack()
    var metrics: Node = arena.get_node("BattleMetrics")
    metrics.reset()
    enemy.guarding = true
    enemy.guard_meter = 1
    enemy.invulnerable_timer = 0
    hero.attack_hitbox.activate(hero,4,0,0,.1,.1)
    hero.attack_hitbox.try_hit(enemy)
    hero.attack_hitbox.deactivate()
    check(not enemy.guarding and metrics.guarded_hits == 1 and metrics.hits == 0,"Guard-breaking contact retains its original blocked classification")
    var feedback: Node = arena.get_node("CombatFeedback")
    feedback.spawn_elemental_impact(Vector3(0,1,0),"lightning")
    check(feedback.elemental_impacts.size() == 6,"Elemental audio preserves bounded VFX pool")
    if DisplayServer.get_name() != "headless": # Dummy renderer does not retain MultiMesh transforms.
        var impact: Node = feedback.elemental_impacts[0]
        impact.activate(Vector3(0,1,0),"fire",1.0,Vector3.BACK)
        impact.update_visual(impact.duration*.5)
        var ember_height: float = impact.sparks.multimesh.get_instance_transform(0).origin.y
        impact.activate(Vector3(0,1,0),"earth",1.0,Vector3.BACK)
        impact.update_visual(impact.duration*.5)
        check(ember_height > impact.sparks.multimesh.get_instance_transform(0).origin.y,"Fire embers rise while earth debris falls")
        impact.activate(Vector3(0,1,0),"wind",1.0,Vector3.RIGHT)
        impact.update_visual(impact.duration*.5)
        check(impact.sparks.multimesh.get_instance_transform(0).origin.x > .4,"Wind contact fragments follow attack heading")
    check(load("res://scripts/audio_manager.gd").element_sound("black_fire") == "jutsu_fire" and load("res://scripts/audio_manager.gd").element_sound("lightning") == "jutsu_lightning","Elemental contacts choose matching sound")
    var audio: Node = arena.get_node("AudioManager")
    check(audio.voices.size() == 8 and audio.voices[0] is AudioStreamPlayer3D,"Spatial SFX retain eight preallocated voices")
    var hud: Node = arena.get_node("HUD")
    check(hud.health_bar.has_node("DamageTail") and hud.enemy_health_bar.has_node("DamageTail"),"Both fighters show recently lost health")
    enemy.combat_state.force_state("guard_break",.55)
    hud._update_combat_events(.016)
    check(hud.event_label.text == "GUARDA ROMPIDA","Guard break has readable event feedback")
    var menu: Node = arena.get_node("BattlePause")
    hero.jump_buffer = .1
    hero.dash_cancel_buffer = .1
    menu.toggle()
    var lifetime: float = feedback.lifetimes[0]
    feedback._process(.2)
    check(feedback.lifetimes[0] == lifetime,"Pause freezes always-process feedback lifetimes")
    check(hero.jump_buffer == 0 and hero.dash_cancel_buffer == 0,"Pause clears pending movement commands")
    check(menu.panel.size.y < 700,"Expanded pause settings fit landscape Android")
    menu.resume()
    var dialogue: CanvasLayer = load("res://scripts/world/story_dialogue.gd").new()
    root.add_child(dialogue)
    dialogue.play([{"speaker":"Henrique Uchiha","text":"Minha jornada continua."},{"speaker":"Naruto","text":"Vamos treinar!"}])
    dialogue._process(.1)
    check(dialogue.body_label.visible_characters > 0 and dialogue.body_label.visible_characters < dialogue.body_label.get_total_character_count(),"Dialogue gradually reveals text")
    dialogue.advance()
    check(dialogue.index == 0 and dialogue.body_label.visible_characters == -1,"First continue reveals text without skipping the line")
    dialogue.advance()
    check(dialogue.index == 1,"Second continue advances dialogue")
    dialogue.close()
    dialogue.queue_free()
    hero.set_physics_process(true)
    enemy.training_behavior = 0
    enemy.set_physics_process(true)
    settings.difficulty = difficulty
    flow.enter_selection()
    await frames(8)
    check(not paused,"Story and battle transitions release pause ownership")
    print("INTEGRATED POLISH CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL",checks])
    quit(0 if failures == 0 else 1)
