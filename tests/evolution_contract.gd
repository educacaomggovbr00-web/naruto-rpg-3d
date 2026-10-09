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
    var settings: Node = root.get_node("CombatSettings")
    var profile: AIProfileDefinition = RosterAIProfileFactory.build("naruto")
    var original: float = profile.decision_speed
    settings.difficulty = 0
    var easy: AIProfileDefinition = settings.profile_for(profile)
    settings.difficulty = 3
    var hard: AIProfileDefinition = settings.profile_for(profile)
    check(hard.decision_speed > easy.decision_speed and hard.guard_bias > easy.guard_bias and hard.jutsu_bias > easy.jutsu_bias, "Difficulty changes CPU decisions")
    check(is_equal_approx(profile.decision_speed, original), "Difficulty never mutates character's shared profile")
    settings.difficulty = 1
    check(InputMap.action_get_events("pad_attack")[0] is InputEventJoypadButton, "Controller attack uses joypad events")
    check(InputMap.action_get_events("pad_left")[0] is InputEventJoypadMotion, "Controller movement uses analog axes")
    Input.action_press("pad_right", 0.8)
    check(settings.movement().x > 0.5, "Analog movement passes through deadzone")
    Input.action_release("pad_right")
    var avatar: SusanooVisual = SusanooVisual.new()
    root.add_child(avatar)
    await frames(2)
    check(avatar.skeleton != null and avatar.skeleton.get_bone_count() == 25, "Susanoo imports a real 25-bone skeleton")
    check(avatar.animation_player != null and avatar.animation_player.has_animation("slash"), "Susanoo imports skeletal strike clip")
    var meshes: Array[Node] = avatar.imported_avatar.find_children("*", "MeshInstance3D", true, false)
    for mesh: Node in meshes:
        check(mesh.skin != null and not mesh.skeleton.is_empty(), "Every source surface is skinned")
    avatar.update_pose(0.016, true, 0.0)
    var arm: int = avatar.skeleton.find_bone("Susanoo_LeftArm")
    var neutral: Quaternion = avatar.skeleton.get_bone_pose_rotation(arm)
    avatar.update_pose(0.016, true, 0.55, Vector3.ZERO, 0.55)
    var impact: Quaternion = avatar.skeleton.get_bone_pose_rotation(arm)
    check(neutral.angle_to(impact) > 0.5, "Actual arm bone articulates at attack impact")
    avatar.update_pose(0.0, true, 0.55, Vector3.ZERO, 0.55)
    check(avatar.skeleton.get_bone_pose_rotation(arm).is_equal_approx(impact), "Hit-stop freezes skeleton")
    avatar.update_pose(0.016, true, 1.0)
    check(avatar.skeleton.get_bone_pose_rotation(arm).angle_to(neutral) < 0.01, "Skeletal recovery returns to bind pose")
    avatar.queue_free()
    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("henrique", "naruto", "training") == OK, "Existing battle starts")
    await frames(8)
    var fighter: CharacterBody3D = current_scene.get_node("Player")
    var enemy: CharacterBody3D = current_scene.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    enemy.set_physics_process(false)
    fighter.is_guarding = true
    fighter.timed_guard_window = 0.12
    var health: float = fighter.health
    check(is_zero_approx(fighter.receive_combat_hit(10.0, Vector3.FORWARD, 3.0, 0.0, 0.2)), "Timed guard parries normal attack")
    check(fighter.health == health and fighter.counter_window > 0.0, "Parry creates a counter opportunity")
    fighter.is_guarding = false
    fighter.attack_cooldown = 0.0
    fighter._try_attack()
    check(fighter.attack_counter_bonus > 1.0, "Counter increases next attack damage")
    check(is_zero_approx(fighter.counter_window), "Counter bonus consumed once")
    fighter._cancel_attack()
    fighter.attack_cooldown = 0.0
    fighter.invulnerable_timer = 0.0
    fighter.velocity = Vector3.DOWN * 40
    for index: int in range(10):
        fighter.move_and_slide()
        await frames(1)
    enemy.global_position = fighter.global_position + Vector3(0, 0, 1.3)
    enemy.invulnerable_timer = 0.0
    enemy.reactive_substitution = false
    fighter.locked_target = enemy
    fighter._try_grab()
    check(fighter.grab_attack, "Close grounded grab starts")
    enemy.is_guarding = true
    var before: float = enemy.health
    fighter._update_attack_timeline(fighter.attack_startup + 0.01)
    check(enemy.health < before and not enemy.is_guarding, "Throw defeats guard at impact")
    fighter._cancel_attack()
    fighter.attack_cooldown = 0.0
    fighter.grab_cooldown = 0.0
    enemy.global_position = fighter.global_position + Vector3(0, 0, 1.3)
    fighter._try_grab()
    before = enemy.health
    enemy.global_position += Vector3(0, 0, 4)
    fighter._update_attack_timeline(fighter.attack_startup + 0.01)
    check(enemy.health == before, "Escaping grab startup avoids throw")
    var controls: Control = current_scene.get_node("HUD/MobileControls")
    var original_layout: Dictionary = settings.touch_layout.duplicate(true)
    var original_writable: bool = settings.writable
    settings.writable = false
    var center: Vector2 = controls.attack_center
    controls.set_layout_editing(true)
    check(paused and controls.layout_editing, "Control editing pauses battle")
    controls._touch_pressed(45, center)
    controls._touch_dragged(45, center - Vector2(100, 40))
    check(controls.attack_center.distance_to(center) > 90.0 and controls.attack_queue == 0, "Dragging button edits layout without attacking")
    controls._touch_released(45)
    controls.set_layout_editing(false)
    check(not paused and settings.touch_layout.has("attack"), "Saving layout resumes fight and stores normalized position")
    settings.touch_layout = original_layout
    settings.writable = original_writable
    current_scene.queue_free()
    await frames(4)
    if failures == 0:
        print("SHINOBI EVOLUTION CONTRACT: PASS")
    quit(0 if failures == 0 else 1)
