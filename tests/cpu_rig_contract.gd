extends SceneTree
var failures: int = 0
var checks: int = 0
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
    var arena: Node3D = load("res://main.tscn").instantiate()
    root.add_child(arena)
    await frames(8)
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    var fighter: CharacterBody3D = arena.get_node("Player")
    var rig: Node3D = cpu.rig_adapter
    cpu.set_physics_process(false)
    fighter.set_physics_process(false)
    arena.get_node("CombatFeedback").set_process(false)
    check(rig.rig_loaded and rig.real_animation_count == 27, "CPU needs the real shared 27-clip rig")
    check(not cpu.visual.visible, "Capsule must be hidden after rig loading")
    check(rig.animation_tree != fighter.rig_adapter.animation_tree, "Fighters need independent AnimationTree playback")
    check(cpu.attack_hitbox.collision_mask == 8, "CPU strike must target player hurtboxes")
    cpu._start_attack()
    check(cpu.attack_timing == rig.get_attack_timing(1, false), "CPU timing must come from the manifest")
    cpu._update_attack_timeline(0.10)
    check(not cpu.attack_hit_triggered, "No hitbox during startup")
    cpu._update_attack_timeline(0.03)
    check(cpu.attack_hit_triggered, "Hitbox opens at real clip startup")
    rig.snap_attack_hitbox(1, false)
    var hand: Vector3 = rig.get_hand_world_position("LeftHand")
    check(cpu.attack_hitbox.global_position.distance_to(hand) < 0.18, "Strike must follow the named hand bone")
    cpu.on_hitbox_contact(cpu.attack_hitbox, fighter, 2.0, true)
    cpu._update_attack_timeline(0.09)
    check(cpu.combo_step == 1, "Blocked entry cannot confirm CPU combo")
    cpu._update_attack_timeline(0.10)
    check(not cpu.attack_active, "Whiff/block needs normal recovery")
    cpu._start_attack()
    cpu.attack_hitbox.activate(cpu, 10.0, 0.0, 0.0, 0.3, 0.09)
    cpu.attack_hitbox.try_hit(fighter)
    cpu._update_attack_timeline(0.22)
    check(cpu.combo_step == 2 and cpu.attack_active, "Clean collision can continue within cancel window")
    cpu.receive_combat_hit(1.0, Vector3.FORWARD, 0.0, 0.0, 0.3)
    check(not cpu.attack_active and cpu.attack_hitbox.remaining_time == 0.0, "Incoming hit closes CPU attack")
    check(cpu.get_animation_state() == "hit", "CPU needs a real hit reaction")
    cpu._knock_out()
    check(cpu.get_animation_state() == "defeat", "KO must play defeat clip")
    cpu._respawn()
    check(cpu.targetable and not cpu.attack_active, "Respawn restores CPU safely")
    arena.queue_free()
    await frames(4)
    check(root.get_child_count() == 1, "CPU rig must clean up with arena")
    print("CPU RIG CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
