extends SceneTree
## Run headless for resource/quality checks; run with -- --capture for GPU images.
const ANIME: Script = preload("res://scripts/anime_presentation.gd")
const SCENERY: ShaderMaterial = preload("res://assets/world/anime_scenery.tres")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func settle() -> void:
    for index: int in range(12):
        await physics_frame

func capture(label: String) -> void:
    if not OS.get_cmdline_user_args().has("--capture"):
        return
    await RenderingServer.frame_post_draw
    var directory: String = "user://"
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--capture-dir="):
            directory = argument.trim_prefix("--capture-dir=")
    DirAccess.make_dir_recursive_absolute(directory)
    var output: String = directory.path_join("anime_%s.png" % label)
    check(root.get_texture().get_image().save_png(output) == OK, "Capture saves: " + label)
    print("ANIME CAPTURE: ", ProjectSettings.globalize_path(output))

func has_visible_mesh(node: Node) -> bool:
    if node is MeshInstance3D and node.visible and node.mesh != null:
        return true
    for child: Node in node.get_children():
        if has_visible_mesh(child):
            return true
    return false

func first_visible_mesh(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D and node.visible and node.mesh != null:
        return node as MeshInstance3D
    for child: Node in node.get_children():
        var result: MeshInstance3D = first_visible_mesh(child)
        if result != null:
            return result
    return null

func run() -> void:
    root.size = Vector2i(1280, 720)
    var source: StandardMaterial3D = StandardMaterial3D.new()
    source.albedo_color = Color("e87932")
    var material: StandardMaterial3D = ANIME.textured(source) as StandardMaterial3D
    check(material.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON and material.rim_enabled, "Opaque imported material receives toon lighting")
    check(ANIME.textured(source) == material, "Player, CPU and clones share imported material")
    check(source.albedo_color == Color("e87932") and source.next_pass == null, "Source color and single pass stay unchanged")
    source = StandardMaterial3D.new()
    source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    check(ANIME.textured(source) == source, "Transparent imports keep their source features")
    check(SCENERY.shader == ANIME.SURFACE, "Village and arena use the shared shader")
    change_scene_to_file("res://selection.tscn")
    await settle()
    await capture("selection")
    var flow: Node = root.get_node("GameFlow")
    for arena_id: String in ["training", "courtyard"]:
        check(flow.start_versus("naruto", "sasuke", arena_id) == OK, "Anime arena opens")
        await settle()
        var arena: Node = current_scene
        var fighter: CharacterBody3D = arena.get_node("Player") as CharacterBody3D
        var rival: CharacterBody3D = arena.get_node("EnemyDummy") as CharacterBody3D
        check(fighter.rig_adapter.get_node_or_null("LicensedCombatNinja") == null, "Player keeps the roster-selected 3D model instead of a generic ninja skin")
        check(rival.rig_adapter.get_node_or_null("LicensedCombatNinja") == null, "CPU keeps the roster-selected 3D model instead of a generic ninja skin")
        check(fighter.rig_adapter.rig_loaded and has_visible_mesh(fighter.rig_adapter.model_instance), "Naruto configured 3D model is instantiated and visible")
        check(rival.rig_adapter.rig_loaded and has_visible_mesh(rival.rig_adapter.model_instance), "Sasuke configured 3D model is instantiated and visible")
        check(fighter.rig_adapter.model_path == fighter.get_character_definition().model_path, "Player renders Naruto's configured model path")
        check(rival.rig_adapter.model_path == rival.get_character_definition().model_path, "CPU renders Sasuke's configured model path")
        check(fighter.rig_adapter.real_animation_count == 27 and rival.rig_adapter.real_animation_count == 27, "Both roster combat rigs retain all 27 clips")
        var visible_player_mesh: MeshInstance3D = first_visible_mesh(fighter.rig_adapter.model_instance)
        check(visible_player_mesh != null, "Configured player mesh remains visible with anime presentation")
        if visible_player_mesh != null:
            var player_material: Material = visible_player_mesh.get_active_material(0)
            check(player_material != null, "Configured player mesh keeps a valid runtime material")
        var quality: Node = arena.get_node("MobileQuality")
        for level: int in [0, 1, 2]:
            quality.apply(level, false)
            check(arena.get_node("Sun").shadow_enabled == (level > 0), "Arena quality controls shadows")
            check(arena.get_node("ArenaPresentation").environment.environment.fog_enabled == (level > 0), "Arena quality controls haze")
        await settle()
        await capture(arena_id)
        if arena_id == "training" and fighter_skin != null:
            fighter.call("_try_attack")
            await physics_frame
            var tool: Node = fighter.ninja_tools.projectiles[0]
            var weapon_origin: Vector3 = fighter.rig_adapter.call("get_hand_world_position")
            tool.call("launch", fighter, rival, weapon_origin, (rival.global_position - weapon_origin).normalized(), "shuriken")
            check(tool.visible and tool.shuriken.visible, "A live kunai/shuriken projectile renders in the combat arena")
            var feedback: Node = arena.get_node("CombatFeedback")
            feedback.call("spawn_chakra_impact", rival.global_position + Vector3.UP * 0.9, Color("36d8ff"))
            check(feedback.flashes.any(func(flash: MeshInstance3D) -> bool: return flash.visible), "A jutsu impact VFX is visible during gameplay")
            await physics_frame
            await capture("training_live_shuriken")
            tool.call("recycle")
            tool.call("launch", fighter, rival, weapon_origin, (rival.global_position - weapon_origin).normalized(), "kunai")
            check(tool.visible and tool.kunai.visible and not tool.shuriken.visible, "The licensed kunai mesh renders when the kunai is thrown")
            await capture("training_live_kunai")
            var camera: Camera3D = fighter.get_node("CameraRig/SpringArm3D/Camera3D") as Camera3D
            var vfx_position: Vector3 = rival.global_position + camera.global_basis.x * 0.7 + Vector3.UP * 1.0
            feedback.call("spawn_chakra_impact", vfx_position, Color("36d8ff"))
            check(feedback.flashes.any(func(flash: MeshInstance3D) -> bool: return flash.visible), "Jutsu impact billboards remain visibly pooled")
            await physics_frame
            await capture("training_live_jutsu_vfx")
    change_scene_to_file("res://world.tscn")
    await settle()
    var village: Node = current_scene
    for level: int in [0, 1, 2]:
        village.apply_quality(level, false)
        check(village.get_node("Sun").shadow_enabled == (level > 0), "Village quality controls shadows")
        check(village.get_node("Environment").environment.fog_enabled == (level > 0), "Village quality controls haze")
        check(village.get_node("Geometry").collision_count > 0, "Village retains physical traversal at every quality")
    await settle()
    await capture("village")
    current_scene.queue_free()
    await settle()
    await settle()
    print("ANIME PRESENTATION CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
