extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for _index: int in range(count):
        await physics_frame

func run() -> void:
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)
    var flow: Node = root.get_node("GameFlow")
    var preferences: Node = root.get_node("GamePreferences")
    # Keep this contract isolated from a user's real save/config.
    flow.save_path = "user://improvements_test_save.json"
    preferences.config_path = "user://improvements_test_controls.cfg"
    preferences.difficulty = 1
    preferences.controls_scale = 1.0
    preferences.training_behavior = 0
    var base: AIProfileDefinition = RosterAIProfileFactory.build("naruto")
    var base_speed: float = base.decision_speed
    preferences.difficulty = 0
    var easy: AIProfileDefinition = preferences.cpu_profile(base)
    preferences.difficulty = 2
    var hard: AIProfileDefinition = preferences.cpu_profile(base)
    check(hard.decision_speed > easy.decision_speed and hard.jutsu_bias > easy.jutsu_bias, "Difficulty must change actual decisions")
    check(base.decision_speed == base_speed and hard != base, "Difficulty must not mutate shared character Resources")
    preferences.camera_sensitivity = 1.5
    preferences.camera_shake = false
    check(preferences.save_preferences() == OK, "Control preferences must persist independently")
    preferences.camera_sensitivity = 1.0
    preferences.load_preferences()
    check(preferences.camera_sensitivity == 1.5 and not preferences.camera_shake, "Sensitivity and shake must survive reload")
    check(InputMap.has_action("pad_attack") and InputMap.has_action("pad_camera_right"), "Gamepad must expose movement, camera and abilities")
    preferences.difficulty = 1
    check(flow.start_versus("henrique", "naruto", "training", "unknown") == ERR_INVALID_PARAMETER, "Invalid mode must not change scene")
    check(flow.start_versus("henrique", "naruto", "training", "training") == OK, "Training must enter the existing combat arena")
    await frames(12)
    var arena: Node3D = current_scene
    var fighter: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    var bridge: Node = arena.get_node("BattleBridge")
    check(flow.versus_mode and flow.battle_mode == "training", "Training must stay outside campaign inventory/rewards")
    check(not cpu.attack_active and not cpu.reactive_substitution, "Passive training dummy must not attack or substitute")
    fighter.chakra = 0.0
    await frames(2)
    check(fighter.chakra == fighter.max_chakra, "Training must refill chakra")
    var ryo_before: int = int(flow.progress.ryo)
    cpu._knock_out()
    await frames(2)
    check(cpu.targetable and cpu.health == cpu.max_health and not flow.battle_finished, "Training KO must reset instead of opening victory")
    check(int(flow.progress.ryo) == ryo_before, "Training must not grant repeatable campaign rewards")

    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    bridge.set_physics_process(false)
    arena.get_node("CombatFeedback").hit_stop_enabled = false
    fighter._respawn()
    fighter.invulnerable_timer = 0.0
    fighter.rotation = Vector3.ZERO
    fighter.global_position = Vector3(0, 0.96, -2.0)
    cpu.global_position = Vector3(0, 0.96, 0)
    cpu.invulnerable_timer = 0.0
    cpu.reactive_substitution = false
    cpu.guarding = false
    fighter.attack_cooldown = 0.0
    var pad_attack: InputEventJoypadButton = InputEventJoypadButton.new()
    pad_attack.button_index = JOY_BUTTON_X
    pad_attack.pressed = true
    Input.parse_input_event(pad_attack)
    Input.flush_buffered_events()
    await frames(2)
    check(fighter.attack_active, "A real gamepad attack event must reach the fighter")
    var pad_attack_release: InputEventJoypadButton = pad_attack.duplicate() as InputEventJoypadButton
    pad_attack_release.pressed = false
    Input.parse_input_event(pad_attack_release)
    Input.flush_buffered_events()
    fighter._cancel_attack()
    fighter.attack_cooldown = 0.0
    var pad_guard: InputEventJoypadButton = InputEventJoypadButton.new()
    pad_guard.button_index = JOY_BUTTON_LEFT_SHOULDER
    pad_guard.pressed = true
    Input.parse_input_event(pad_guard)
    Input.flush_buffered_events()
    fighter._refresh_hold_states()
    check(fighter.is_guarding, "Held gamepad defense must reach the same guard rules")
    var pad_guard_release: InputEventJoypadButton = pad_guard.duplicate() as InputEventJoypadButton
    pad_guard_release.pressed = false
    Input.parse_input_event(pad_guard_release)
    Input.flush_buffered_events()
    fighter._refresh_hold_states()
    check(not fighter.is_guarding, "Releasing gamepad defense must release guard")
    var box: Area3D = fighter.attack_hitbox
    box.set_physics_process(false)
    box.global_position = cpu.global_position
    await frames(2)
    var previous_health: float = cpu.health
    box.activate(fighter, 5.0, 0.0, 0.0, 0.1, 0.005)
    box._physics_process(1.0 / 60.0)
    check(cpu.health < previous_health and box.remaining_time == 0.0, "Even a window shorter than one frame must check current collisions")
    var health_after: float = cpu.health
    box._physics_process(1.0 / 60.0)
    check(cpu.health == health_after, "Expired hitbox must not hit twice")

    cpu.health = cpu.max_health
    cpu.stagger_timer = 0.0
    box.global_position = cpu.global_position + Vector3.LEFT * 1.6
    box.activate(fighter, 5.0, 0.0, 0.0, 0.1, 0.2)
    box._physics_process(0.01)
    check(cpu.health == cpu.max_health, "A missed initial pose must not deal proximity damage")
    box.global_position = cpu.global_position + Vector3.RIGHT * 1.6
    box._physics_process(0.01)
    check(cpu.health < cpu.max_health, "Moving strike must sweep the real hurtbox between poses")
    health_after = cpu.health
    box._physics_process(0.01)
    check(cpu.health == health_after, "Swept samples must deduplicate victims")
    box.deactivate()

    var wall: StaticBody3D = StaticBody3D.new()
    wall.collision_layer = 1
    var obstacle: CollisionShape3D = CollisionShape3D.new()
    var obstacle_shape: BoxShape3D = BoxShape3D.new()
    obstacle_shape.size = Vector3(3, 3, 0.2)
    obstacle.shape = obstacle_shape
    wall.add_child(obstacle)
    arena.add_child(wall)
    wall.global_position = Vector3(0, 1, -1)
    await frames(2)
    health_after = cpu.health
    box.activate(fighter, 5.0, 0.0, 0.0, 0.1, 0.2)
    box.try_hit(cpu)
    check(cpu.health == health_after, "Melee must not pass through a physical wall")
    wall.queue_free()
    await frames(2)
    box.deactivate()

    cpu.guarding = true
    cpu.techniques.guard_age = 0.05
    cpu.techniques.counter_cooldown = 0.0
    cpu.techniques.set_physics_process(false)
    health_after = cpu.health
    box.activate(fighter, 5.0, 0.0, 0.0, 0.1, 0.2)
    box.try_hit(cpu)
    check(cpu.health == health_after and fighter.stagger_timer >= 0.30, "Timed guard must negate the hit and open a counter opportunity")
    check(cpu.techniques.counter_cooldown > 0.0, "Perfect guard cannot repeat every frame")
    box.deactivate()
    cpu.techniques.guard_age = 1.0
    cpu.stagger_timer = 0.0
    cpu.combat_state.clear_transient()
    fighter.stagger_timer = 0.0
    fighter.combat_state.clear_transient()
    fighter.global_position = Vector3(0, 0.96, -1.1)
    fighter.velocity = Vector3.DOWN * 60.0
    fighter.move_and_slide()
    fighter.velocity = Vector3.ZERO
    fighter.invulnerable_timer = 0.0
    fighter.techniques.set_physics_process(false)
    check(fighter.techniques.start_grab(), "Grab must start from a grounded neutral state")
    fighter.techniques._physics_process(0.20)
    fighter.techniques.grab_box.try_hit(cpu)
    check(cpu.health < health_after and not cpu.guarding, "Grab must pierce defense after startup")
    fighter._cancel_jutsu()
    check(not fighter.techniques.active and fighter.techniques.grab_box.remaining_time == 0.0, "Interruption must release grab volume")

    fighter.stagger_timer = 0.0
    fighter.combat_state.clear_transient()
    fighter.chakra_dash_timer = 0.3
    fighter.attack_buffer = 0.2
    fighter.dash_hitbox.activate(fighter, 0.0, 0.0, 0.0, 0.1, 0.3)
    fighter.receive_combat_hit(1.0, Vector3.BACK, 0.0, 0.0, 0.2)
    check(fighter.chakra_dash_timer == 0.0 and fighter.dash_hitbox.remaining_time == 0.0 and fighter.attack_buffer == 0.0, "An incoming hit must cancel dash contact and queued retaliation")

    fighter.stagger_timer = 0.0
    fighter.combat_state.clear_transient()
    fighter.attack_cooldown = 0.0
    fighter.jump_requested = true
    fighter._physics_process(1.0 / 60.0)
    check(fighter.velocity.y > 0.0 and fighter.jump_buffer == 0.0, "Grounded jump must consume the movement buffer")
    fighter.jump_requested = true
    fighter._physics_process(1.0 / 60.0)
    check(fighter.jump_buffer > 0.0, "Jump pressed shortly before landing must remain buffered")

    var controls: Control = arena.get_node("HUD/MobileControls")
    check(controls.advanced_toggle_center.y - controls.top_radius >= 58.0 and controls.advanced_toggle_center.y + controls.top_radius <= 128.0, "Top touch controls must fit between pause and enemy vitals")
    check(controls.grab_center.y - controls.advanced_radius > 221.0, "Expanded abilities must stay below enemy vitals")
    for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(960, 540), Vector2(1600, 720)]:
        controls.size = viewport_size
        preferences.controls_scale = 1.15
        controls._update_layout()
        check(controls.attack_center.x + controls.attack_radius <= viewport_size.x and controls.guard_center.x - controls.guard_radius > controls.joystick_center.x + controls.joystick_radius, "Scaled touch banks must fit and remain separate")
    controls._touch_pressed(10, controls.guard_center)
    controls._touch_pressed(11, controls.charge_center)
    controls.grab_queue = 1
    controls._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(not controls.is_guard_held() and not controls.is_charge_held() and controls.grab_queue == 0, "Focus loss must release holds and pending actions")
    var pause: CanvasLayer = bridge.get_node("BattlePause")
    pause.pause_battle()
    check(paused and pause.overlay != null, "Pause must freeze the actual simulation")
    pause.resume_battle()
    check(not paused and pause.overlay == null, "Resume must restore the simulation")

    # Regression: CPU Henrique has attack_timing, not the player's attack_duration.
    check(flow.start_versus("naruto", "henrique", "courtyard", "survival") == OK, "Survival must start with chosen fighters")
    await frames(12)
    arena = current_scene
    fighter = arena.get_node("Player")
    cpu = arena.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    arena.get_node("BattleBridge").set_physics_process(false)
    cpu.awakening.active = true
    cpu.awakening.remaining = 2.0
    cpu.attack_active = true
    cpu.awakening._physics_process(0.01)
    check(cpu.awakening.avatar.visible, "CPU Susanoo must animate without reading missing player properties")
    cpu.attack_active = false
    cpu.awakening.stop()
    fighter.health = fighter.max_health * 0.5
    check(flow.finish_battle(true), "Survival win must open a wave result")
    check(not flow.finish_battle(true), "Repeated result must not duplicate a victory")
    check(flow.survival_health_ratio > 0.69 and flow.survival_health_ratio < 0.71, "Next wave must preserve remaining life plus bounded healing")
    check(flow.advance_survival() == OK, "Wave result must advance to next opponent")
    await frames(12)
    fighter = current_scene.get_node("Player")
    check(flow.survival_wave == 2 and fighter.health <= fighter.max_health * 0.71, "Next wave must not reset to full health")
    check(int(flow.progress.get("survival_best", 0)) >= 1, "Survival best must be saved")
    flow.finish_battle(false)
    check(flow.advance_survival() == ERR_UNAVAILABLE, "Loss must end the sequence")
    check(flow.retry_battle() == OK and flow.survival_wave == 1 and flow.survival_health_ratio == 1.0, "Retry must restart survival from wave one")
    await frames(8)
    flow.enter_selection()
    await frames(8)
    var menu: Control = current_scene
    check(menu.mode_pick.item_count == 3 and menu.difficulty_pick.item_count == 3, "Modes and difficulty must be selectable in the real menu")
    check(menu.start_button.get_global_rect().end.y <= 720, "Selection actions must remain in landscape bounds")
    if "--capture" in OS.get_cmdline_user_args():
        var capture_dir: String = "user://improvements-captures"
        for argument: String in OS.get_cmdline_user_args():
            if argument.begins_with("--capture-dir="):
                capture_dir = argument.trim_prefix("--capture-dir=")
        DirAccess.make_dir_recursive_absolute(capture_dir)
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(capture_dir.path_join("selection.png"))
        menu._show_preferences()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(capture_dir.path_join("preferences.png"))
    preferences.controls_scale = 1.0
    preferences.camera_sensitivity = 1.0
    preferences.camera_shake = true
    DirAccess.remove_absolute(flow.save_path)
    DirAccess.remove_absolute(preferences.config_path)
    current_scene.queue_free()
    await frames(4)
    check(root.get_child_count() == 2 and root.has_node("GameFlow") and root.has_node("GamePreferences"), "Repeated modes must release all scene-owned nodes")
    print("GAMEPLAY IMPROVEMENTS: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
    quit(1 if failures > 0 else 0)
