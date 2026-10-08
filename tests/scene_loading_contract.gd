extends SceneTree
var failures: int = 0
var checks: int = 0
var previous: Node
var scene_count: int = 0
var capture: bool = "--capture" in OS.get_cmdline_user_args()
var captured: bool = false
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
func capture_loading() -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/captures/loading_0100.png")
    captured = true
func on_request(path: String) -> void:
    check(not is_instance_valid(previous), "Previous scene released before request: " + path)
    check(current_scene == null, "No simultaneous old scene during resource load")
    scene_count += 1
    if capture and not captured: capture_loading()
func run() -> void:
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1280,720)
    if capture: root.gui_embed_subwindows = true
    var flow = root.get_node("GameFlow")
    flow.save_path = "user://scene_loading_fixture_save.json"
    var loader = flow.loading_screen
    loader.resources_requested.connect(on_request)
    var preferences: ConfigFile = ConfigFile.new()
    for invalid: Variant in ["HIGH", [], {}, NAN, INF, true]:
        preferences.set_value("graphics", "quality", invalid)
        check(GraphicsPreferences.read_quality(preferences) == GraphicsPreferences.default_level(), "Malformed graphics value uses a safe default")
    for value: int in range(3):
        preferences.set_value("graphics", "quality", value)
        check(GraphicsPreferences.read_quality(preferences) == value, "Persisted graphic level remains available")
    check(GraphicsPreferences.save_quality(-1) == ERR_INVALID_PARAMETER and GraphicsPreferences.save_quality(3) == ERR_INVALID_PARAMETER, "Invalid graphics preference cannot be saved")
    check(not ResourceLoader.has_cached("res://assets/animations/combat_mixamo.tres"), "Startup does not preload the combat library before the loading screen")
    check(ProjectSettings.get_setting("application/run/main_scene") == "res://boot.tscn", "Startup uses a lightweight scene")
    check(change_scene_to_file("res://boot.tscn") == OK, "Boot scene opens")
    # Boot itself emits scene_changed before its asynchronous selection request.
    await scene_changed
    await scene_changed
    await frames(3)
    check(current_scene.scene_file_path == "res://selection.tscn" and not flow.busy and not loader.active, "Cold boot completes selection and releases input")
    check(flow._transition("res://missing_scene_fixture.tscn") == ERR_FILE_NOT_FOUND and not flow.busy, "Missing scene preserves current menu and does not lock navigation")
    current_scene._show_options()
    await frames(2)
    var graphics = current_scene.find_child("GraphicsQuality", true, false)
    check(graphics != null and graphics.item_count == 3, "Menu exposes all three graphics levels")
    var had_graphics: bool = FileAccess.file_exists(GraphicsPreferences.PATH)
    var previous_graphics: String = FileAccess.get_file_as_string(GraphicsPreferences.PATH) if had_graphics else ""
    var next_quality: int = (graphics.selected + 1) % 3
    graphics.select(next_quality)
    graphics.item_selected.emit(next_quality)
    check(GraphicsPreferences.read_quality() == next_quality, "Graphics menu persists selected quality for every scene")
    if had_graphics:
        var restored: FileAccess = FileAccess.open(GraphicsPreferences.PATH, FileAccess.WRITE)
        restored.store_string(previous_graphics)
        restored.close()
    else:
        DirAccess.remove_absolute(GraphicsPreferences.PATH)
    if capture:
        await frames(20)
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://docs/captures/options_0100.png")
    for dialog in current_scene.get_children():
        if dialog is AcceptDialog:
            check(dialog.size.y <= 720, "Graphics and controls options fit landscape height")
            dialog.queue_free()
    previous = current_scene
    check(flow.start_versus("henrique", "naruto", "training") == OK, "Battle request accepted")
    check(flow.busy and loader.active and previous.process_mode == Node.PROCESS_MODE_DISABLED, "Loading overlay blocks previous gameplay immediately")
    var first_generation: int = loader.generation
    check(flow.enter_world() == ERR_BUSY and loader.generation == first_generation, "Repeated input cannot enqueue a second scene")
    await scene_changed
    await frames(3)
    check(current_scene.get_node("Player").rig_adapter.real_animation_count == 127 and current_scene.get_node("EnemyDummy").rig_adapter.rig_loaded, "Loaded battle keeps both full rigs and combat clips")
    flow.world_region = "forest"
    flow.player_character = CharacterCatalog.SASUKE
    flow.cpu_character = CharacterCatalog.SAKURA
    flow.arena_id = "courtyard"
    for path: String in ["res://world.tscn", "res://region.tscn", "res://selection.tscn", "res://main.tscn", "res://selection.tscn"]:
        previous = current_scene
        check(flow._transition(path) == OK, "Repeated scene request succeeds: " + path)
        await scene_changed
        await frames(3)
        check(current_scene.scene_file_path == path and not flow.busy and not loader.active, "Target is ready and overlay gone: " + path)
    check(current_scene.player_pick.selected == CharacterCatalog.READY.find(CharacterCatalog.SASUKE) and current_scene.cpu_pick.selected == CharacterCatalog.READY.find(CharacterCatalog.SAKURA) and current_scene.arena_pick.selected == 1, "Menu retains both fighters and arena after navigation")
    check(current_scene.preview.fighters[0].definition == CharacterCatalog.SASUKE and current_scene.preview.fighters[1].definition == CharacterCatalog.SAKURA, "Preview starts with selected actors instead of allocating temporary protagonists")
    check(scene_count == 7, "All transitions release previous scene before loading")
    check(not paused and is_equal_approx(Engine.time_scale, 1.0), "Navigation leaves gameplay clocks running")
    loader.resources_requested.disconnect(on_request)
    current_scene.queue_free()
    previous = null
    await frames(4)
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        await process_frame
    print("SCENE LOADING CONTRACT: PASS" if failures == 0 else "SCENE LOADING CONTRACT: FAIL", " checks=", checks)
    quit(1 if failures else 0)
