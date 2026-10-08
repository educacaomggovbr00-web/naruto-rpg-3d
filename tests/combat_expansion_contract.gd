extends SceneTree
## Gallery, repeated one-shots, independent actors and Susanoo timing.
var failures: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for index: int in range(count):
        await physics_frame
        await process_frame

func run() -> void:
    var selection: Control = load("res://selection.tscn").instantiate()
    root.add_child(selection)
    await frames(4)
    var gallery: HBoxContainer = selection.animation_gallery
    var preview: SubViewportContainer = selection.preview
    var hero: CharacterBody3D = preview.fighters[0]
    var rival: CharacterBody3D = preview.fighters[1]
    check(gallery.family.item_count == 10 and gallery.variant.item_count == 10, "Gallery exposes all 100 clips")
    for family: int in range(10):
        for variant: int in range(10):
            gallery.family.select(family)
            gallery.variant.select(variant)
            gallery._selected(variant)
            await frames(1)
            var clip: String = gallery.selected_clip()
            check(hero.rig_adapter.playback.get_current_node() == StringName(clip), "Gallery really plays " + clip)
            check(rival.rig_adapter.playback.get_current_node() == &"idle", "Opponent playback stays independent")
    gallery.family.select(0)
    gallery.variant.select(0)
    gallery._selected(0)
    await frames(5)
    var before: float = hero.rig_adapter.playback.get_current_play_position()
    gallery._selected(0)
    await frames(1)
    check(hero.rig_adapter.playback.get_current_play_position() < before, "Repeated one-shot restarts at zero")
    preview.preview_animation("idle")
    await frames(1)
    check(hero.rig_adapter.playback.get_current_node() == &"idle", "Neutral button clears gallery pose")
    check(hero.rig_adapter.animation_tree.tree_root.get_transition_count() < 2500, "Mobile graph avoids quadratic gallery transitions")

    var avatar: SusanooVisual = SusanooVisual.new()
    root.add_child(avatar)
    check(is_zero_approx(SusanooVisual.strike_angle(0.0)), "Strike starts in neutral")
    check(SusanooVisual.strike_angle(0.24) < -0.5, "Sword anticipates before impact")
    check(is_equal_approx(SusanooVisual.strike_angle(0.4, 0.4), 1.4), "Sword reaches strike at the manifest impact")
    check(is_zero_approx(SusanooVisual.strike_angle(1.0)), "Recovery finishes in neutral")
    avatar.update_pose(1.0 / 60.0, true, 0.4, Vector3(5, 0, 8), 0.4)
    check(is_equal_approx(avatar.sword_arm.rotation.y, 1.4), "Actual blade transform matches impact")
    var frozen: Transform3D = avatar.shell.transform
    avatar.update_pose(0.0, true, 0.4, Vector3(5, 0, 8), 0.4)
    check(avatar.shell.transform.is_equal_approx(frozen), "Zero delta preserves pose during hit-stop")
    avatar.reset_pose()
    check(avatar.shell.transform == Transform3D.IDENTITY and avatar.sword_arm.rotation == Vector3.ZERO, "Reset clears combat pose")
    avatar.update_pose(1.0 / 60.0, false, 0.0, Vector3.ZERO, 0.4, 0.0)
    check(avatar.shell.scale.x < 0.2, "Summon begins small")
    avatar.update_pose(1.0 / 60.0, false, 0.0, Vector3.ZERO, 0.4, 1.0)
    check(avatar.shell.scale.x > 0.95, "Summon reaches full size")
    if "--capture" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://docs/captures/selection_combat100.png") == OK, "Gallery capture saves")
    avatar.queue_free()
    selection.queue_free()
    await frames(2)
    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("henrique", "naruto", "training") == OK, "Expanded kit starts a real battle")
    await frames(6)
    var fighter: CharacterBody3D = current_scene.get_node("Player")
    var opponent: CharacterBody3D = current_scene.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    opponent.set_physics_process(false)
    opponent.enable_arsenal = false
    fighter.velocity = Vector3.DOWN * 30.0
    fighter.move_and_slide()
    fighter.velocity = Vector3.ZERO
    for step: int in range(1, 5):
        fighter.attack_active = false
        fighter.attack_cooldown = 0.0
        fighter.combo_timer = 1.0 if step > 1 else 0.0
        fighter.combo_step = step - 1
        fighter._try_attack()
        var attack: AttackDefinition = fighter.selected_attack
        var timing: Dictionary = attack.animation_timing(fighter.rig_adapter.manifest)
        check(attack.animation_name.begins_with("combat_"), "New clip is used by actual ground combo")
        check(is_equal_approx(fighter.attack_startup, float(timing["impact"])), "Real hit startup follows new clip")
        fighter._update_attack_timeline(fighter.attack_startup - 0.001)
        check(not fighter.attack_hit_triggered, "No early damage before animation impact")
        fighter._update_attack_timeline(0.002)
        check(fighter.attack_hit_triggered and fighter.attack_hitbox.remaining_time > 0.0, "Impact opens existing hitbox")
        fighter._update_attack_timeline(fighter.attack_duration)
        check(not fighter.attack_active and fighter.attack_hitbox.remaining_time <= 0.0, "Recovery clears the hitbox")
    if "--capture" in OS.get_cmdline_user_args():
        fighter.health = fighter.max_health * 0.45
        fighter.chakra = fighter.max_chakra
        fighter.attack_cooldown = 0.0
        fighter.jutsu_timer = 0.0
        check(fighter.awakening.start(), "Capture summons real Susanoo")
        fighter.awakening._physics_process(1.0)
        await frames(6)
        fighter.awakening.avatar.update_pose(1.0 / 60.0, true, 0.42, Vector3.ZERO, 0.42)
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://docs/captures/henrique_combat100.png") == OK, "Rendered Henrique/Susanoo capture saves")
    current_scene.queue_free()
    current_scene = null
    flow._clear_pending_battle()
    await frames(4)
    print("COMBAT EXPANSION CONTRACT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
    quit(0 if failures == 0 else 1)
