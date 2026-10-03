extends SceneTree
## Copy this script outside the checkout, run with --main-pack from that directory.
## Otherwise res:// can fall back to checkout files and invalidate the check.
func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    if "--public" in OS.get_cmdline_user_args():
        if FileAccess.file_exists("res://main.tscn") or FileAccess.file_exists("res://assets/characters/rigged.glb") or FileAccess.file_exists("res://world.tscn"):
            push_error("Uncleared public payload leaked")
            quit(1)
            return
        var model_import: ConfigFile = ConfigFile.new()
        if model_import.load("res://assets/characters/rigged.glb.import") == OK:
            var imported_path: String = model_import.get_value("remap", "path", "")
            if FileAccess.file_exists(imported_path):
                push_error("Imported uncleared model leaked")
                quit(1)
                return
        print("PUBLIC PAYLOAD GATE: PASS")
        quit(0)
        return
    var game: Node = load("res://main.tscn").instantiate()
    root.add_child(game)
    for i: int in range(8):
        await physics_frame
    var fighter: Node = game.get_node("Player")
    if not fighter.rig_adapter.rig_loaded or fighter.rig_adapter.real_animation_count != 27 or fighter.ninja_tools.projectiles.size() != 6 or fighter.specials.clones.size() != 3:
        push_error("Development export lost rig/manifest or pools")
        quit(1)
        return
    if not ResourceLoader.exists("res://assets/vfx/chakra_core.gdshader") or not ResourceLoader.exists("res://assets/combat/naruto_handbook.tres"):
        push_error("Development export lost Naruto resources")
        quit(1)
        return
    if FileAccess.file_exists("res://tests/storm_slice_contract.gd") or FileAccess.file_exists("res://assets/animations/source/UAL2_Standard.glb") or FileAccess.file_exists("res://addons/release_asset_gate/plugin.gd"):
        push_error("Development-only pipeline leaked into runtime")
        quit(1)
        return
    game.queue_free()
    for i: int in range(3):
        await physics_frame
    var village: Node = load("res://world.tscn").instantiate()
    root.add_child(village)
    for i: int in range(8):
        await physics_frame
    if village.points.size() != 7 or not village.get_node("Player").rig_adapter.rig_loaded or not ResourceLoader.exists("res://assets/world/training.tres"):
        push_error("Development export lost village point JSON or mission/rig resources")
        quit(1)
        return
    print("WORLD ANDROID PACK: PASS")
    village.queue_free()
    print("ANDROID PHASE 1 PACK: PASS")
    await process_frame
    quit(0)
