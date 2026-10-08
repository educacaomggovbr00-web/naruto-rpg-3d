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
    var persistent_nodes: int = root.get_child_count()
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)
    var flow: Node = root.get_node("GameFlow")
    check(flow.enter_selection() == OK, "Selection scene transition must succeed")
    await frames(8)
    var menu: Control = current_scene
    check(menu.scene_file_path == "res://selection.tscn", "Game must expose a real selection scene")
    check(menu.player_pick.item_count == 26 and not menu.player_pick.is_item_disabled(12), "All 25 original Storm 1 playable fighters must be selectable; Gaara is slot 13")
    check(menu.start_button.get_global_rect().end.y <= 720.0, "Start button must fit landscape viewport")
    check(flow.start_versus("not_in_storm1", "naruto", "training") == ERR_INVALID_PARAMETER, "Unknown character cannot enter battle")
    check(flow.start_versus("naruto", "naruto", "unknown") == ERR_INVALID_PARAMETER, "Unavailable arena cannot enter battle")
    menu.player_pick.select(1)
    menu.cpu_pick.select(0)
    menu.arena_pick.select(1)
    menu._start()
    await frames(8)
    var arena: Node3D = current_scene
    var fighter: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    cpu.enable_arsenal = false
    cpu.reactive_substitution = false
    arena.get_node("CombatFeedback").hit_stop_enabled = false
    check(flow.versus_mode and flow.arena_id == "courtyard", "Arena and versus context must survive scene change")
    check(fighter.character_definition.character_id == "sasuke" and cpu.character_definition.character_id == "naruto", "Selected profiles must reach both controllers")
    check(fighter.moveset != cpu.moveset and fighter.move_speed == 8.0, "Selection must change actual moveset and movement stats")
    check(fighter.moveset.attack(3, false).animation_name == "air_attack_2", "Sasuke kick must consume the real selected clip")
    check(fighter.rig_adapter.real_animation_count == 127 and cpu.rig_adapter.real_animation_count == 127, "Both profiles retain all baked clips")
    check(fighter.rig_adapter.animation_player.get_animation_library(&"combat") != cpu.rig_adapter.animation_player.get_animation_library(&"combat"), "Different Naruto/Sasuke rest rigs must keep independently prepared clip libraries")
    check(fighter.rig_adapter.animation_tree != cpu.rig_adapter.animation_tree, "Playback state must remain independent")
    var controls: Control = arena.get_node("HUD/MobileControls")
    check(controls.ultimate_enabled and controls.awakening_enabled and not controls.clones_enabled and controls.special_label == "FIRE", "Touchscreen must reflect selected fighter capabilities")
    check(fighter.specials.clones.is_empty() and cpu.specials.clones.is_empty(), "Sasuke and idle CPU must not allocate Naruto clone rigs")
    check(fighter.ultimate.definition != null and fighter.ultimate.definition.ultimate_id == "sasuke_ultimate", "Sasuke receives own generic Ultimate definition")
    check(fighter.awakening.definition != null and fighter.awakening.definition.awakening_id == "sasuke_awakening", "Sasuke receives own generic Awakening definition")
    check(not fighter.specials.start("demon"), "Cross-character jutsu must be rejected")
    fighter.chakra = 100.0
    fighter.jutsu_cooldown = 0.0
    check(fighter.specials.start("chidori") and fighter.chakra == 68.0, "Chidori must consume chakra")
    check(not fighter.specials.start("chidori"), "Jutsu cannot double-start")
    await frames(12)
    check(fighter.specials.rasengan_hitbox.remaining_time == 0.0, "Chidori cannot damage during startup")
    await frames(14)
    check(fighter.specials.chidori_visual.visible and not fighter.specials.sphere_visual.visible, "Chidori needs a distinct electrical effect")
    check(fighter.specials.rasengan_hitbox.global_position.distance_to(fighter.rig_adapter.get_hand_world_position()) < 0.2, "Chidori hit volume must track the hand")
    fighter.specials.cancel()
    check(not fighter.specials.chidori_visual.visible and fighter.specials.rasengan_hitbox.remaining_time == 0.0, "Cancellation closes Chidori effect/hitbox")
    var flame: Node3D = fighter.specials.projectiles[0]
    fighter.global_position = Vector3(0, 0.96, -4)
    cpu.global_position = Vector3(0, 0.96, 0)
    cpu.guarding = false
    cpu.invulnerable_timer = 0.0
    var previous: float = cpu.health
    flame.launch(fighter, cpu, Vector3(0, 0.96, -3), Vector3.BACK)
    await frames(18)
    check(cpu.health < previous and not flame.active, "Fireball must hit a real hurtbox through the swept volume")
    cpu._respawn()
    fighter._respawn()
    fighter.set_physics_process(false)
    cpu.stagger_timer = 0.0
    cpu.chakra = 100.0
    check(cpu._start_chakra_dash() and cpu.chakra == 82.0, "CPU dash follows the same resource cost")
    cpu._dash_motion(0.04)
    check(cpu.dash_speed == 0.0 and cpu.dash_hitbox.remaining_time == 0.0, "CPU dash respects short startup")
    cpu._dash_motion(0.04)
    check(cpu.dash_speed > 0.0 and cpu.dash_hitbox.remaining_time > 0.0, "CPU dash accelerates with a physical contact volume")
    cpu.on_hitbox_contact(cpu.dash_hitbox, fighter, 0.0, true)
    check(cpu.stagger_timer > 0.0 and not cpu.attack_active, "Blocked CPU dash recoils without starting combo")
    cpu._respawn()
    cpu.set_physics_process(false)
    check(cpu.specials.start("rasengan") and cpu.chakra == 68.0, "CPU runs the same Rasengan module/cost")
    check(cpu.specials.rasengan_hitbox.collision_mask == 8, "CPU jutsu volume must target player, not CPU")
    cpu.receive_combat_hit(1.0, Vector3.BACK, 0, 0, 0.3)
    check(cpu.specials.current.is_empty() and cpu.specials.rasengan_hitbox.remaining_time == 0.0, "Incoming hit interrupts CPU jutsu")
    cpu._respawn()
    cpu.set_physics_process(false)
    cpu.attack_cooldown = 0.0
    cpu.specials.warm_clone_pool()
    check(cpu.rig_adapter.animation_player.get_animation_library(&"combat") == cpu.specials.clones[0].animation_player.get_animation_library(&"combat"), "Matching Naruto clone rigs share immutable prepared clip data")
    check(cpu.specials.clones.size() == 3 and cpu.specials.clones[0].hitbox.collision_mask == 8, "CPU Naruto creates bounded pooled clones with correct team mask")
    cpu.global_position = Vector3(0, 0.96, -3.0)
    cpu.rotation.y = 0.0
    # Physics is disabled in this fixture; refresh floor contact after teleporting.
    cpu.velocity = Vector3.DOWN * 60.0
    cpu.move_and_slide()
    cpu.velocity = Vector3.ZERO
    fighter.global_position = Vector3(0, 0.96, 0)
    fighter.stagger_timer = 0.0
    check(cpu.ultimate.start() and cpu.chakra == 20.0, "CPU Ultimate must use the shared startup/resource gate")
    check(not cpu.ultimate.cinematic_started, "CPU Ultimate cannot trigger cinematic on input alone")
    fighter.invulnerable_timer = 0.0
    cpu.ultimate.on_hitbox_contact(cpu.ultimate.entry_box, fighter, 1.0, true)
    check(not cpu.ultimate.cinematic_started, "Blocked CPU Ultimate cannot confirm")
    await frames(30)
    check(fighter.cinematic_owner == cpu.ultimate and cpu.ultimate.phase == "clash", "Clean Ultimate entry locks player only after hit confirm")
    var cpu_attacker_presses: int = cpu.ultimate.presses
    var player_defense_presses: int = cpu.ultimate.cpu_presses
    fighter._try_attack()
    check(cpu.ultimate.cpu_presses == player_defense_presses + 1 and cpu.ultimate.presses == cpu_attacker_presses, "Player ATK defends against CPU Ultimate")
    cpu.ultimate.cpu_press_timer = 0.0
    cpu.ultimate._advance_cpu_clash(0.01)
    check(cpu.ultimate.presses > 0, "CPU attacker presses are independently timed")
    fighter.substitution_cooldown = 0.0
    fighter.substitutions = 4
    fighter._try_substitution()
    check(cpu.ultimate.phase.is_empty() and fighter.cinematic_owner == null and fighter.camera_rig.cinematic_remaining == 0.0, "Substitution restores control/camera during CPU Ultimate")
    cpu._respawn()
    cpu.health = cpu.max_health * 0.25
    cpu.velocity = Vector3.DOWN * 60.0
    cpu.move_and_slide()
    cpu.velocity = Vector3.ZERO
    cpu.chakra = cpu.max_chakra
    cpu.stagger_timer = 0.0
    check(cpu.awakening.start(), "CPU can enter Naruto Awakening with matching condition")
    cpu.awakening._physics_process(1.01)
    check(cpu.awakening.active and cpu.get_damage_multiplier() > 1.0, "CPU Awakening affects real damage stats")
    cpu._knock_out()
    check(not cpu.awakening.active and cpu.specials.current.is_empty(), "KO cleans CPU modes and abilities")
    var audio: Node = arena.get_node("AudioManager")
    check(audio.voices.size() == 8 and audio.BANK.size() == 11, "Audio must use a bounded preloaded pool")
    var node_count: int = audio.get_child_count()
    for index: int in range(100):
        audio.play("normal")
    check(audio.get_child_count() == node_count, "Repeated SFX must not allocate more voices")
    audio.stop_all()
    check(not audio.charge_voice.playing, "Result cleanup stops charging loop")
    Engine.time_scale = 0.1
    check(flow.finish_battle(true), "Versus KO must enter result flow")
    check(Engine.time_scale == 1.0 and arena.process_mode == Node.PROCESS_MODE_DISABLED, "Hit-stop cannot freeze the result overlay")
    check(not flow.finish_battle(true), "Result must be idempotent")
    check(flow.retry_battle() == OK, "Versus rematch must work without mission ID")
    await frames(8)
    check(current_scene.get_node("Player").character_definition.character_id == "sasuke" and flow.arena_id == "courtyard", "Rematch keeps selected profiles/arena")
    check(flow.enter_selection() == OK, "Result flow can return to selection")
    await frames(8)
    check(current_scene.scene_file_path == "res://selection.tscn", "Selection must return after cleanup")
    var returned_menu: Control = current_scene
    returned_menu.player_pick.select(2)
    returned_menu._describe(2)
    check(returned_menu.player_name.text.contains("SAKURA"), "Sakura must be presented as a first-class fighter")
    returned_menu._enter_world()
    await frames(8)
    var world_player: CharacterBody3D = get_first_node_in_group("world_player") as CharacterBody3D
    check(world_player != null and world_player.get_character_definition().character_id == "sakura", "Village must use the selected fighter")
    check(world_player.rig_adapter.model_yaw_degrees == 0.0 and is_equal_approx(world_player.rig_adapter.target_character_height, 1.66), "Sakura must use corrected facing and height")
    check(world_player.rig_adapter.native_locomotion_count >= 3, "Sakura must use native Idle/Walk/Run in exploration")
    check(flow.enter_selection() == OK, "Sakura exploration can return to selection")
    await frames(6)
    current_scene.queue_free()
    await frames(4)
    check(root.get_child_count() == persistent_nodes, "Selection/rematch must not leak pools or voice nodes")
    print("SELECTION ARSENAL CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
