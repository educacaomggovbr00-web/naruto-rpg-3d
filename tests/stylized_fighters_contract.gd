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

func wait_for_scene(path: String, max_frames: int = 180) -> Node:
    for index: int in range(max_frames):
        if current_scene != null and current_scene.scene_file_path == path:
            return current_scene
        await physics_frame
    return current_scene

func check_retarget_math() -> void:
    var adapter: Node3D = preload("res://scripts/rigged_character_adapter.gd").new()
    check(adapter._ensure_reference_rest_cache(), "Compact retarget metadata must load without the reference GLB")
    check(adapter._has_reference_rest("mixamorig_Hips"), "Retarget metadata must contain the reference hips")

    var animation: Animation = Animation.new()
    animation.length = 1.0
    var rotation_track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
    var position_track: int = animation.add_track(Animation.TYPE_POSITION_3D)

    var source_rest_rotation: Quaternion = Quaternion.from_euler(Vector3(0.2, -0.3, 0.1))
    var target_rest_rotation: Quaternion = Quaternion.from_euler(Vector3(-0.4, 0.1, 0.35))
    var relative_rotation: Quaternion = Quaternion.from_euler(Vector3(0.12, 0.18, -0.08))
    var source_rest: Transform3D = Transform3D(Basis(source_rest_rotation), Vector3(0.0, 10.0, 0.0))
    var target_rest: Transform3D = Transform3D(Basis(target_rest_rotation), Vector3(0.0, 2.0, 0.0))
    animation.rotation_track_insert_key(rotation_track, 0.0, (source_rest_rotation * relative_rotation).normalized())
    animation.position_track_insert_key(position_track, 0.0, source_rest.origin + Vector3(1.0, -2.0, 3.0))

    adapter._retarget_track(animation, rotation_track, source_rest, target_rest)
    adapter._retarget_track(animation, position_track, source_rest, target_rest)

    var actual_rotation: Quaternion = animation.track_get_key_value(rotation_track, 0)
    var expected_rotation: Quaternion = (target_rest_rotation * relative_rotation).normalized()
    check(absf(actual_rotation.dot(expected_rotation)) > 0.99999, "Retarget must preserve rotation relative to Bone Rest")

    var actual_position: Vector3 = animation.track_get_key_value(position_track, 0)
    var expected_position: Vector3 = target_rest.origin + Vector3(1.0, -2.0, 3.0) * 0.2
    check(actual_position.distance_to(expected_position) < 0.00001, "Retarget must normalize position delta to target bone length")
    adapter.free()

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
    CharacterCatalog.initialize()
    check_retarget_math()
    check(CharacterCatalog.READY.size() == 25, "Storm 1 selection must expose all 25 playable fighters")
    var placeholder_count: int = 0
    for definition: CharacterDefinition in CharacterCatalog.READY:
        if definition.visual_status == "STORM1_ROSTER_SLOT_SHARED_PLACEHOLDER_RIG":
            placeholder_count += 1
    check(placeholder_count == 21, "Twenty-one roster slots should use the temporary shared rig until their visuals are authored")
    var model_paths: Dictionary = {}
    var shared_stylized_library: AnimationLibrary
    for definition: CharacterDefinition in CharacterCatalog.AUTHORED_VISUALS:
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
            check(adapter.rig_loaded and adapter.real_animation_count == 27, "Authored profiles/CPU use 27 real clips")
            check(adapter.skeleton.get_bone_count() >= 27, "Authored mesh keeps a complete Mixamo body rig")
            check(adapter._has_required_combat_bones(), "Authored mesh keeps every combat-critical hand/foot/body bone")
            var meshes: Array[MeshInstance3D] = []
            adapter._collect_mesh_instances(adapter.model_instance, meshes)
            if definition.character_id == "naruto":
                check(meshes.size() == 1, "BaseBasic Naruto uses one optimized skinned mesh")
                check(meshes[0].mesh.surface_get_array_index_len(0) / 3 <= 60000, "Naruto stays within the offline triangle budget")
                for mesh: MeshInstance3D in meshes:
                    check(mesh.material_override == null, "Pre-Shippuden Naruto keeps embedded materials/textures")
                    for surface: int in range(mesh.mesh.get_surface_count()):
                        var original: StandardMaterial3D = mesh.mesh.surface_get_material(surface) as StandardMaterial3D
                        var anime: StandardMaterial3D = mesh.get_surface_override_material(surface) as StandardMaterial3D
                        if original != null and original.normal_enabled:
                            check(anime != null and anime.normal_enabled and anime.normal_texture == original.normal_texture, "PBR Naruto keeps its normal map")
                            check(anime != null and anime.metallic_texture == original.metallic_texture and anime.roughness_texture == original.roughness_texture, "PBR Naruto keeps metallic/roughness maps")
                        else:
                            check(anime != null and anime.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON and anime.rim_enabled, "Simple Naruto materials receive toon lighting per surface")
                        if anime != null and original != null:
                            check(anime.albedo_texture == original.albedo_texture, "Anime lighting preserves each original Naruto texture")
                            check(anime.albedo_color == original.albedo_color, "Anime lighting preserves each original Naruto tint")
                check(definition.model_auto_scale and adapter.detected_source_height > 150.0 and adapter.detected_source_height < 200.0, "Naruto mesh bounds use the same centimeter units as its skeleton")
                check(absf(adapter.applied_model_scale * adapter.detected_source_height - definition.model_target_height) < 0.001, "Naruto respects its tuned physical height")
                var collision: CollisionShape3D = actor.get_node("CollisionShape3D")
                check(absf(adapter.model_instance.position.y + adapter.detected_source_min_y * adapter.applied_model_scale - (collision.position.y - collision.shape.height * 0.5)) < 0.001, "Naruto soles align with each actor's physical capsule bottom")
                check(is_equal_approx(adapter.model_instance.rotation_degrees.y, 180.0), "Naruto faces the same combat axis as the other fighters")
            elif definition.character_id == "sakura" and adapter.model_path == definition.model_path:
                check(meshes.size() == 1 and meshes[0].mesh.get_surface_count() == 1, "User Sakura keeps one optimized skinned surface")
                check(adapter.native_locomotion_count >= 3, "Sakura must keep native Idle/Walk/Run")
                check(adapter._animation_for_state("idle") == &"native/idle", "Sakura idle must use her native rig animation")
                check(adapter._animation_for_state("run") == &"native/walk", "Sakura movement must use her native walk")
                check(adapter._animation_for_state("sprint") == &"native/run", "Sakura sprint must use her native run")
                check(meshes[0].mesh.surface_get_array_index_len(0) / 3 <= 50000, "User Sakura stays within the mobile triangle budget")
                check(meshes[0].material_override == null, "Textured Sakura keeps her embedded material instead of the flat placeholder shader")
                check(adapter.detected_source_height > 1.0 and adapter.detected_source_height < 2.5, "User Sakura arrives in meter-like source units")
                check(absf(adapter.applied_model_scale * adapter.detected_source_height - definition.model_target_height) < 0.001, "User Sakura respects her tuned combat height")
                check(is_equal_approx(adapter.model_instance.rotation_degrees.y, definition.model_yaw_degrees), "Sakura keeps her corrected forward facing")
            else:
                check(meshes.size() == 1 and meshes[0].mesh.get_surface_count() == 1, "Original authored fighter keeps one opaque skinned surface")
                check(meshes[0].material_override == adapter.TOON_MATERIAL, "Original authored fighters keep the project toon material")
            var library: AnimationLibrary = adapter.animation_player.get_animation_library(&"combat")
            check(library == cpu.rig_adapter.animation_player.get_animation_library(&"combat"), "Identical profiles share immutable prepared clips across teams")
            if definition.character_id != "naruto" and adapter.skeleton.get_bone_count() == 65:
                if shared_stylized_library == null:
                    shared_stylized_library = library
                check(library == shared_stylized_library, "Compatible 65-bone authored models share immutable clip data")
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
            check(player.specials.selected == "booby_trap" and player.specials.projectiles.is_empty() and player.specials.traps.size() == 3, "Sakura owns trap pool without foreign projectile pools")
            player.specials.cycle_selection()
            check(not player.specials.start("rasengan"), "Sakura rejects foreign Naruto jutsu")
            cpu.arsenal_delay = 0.0
            cpu.attack_cooldown = 0.0
            cpu.stagger_timer = 0.0
            cpu._decide_arsenal(6.0)
            var controls: Control = arena.get_node("HUD/MobileControls")
            check(controls.jutsu_enabled and controls.special_label == "TRAP", "Sakura trap is available on mobile")
        if definition.character_id == "kakashi":
            check(player.specials.selected == "raikiri" and player.specials.projectiles.size() == 3, "Kakashi owns Raikiri and fireball pool")
            player.jutsu_cooldown = 0.0
            check(player.specials.start("raikiri") and not player.ultimate.start(), "Kakashi lightning works without Naruto Ultimate")
        check(flow.enter_selection() == OK, "Profile returns safely to selection")
        var loaded_scene: Node = await wait_for_scene("res://selection.tscn")
        var menu: Control = loaded_scene as Control
        check(menu != null, "Selection scene must become ready before preview validation")
        if menu == null:
            continue
        menu.player_pick.select(CharacterCatalog.READY.find(definition))
        menu._describe(0)
        await frames(5)
        var preview_path: String = menu.preview.fighters[0].rig_adapter.model_path if menu.preview.fighters.size() == 2 else ""
        var valid_preview_path: bool = preview_path == definition.model_path or (not definition.model_fallback_path.is_empty() and preview_path == definition.model_fallback_path)
        check(menu.preview.fighters.size() == 2 and valid_preview_path, "3D preview follows preferred model or its declared fallback")
        check(menu.start_button.get_global_rect().end.y <= 720, "Preview cannot displace touch start button")
    current_scene.queue_free()
    await frames(5)
    check(root.get_child_count() == 1, "No leaked preview, pool or environment nodes")
    print("STYLIZED FIGHTERS CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
