extends "res://tests/base_basic_visual_contract.gd"
## Real imported skin, combat lifecycle and campaign integration regressions.

func run() -> void:
    var flow: Node = root.get_node("GameFlow")
    flow.save_path = "user://henrique_contract.json"
    CharacterCatalog.initialize()
    check(CharacterCatalog.READY.size() == 26, "25 existing fighters plus Henrique")
    check(flow.player_character == CharacterCatalog.HENRIQUE, "Henrique is default protagonist")
    check(flow.start_versus("henrique", "henrique", "training") == OK, "Both teams support Henrique")
    await frames(12)
    var player: CharacterBody3D = current_scene.get_node("Player")
    var cpu: CharacterBody3D = current_scene.get_node("EnemyDummy")
    player.set_physics_process(false)
    cpu.set_physics_process(false)
    cpu.enable_arsenal = false
    for actor: CharacterBody3D in [player, cpu]:
        check(actor.rig_adapter.rig_loaded, "Uploaded Henrique model loads")
        check(actor.rig_adapter.skeleton.get_bone_count() == 65, "Henrique has full 65-bone skin")
        check(actor.rig_adapter.real_animation_count == 127, "All 127 clips retarget to chibi rig")
        check(actor.awakening.avatar != null and actor.ultimate.avatar != null, "Both teams have Susanoo controllers")
        check(actor.awakening.avatar.external_model and actor.ultimate.avatar.external_model, "Both teams load the licensed ready-made Susanoo")
        actor.awakening.avatar.set_quality(0)
        check(actor.awakening.avatar.wings.size() == 1 and not actor.awakening.avatar.wings[0].visible, "Mobile quality hides wide wings")
        var upper_hands: Node3D = actor.awakening.avatar.imported_avatar.find_child("Object_10", true, false) as Node3D
        check(upper_hands != null and upper_hands.visible, "Upper hands are anatomy, not wings to hide")
    check(player.rig_adapter.skeleton != cpu.rig_adapter.skeleton, "Independent CPU skeleton")
    check(player.moveset.ground[0].attack_id.begins_with("henrique_"), "Independent attack data")
    var adapter: Node3D = player.rig_adapter
    adapter.set_physics_process(false)
    adapter.animation_tree.active = false
    adapter.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var meshes: Array[MeshInstance3D] = []
    adapter._collect_mesh_instances(adapter.model_instance, meshes)
    check(meshes.size() == 1 and meshes[0].skin != null, "One genuinely skinned mesh")
    check(meshes[0].mesh.surface_get_array_index_len(0) / 3 < 20000, "Mobile triangle budget")
    var library: AnimationLibrary = adapter.animation_player.get_animation_library(&"combat")
    var snapshots: Dictionary = {}
    for clip_name: StringName in library.get_animation_list():
        var clip: Animation = library.get_animation(clip_name)
        var poses: Array = []
        var first: PackedVector3Array = []
        var motion: float = 0.0
        for phase: float in [0.0, 0.45, 0.85]:
            adapter.animation_player.play(StringName("combat/" + String(clip_name)))
            adapter.animation_player.seek(clip.length * phase, true)
            adapter.animation_player.advance(0.0)
            adapter.skeleton.force_update_all_bone_transforms()
            var points: PackedVector3Array = samples(meshes[0], adapter.skeleton, adapter.applied_model_scale)
            var minimum: Vector3 = Vector3(INF, INF, INF)
            var maximum: Vector3 = -minimum
            for i: int in range(points.size()):
                check(points[i].is_finite(), "Finite skin: " + String(clip_name))
                minimum = minimum.min(points[i])
                maximum = maximum.max(points[i])
                if not first.is_empty():
                    motion = maxf(motion, points[i].distance_to(first[i]))
            var size: Vector3 = maximum - minimum
            check(size.x < 3.5 and size.y < 3.5 and size.z < 3.5, "Bounded animation: " + String(clip_name))
            if first.is_empty():
                first = points
            var pose: Dictionary = {}
            for i: int in range(adapter.skeleton.get_bone_count()):
                var transform: Transform3D = adapter.skeleton.get_bone_global_pose(i)
                var q: Quaternion = transform.basis.get_rotation_quaternion()
                pose[String(adapter.skeleton.get_bone_name(i))] = {"position": [transform.origin.x, transform.origin.y, transform.origin.z], "rotation": [q.x, q.y, q.z, q.w]}
            poses.append(pose)
        if clip_name in [&"run", &"attack_1", &"attack_4", &"defeat"]:
            check(motion > 0.03, "Mesh actually deforms: " + String(clip_name))
        snapshots[String(clip_name)] = poses
    if "--dump-poses" in OS.get_cmdline_user_args():
        var file: FileAccess = FileAccess.open("res://tests/animation_poses.json", FileAccess.WRITE)
        file.store_string(JSON.stringify(snapshots))
        file.close()

    player.velocity = Vector3.DOWN * 50.0
    player.move_and_slide()
    player.velocity = Vector3.ZERO
    player.health = player.max_health
    player.chakra = player.max_chakra
    check(not player.awakening.start(), "High HP cannot awaken")
    check(not player.specials.start("henrique_susanoo_slash"), "Susanoo slash needs transformation")
    player.health = player.max_health * 0.45
    player.chakra = 10.0
    check(not player.awakening.start(), "Transformation needs full chakra")
    player.chakra = player.max_chakra
    check(player.awakening.start(), "Valid transformation starts")
    player.awakening._physics_process(1.0)
    check(player.awakening.active and player.awakening.avatar.visible, "Susanoo materializes")
    check(is_equal_approx(player.awakening.damage_multiplier(), 1.30), "Transformed attacks gain damage")
    player.chakra = 100.0
    player.jutsu_cooldown = 0.0
    check(player.specials.start("henrique_susanoo_slash"), "Transformed sword attack starts")
    player.specials._physics_process(0.5)
    var hp: float = cpu.health
    player.specials.rasengan_hitbox.try_hit(cpu)
    check(cpu.health < hp, "Susanoo sword deals real damage")
    var after: float = cpu.health
    player.specials.rasengan_hitbox.try_hit(cpu)
    check(is_equal_approx(cpu.health, after), "Sword cannot repeat-hit same target")
    player.specials.cancel()
    player.awakening._physics_process(20.0)
    check(not player.awakening.active and not player.awakening.avatar.visible, "Duration expires and clears avatar")
    check(is_equal_approx(player.awakening.damage_multiplier(), 1.0), "Damage returns to normal")
    player.awakening.reset()
    player.chakra = player.max_chakra
    player.jutsu_timer = 0.0
    player.stagger_timer = 0.0
    check(player.awakening.start(), "Awakening can restart after reset")
    player.stagger_timer = 0.2
    player.awakening._physics_process(0.01)
    check(not player.awakening.transforming and not player.awakening.avatar.visible, "Hit interrupts transformation")
    player.stagger_timer = 0.0
    player.awakening.reset()
    player.chakra = player.max_chakra
    player.jutsu_timer = 0.0
    player.jutsu_cooldown = 0.0
    check(player.specials.start("henrique_katon"), "Katon starts in normal mode")
    player.specials._physics_process(0.6)
    check(player.specials.projectiles.any(func(p: Node3D) -> bool: return p.active), "Katon releases pooled projectile")
    player.specials.cancel()
    player.jutsu_timer = 0.0
    player.jutsu_cooldown = 0.0
    player.chakra = player.max_chakra
    check(player.specials.start("henrique_chidori"), "Chidori uses real hand timeline")
    player.specials.cancel()
    player.jutsu_timer = 0.0
    player.attack_cooldown = 0.0
    player.chakra = player.max_chakra
    cpu.health = cpu.max_health
    cpu.stagger_timer = 0.0
    cpu.invulnerable_timer = 0.0
    check(player.ultimate.start(), "Henrique Ultimate starts")
    player.ultimate.entry_box.activate(player.ultimate, 4.0, 1.5, 0.0, 0.75, 0.28)
    player.ultimate.entry_box.try_hit(cpu)
    check(player.ultimate.phase == "sequence", "Ultimate requires confirmed entry hit")
    player.ultimate._physics_process(0.2)
    check(player.ultimate.avatar.visible, "Ultimate summons same Susanoo")
    player.ultimate.cancel()
    check(not player.ultimate.avatar.visible and cpu.cinematic_owner == null, "Cancelled Ultimate releases target and avatar")
    player.awakening.stop()
    check(flow.enter_world() == OK, "Exploration remains available")
    await frames(10)
    var world_player: Node = get_first_node_in_group("world_player")
    check(world_player.get_character_definition() == CharacterCatalog.HENRIQUE, "Henrique explores village")
    check(world_player.rig_adapter.rig_loaded, "Same Henrique model loads in exploration")
    flow.progress.story_index = 0
    flow.progress.unlocked_jutsus = ["demon"]
    check(flow.start_story_battle() == OK, "Existing story battle starts")
    await frames(10)
    check(current_scene.get_node("Player").character_definition == CharacterCatalog.HENRIQUE, "Story keeps Henrique protagonist")
    var story_player: Node = current_scene.get_node("Player")
    check(story_player.specials._available_choices() == PackedStringArray(["henrique_katon"]), "New campaign starts with Katon only")
    flow.progress.unlocked_jutsus.append("clones")
    check(story_player.specials._available_choices().has("henrique_chidori"), "Existing Academy milestone unlocks Chidori")
    flow.progress.unlocked_jutsus.append("barrage")
    check(story_player.specials._available_choices().has("henrique_susanoo_slash"), "Existing bell-test milestone unlocks Susanoo slash")
    check(flow.story_dialogue("intro").all(func(line: Dictionary) -> bool: return line.get("speaker", "") != "Naruto"), "Hero dialogue uses Henrique")
    flow._clear_pending_battle()
    check(flow.enter_selection() == OK, "Selection remains available")
    await frames(8)
    check(current_scene.player_pick.item_count == 26, "All old characters retained")
    check(CharacterCatalog.READY[current_scene.player_pick.selected] == CharacterCatalog.HENRIQUE, "Menu highlights protagonist")
    DirAccess.remove_absolute(flow.save_path)
    print("HENRIQUE CONTRACT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
    quit(0 if failures == 0 else 1)
