extends SceneTree
const RiggedCharacterAdapter = preload("res://scripts/rigged_character_adapter.gd")
var failures: int = 0
var checks: int = 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error(message)
func frames(count: int) -> void:
    for i: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1280,720)
    var marker: String = "user://stability_test_session.json"
    var graphics_path: String = "user://stability_test_graphics.cfg"
    DirAccess.remove_absolute(marker)
    var graphics: ConfigFile = ConfigFile.new()
    graphics.set_value("graphics", "quality", 2)
    graphics.set_value("other", "preserved", "unchanged")
    graphics.save(graphics_path)
    var stability = root.get_node("RuntimeStability")
    check(not stability.recover_graphics(marker, graphics_path), "Normal startup does not downgrade saved quality")
    graphics.load(graphics_path)
    check(graphics.get_value("graphics", "quality") == 2, "High quality survives normal startup")
    var marker_file: FileAccess = FileAccess.open(marker, FileAccess.WRITE)
    marker_file.store_string("{}")
    marker_file.close()
    check(stability.recover_graphics(marker, graphics_path), "Interrupted foreground session enables recovery")
    graphics.load(graphics_path)
    check(graphics.get_value("graphics", "quality") == 0 and graphics.get_value("other", "preserved") == "unchanged", "Recovery selects LOW and preserves other preferences")
    DirAccess.remove_absolute(marker)
    DirAccess.remove_absolute(graphics_path)
    var anime = preload("res://scripts/anime_presentation.gd")
    var material_source: StandardMaterial3D = StandardMaterial3D.new()
    material_source.albedo_color = Color.RED
    var retained_material: Material = anime.textured(material_source)
    var sources: Array[StandardMaterial3D] = []
    for i: int in range(80):
        var source: StandardMaterial3D = StandardMaterial3D.new()
        source.albedo_color = Color.BLUE
        sources.append(source)
        anime.textured(source)
    check(anime.textured_cache.size() <= anime.MAX_CACHED_MATERIALS, "Material cache remains bounded after repeated model replacement")
    check(retained_material.albedo_color == Color.RED, "Eviction preserves active material appearance")
    var cached_material: Material = anime.textured(sources[-1])
    check(anime.textured(sources[-1]) == cached_material, "Live cached material is reused")
    var flow = root.get_node("GameFlow")
    check(flow.enter_selection() == OK, "Selection opens")
    await scene_changed
    await frames(3)
    var menu = current_scene
    var preview = menu.preview
    var player_id: int = preview.fighters[0].get_instance_id()
    var cpu_id: int = preview.fighters[1].get_instance_id()
    for i: int in range(10):
        preview.show_fighters(CharacterCatalog.HENRIQUE, CharacterCatalog.NARUTO)
    check(preview.fighters[0].get_instance_id() == player_id and preview.fighters[1].get_instance_id() == cpu_id, "Repeated menu updates retain both existing actors")
    var retained_library = preview.fighters[0].rig_adapter.animation_player.get_animation_library(&"combat")
    print("stability: roster stress")
    for definition: CharacterDefinition in CharacterCatalog.READY:
        preview.show_fighters(CharacterCatalog.HENRIQUE, definition)
        await frames(2)
        check(RiggedCharacterAdapter.library_cache.size() <= RiggedCharacterAdapter.MAX_CACHED_LIBRARIES, "Cache stays bounded: " + definition.character_id)
        check(preview.fighters[0].get_instance_id() == player_id, "Changing CPU preserves player: " + definition.character_id)
        check(preview.fighters[1].rig_adapter.real_animation_count == 127, "Every fighter retains all animations: " + definition.character_id)
    check(retained_library.get_animation_list().size() == 127 and preview.fighters[0].rig_adapter.rig_loaded, "Eviction preserves active fighter library")
    print("stability: navigation")
    check(not quit_on_go_back, "Android Back cannot automatically terminate app")
    stability.request_back()
    check(stability.exit_dialog.visible and current_scene == menu, "Back at menu requests explicit exit without terminating")
    stability.exit_dialog.hide()
    check(flow.start_versus("henrique", "naruto", "training") == OK, "Battle opens after roster stress")
    await scene_changed
    await frames(3)
    stability.request_back()
    for i in range(8): await process_frame
    await frames(3)
    check(current_scene.scene_file_path == "res://selection.tscn" and not paused and is_equal_approx(Engine.time_scale,1.0), "Battle Back returns to usable menu")
    current_scene.queue_free()
    await frames(4)
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        await process_frame
    print("ANDROID STABILITY CONTRACT: PASS" if failures == 0 else "ANDROID STABILITY CONTRACT: FAIL", " checks=", checks)
    quit(1 if failures else 0)
