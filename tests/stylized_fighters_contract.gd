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

func skin_bounds(mesh: MeshInstance3D, skeleton: Skeleton3D) -> AABB:
    var skin: Skin = mesh.skin
    var transforms: Array[Transform3D] = []
    for index: int in range(skin.get_bind_count()):
        var bone: int = skeleton.find_bone(skin.get_bind_name(index))
        if bone < 0:
            bone = skin.get_bind_bone(index)
        transforms.append(skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(index))
    var arrays: Array = mesh.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
    var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
    var minimum: Vector3 = Vector3(INF, INF, INF)
    var maximum: Vector3 = Vector3(-INF, -INF, -INF)
    var influences: int = bones.size() / vertices.size()
    for index: int in range(vertices.size()):
        var vertex: Vector3 = Vector3.ZERO
        for influence: int in range(influences):
            var offset: int = index * influences + influence
            if weights[offset] > 0.0:
                vertex += (transforms[bones[offset]] * vertices[index]) * weights[offset]
        minimum = minimum.min(vertex)
        maximum = maximum.max(vertex)
    return AABB(minimum, maximum - minimum)

func run() -> void:
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)
    var flow: Node = root.get_node("GameFlow")
    var model_paths: Dictionary = {}
    var shared_library: AnimationLibrary
    for definition: CharacterDefinition in CharacterCatalog.READY:
        check(not model_paths.has(definition.model_path), "Each selected fighter needs its own mesh")
        model_paths[definition.model_path] = true
        check(flow.start_versus(definition.character_id, definition.character_id, "training") == OK, "Every base profile can enter versus")
        await frames(8)
        var arena: Node3D = current_scene
        var player: CharacterBody3D = arena.get_node("Player")
        var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
        player.set_physics_process(false)
        cpu.set_physics_process(false)
        cpu.enable_arsenal = false
        for actor: CharacterBody3D in [player, cpu]:
            var adapter: Node3D = actor.rig_adapter
            check(adapter.rig_loaded and adapter.real_animation_count == 27, "All four profiles/CPU use 27 real clips")
            check(adapter.skeleton.get_bone_count() == 65, "Author mesh retains 65 Mixamo body bones")
            var meshes: Array[MeshInstance3D] = []
            adapter._collect_mesh_instances(adapter.model_instance, meshes)
            check(meshes.size() == 1 and meshes[0].mesh.get_surface_count() == 1, "One opaque skinned surface per model")
            check(meshes[0].material_override == adapter.TOON_MATERIAL, "Models share original toon material")
            var library: AnimationLibrary = adapter.animation_player.get_animation_library(&"combat")
            if shared_library == null:
                shared_library = library
            check(library == shared_library, "Four compatible models share immutable clip data")
            adapter.set_physics_process(false)
            adapter.animation_tree.active = false
            adapter.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
            for clip: String in ["idle", "attack_1", "air_attack_2", "rasengan"]:
                adapter.animation_player.play(StringName("combat/" + clip))
                adapter.animation_player.advance(0.15)
                adapter.skeleton.force_update_all_bone_transforms()
                var bounds: AABB = skin_bounds(meshes[0], adapter.skeleton)
                var size: Vector3 = bounds.size * adapter.applied_model_scale
                check(bounds.position.is_finite() and size.is_finite() and size.y > 0.5 and size.y < 4.0 and size.x < 5.0 and size.z < 5.0, "Animated vertices must stay finite and fighter-sized: " + clip)
            adapter.snap_attack_hitbox(1, false)
            var strike_bone: int = adapter._choose_strike_bone(1, false)
            var strike_pose: Transform3D = adapter.skeleton.global_transform * adapter.skeleton.get_bone_global_pose(strike_bone)
            check(actor.attack_hitbox.global_position.distance_to(strike_pose.origin) < 0.2, "Collision follows manifest-selected strike bone")
        var presentation: Node3D = arena.get_node("ArenaPresentation")
        check(presentation.sectors.size() <= 32 and presentation.triangles < 20000, "Merged arena must respect bounded geometry budget")
        var quality: Node = arena.get_node("MobileQuality")
        quality.apply(0, false)
        check(not arena.get_node("Sun").shadow_enabled and not presentation.environment.environment.fog_enabled, "LOW removes shadows/fog")
        quality.apply(2, false)
        check(arena.get_node("Sun").shadow_enabled and presentation.environment.environment.fog_enabled, "HIGH restores optional effects")
        check(player.camera_rig.spring_arm.collision_mask == 33, "Camera detects world and decorative roof layers")
        if definition.character_id == "sakura":
            check(player.specials.selected.is_empty() and player.specials.projectiles.is_empty(), "Melee Sakura does not allocate foreign jutsu pools")
            player.specials.cycle_selection()
            check(not player.specials.start(), "Empty jutsu profile is safe")
            cpu.arsenal_delay = 0.0
            cpu.attack_cooldown = 0.0
            cpu.stagger_timer = 0.0
            cpu._decide_arsenal(6.0)
            var controls: Control = arena.get_node("HUD/MobileControls")
            check(not controls.jutsu_enabled and controls.special_label == "—", "Sakura unfinished jutsu is disabled on mobile")
        if definition.character_id == "kakashi":
            check(player.specials.selected == "chidori" and player.specials.projectiles.is_empty(), "Kakashi shares lightning mechanic without Naruto projectile pools")
            player.jutsu_cooldown = 0.0
            check(player.specials.start("chidori") and not player.ultimate.start(), "Kakashi lightning works without Naruto Ultimate")
        check(flow.enter_selection() == OK, "Profile returns safely to selection")
        await frames(5)
        var menu: Control = current_scene
        menu.player_pick.select(CharacterCatalog.READY.find(definition))
        menu._describe(0)
        await frames(3)
        check(menu.preview.fighters.size() == 2 and menu.preview.fighters[0].rig_adapter.model_path == definition.model_path, "3D preview follows chosen profile")
        check(menu.start_button.get_global_rect().end.y <= 720, "Preview cannot displace touch start button")
    current_scene.queue_free()
    await frames(5)
    check(root.get_child_count() == 1, "No leaked preview, pool or environment nodes")
    print("STYLIZED FIGHTERS CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
