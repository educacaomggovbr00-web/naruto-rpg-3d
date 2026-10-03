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
        var quality: Node = arena.get_node("MobileQuality")
        for level: int in [0, 1, 2]:
            quality.apply(level, false)
            check(arena.get_node("Sun").shadow_enabled == (level > 0), "Arena quality controls shadows")
            check(arena.get_node("ArenaPresentation").environment.environment.fog_enabled == (level > 0), "Arena quality controls haze")
        await settle()
        await capture(arena_id)
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
