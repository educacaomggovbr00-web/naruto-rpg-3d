extends SceneTree
## Rejected packs must be checked without parsing resource-dependent game classes.
## Copy outside the checkout and run with --main-pack.
func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    for id: String in ["naruto", "sasuke", "sakura", "kakashi"]:
        if ResourceLoader.exists("res://assets/characters/stylized/" + id + ".glb"):
            push_error("Development-only fan model leaked into public payload")
            quit(1)
            return
    if ProjectSettings.has_setting("autoload/GameFlow"):
        push_error("Rejected public container retained a resource-dependent autoload")
        quit(1)
        return
    if FileAccess.file_exists("res://main.tscn") or FileAccess.file_exists("res://assets/characters/rigged.glb") or FileAccess.file_exists("res://world.tscn") or FileAccess.file_exists("res://selection.tscn"):
        push_error("Uncleared public payload leaked")
        quit(1)
        return
    for path: String in ["res://assets/characters/base_basic/base_basic_pbr_rigged.glb", "res://assets/characters/sakura_user/sakura_mobile_rigged.glb", "res://assets/characters/definitions/henrique.tres", "res://assets/characters/henrique/henrique_mobile_rigged.glb", "res://assets/susanoo/susanoo_mobile.glb", "res://assets/susanoo/susanoo_mobile_rigged.glb"]:
        if FileAccess.file_exists(path) or ResourceLoader.exists(path):
            push_error("Uncleared real character/Susanoo leaked into public payload: " + path)
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
