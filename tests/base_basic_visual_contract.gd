extends SceneTree
## Exercise the actual imported skin against every installed combat clip.
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
        await process_frame

func samples(mesh: MeshInstance3D, skeleton: Skeleton3D, model_scale: float) -> PackedVector3Array:
    var transforms: Array[Transform3D] = []
    for index: int in range(mesh.skin.get_bind_count()):
        var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(index))
        if bone < 0:
            bone = mesh.skin.get_bind_bone(index)
        transforms.append(skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(index))
    var arrays: Array = mesh.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
    var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
    var influences: int = bones.size() / vertices.size()
    var result: PackedVector3Array = []
    for vertex: int in range(0, vertices.size(), 48):
        var position: Vector3 = Vector3.ZERO
        var total: float = 0.0
        for influence: int in range(influences):
            var offset: int = vertex * influences + influence
            if weights[offset] > 0.0:
                position += (transforms[bones[offset]] * vertices[vertex]) * weights[offset]
                total += weights[offset]
        check(absf(total - 1.0) < 0.001, "Skin weights sum to one")
        result.append(position * model_scale)
    return result

func run() -> void:
    var flow: Node = root.get_node("GameFlow")
    check(CharacterCatalog.NARUTO.model_path == "res://assets/characters/repaired/naruto_mobile.glb", "Naruto uses the single animated 3D model")
    check(is_equal_approx(CharacterCatalog.NARUTO.model_target_height, 1.70), "Naruto keeps tuned mobile character height")
    check(CharacterCatalog.NARUTO.idle_animation_override.is_empty(), "Naruto must use the real combat idle instead of chakra-charge as idle")
    check(CharacterCatalog.SAKURA.display_name == "Sakura" and CharacterCatalog.SAKURA.model_yaw_degrees == 0.0, "Sakura profile must expose corrected name and facing")
    check(flow.start_versus("naruto", "naruto", "training") == OK, "Naruto versus opens")
    await frames(8)
    var fighter: CharacterBody3D = current_scene.get_node("Player")
    var cpu: CharacterBody3D = current_scene.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    cpu.enable_arsenal = false
    for actor: CharacterBody3D in [fighter, cpu]:
        var adapter: Node3D = actor.rig_adapter
        check(adapter.rig_loaded and adapter.model_instance.visible, "Each team shows its animated model")
        check(adapter.get_node_or_null("LicensedCombatNinja") == null, "Naruto keeps its configured 3D model instead of the generic ninja skin")
        check(adapter.skeleton.get_bone_count() == 65 and adapter.real_animation_count == 127, "Complete skeleton and library load")
        var meshes: Array[MeshInstance3D] = []
        adapter._collect_mesh_instances(adapter.model_instance, meshes)
        check(meshes.size() == 1 and meshes[0].skin != null, "Optimized imported mesh has real skin")
        check(meshes[0].mesh.surface_get_array_index_len(0) / 3 <= 60000, "Geometry fits the configured mobile budget")
        for clone: Node3D in actor.specials.clones:
            check(clone.model.visible and clone.skeleton != adapter.skeleton, "Clones have independent visible 3D rigs")
            check(clone.model.position.is_equal_approx(adapter.model_instance.position), "Clones inherit corrected grounding")
    var adapter: Node3D = fighter.rig_adapter
    check(adapter._animation_for_state("idle") == &"combat/idle", "Naruto idle state must resolve to combat/idle")
    adapter.set_physics_process(false)
    adapter.animation_tree.active = false
    adapter.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var meshes: Array[MeshInstance3D] = []
    adapter._collect_mesh_instances(adapter.model_instance, meshes)
    var library: AnimationLibrary = adapter.animation_player.get_animation_library(&"combat")
    for name: StringName in library.get_animation_list():
        var clip: Animation = library.get_animation(name)
        var first: PackedVector3Array = []
        var maximum_motion: float = 0.0
        for phase: float in [0.0, 0.45, 0.85]:
            adapter.animation_player.play(StringName("combat/" + String(name)))
            adapter.animation_player.seek(clip.length * phase, true)
            adapter.animation_player.advance(0.0)
            adapter.skeleton.force_update_all_bone_transforms()
            var points: PackedVector3Array = samples(meshes[0], adapter.skeleton, adapter.applied_model_scale)
            var minimum: Vector3 = Vector3(INF, INF, INF)
            var maximum: Vector3 = Vector3(-INF, -INF, -INF)
            for index: int in range(points.size()):
                check(points[index].is_finite(), "Finite animated skin: " + String(name))
                minimum = minimum.min(points[index])
                maximum = maximum.max(points[index])
                if not first.is_empty():
                    maximum_motion = maxf(maximum_motion, points[index].distance_to(first[index]))
            var size: Vector3 = maximum - minimum
            check(size.x < 3.5 and size.y < 3.5 and size.z < 3.5 and size.length() > 0.4, "Skin stays fighter-sized: " + String(name))
            if first.is_empty():
                first = points
        if name in [&"run", &"sprint", &"attack_1", &"attack_2", &"defeat"]:
            check(maximum_motion > 0.03, "Clip visibly deforms the supplied mesh: " + String(name))
    check(adapter.skeleton != cpu.rig_adapter.skeleton and adapter.animation_tree != cpu.rig_adapter.animation_tree, "CPU playback is independent")
    check(flow.enter_selection() == OK, "Selection opens")
    await frames(5)
    for preview: CharacterBody3D in current_scene.preview.fighters:
        check(preview.rig_adapter.rig_loaded and preview.rig_adapter.model_instance.visible, "Menu previews animate the configured model")
    check(flow.enter_world() == OK, "Exploration opens")
    await frames(8)
    var world_player: Node = get_first_node_in_group("world_player")
    check(world_player != null and world_player.rig_adapter.rig_loaded and world_player.rig_adapter.model_instance.visible, "Exploration uses the same animated 3D model")
    print("BASE BASIC VISUAL CONTRACT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
    quit(0 if failures == 0 else 1)
