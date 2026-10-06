extends SceneTree
## Copy this script outside the checkout, run with --main-pack from that directory.
## Otherwise res:// can fall back to checkout files and invalidate the check.
func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    if "--public" in OS.get_cmdline_user_args():
        for id: String in ["naruto", "sasuke", "sakura", "kakashi"]:
            if ResourceLoader.exists("res://assets/characters/stylized/" + id + ".glb"):
                push_error("Development-only fan model leaked into public payload")
                quit(1)
                return
        if ResourceLoader.exists("res://assets/characters/stylized/naruto_pre_shippuden.glb"):
            push_error("Pre-Shippuden Naruto development presentation leaked into public payload")
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
    if fighter.rig_adapter.sprite_mode or not fighter.rig_adapter.model_instance.visible or fighter.specials.clones[0].sprite_visual != null or not fighter.specials.clones[0].model.visible:
        push_error("Development export lost Naruto animated 3D model or clone visuals")
        quit(1)
        return
    for variant: String in ["pbr", "shaded"]:
        if ResourceLoader.exists("res://assets/characters/base_basic/base_basic_" + variant + ".glb"):
            push_error("Unoptimized million-triangle source model leaked into Android payload")
            quit(1)
            return
        if not ResourceLoader.exists("res://assets/characters/base_basic/base_basic_" + variant + "_rigged.glb"):
            push_error("Animation-ready material variant missing from Android payload")
            quit(1)
            return
    for asset: String in ["res://assets/vendor/quaternius_ninjas/Ninja_Male.glb", "res://assets/vendor/quaternius_ninjas/Ninja_Female.glb", "res://assets/vendor/kenney_particles/smoke_01.png", "res://assets/vendor/mehrasaur_weapons/kunai-gata-01.obj", "res://assets/vendor/kenney_nature/tree_oak.glb"]:
        if not ResourceLoader.exists(asset):
            push_error("Licensed gameplay asset missing from Android payload: " + asset)
            quit(1)
            return
    if not FileAccess.file_exists("res://assets/vendor/sources.json") or not FileAccess.file_exists("res://assets/vendor/quaternius_ninjas/LICENSE.txt"):
        push_error("Licensed asset provenance lost from Android payload")
        quit(1)
        return
    print("LICENSED GAMEPLAY ASSETS ANDROID PACK: PASS")
    var cpu: Node = game.get_node("EnemyDummy")
    if not cpu.rig_adapter.rig_loaded or fighter.moveset != cpu.moveset or fighter.moveset.neutral_finisher.launch_force != 0.0 or fighter.specials.projectiles[0].definition.speed != 19.0:
        push_error("Development export lost shared moveset, CPU rig or projectile definition")
        quit(1)
        return
    if not ResourceLoader.exists("res://assets/vfx/chakra_core.gdshader") or not ResourceLoader.exists("res://assets/combat/naruto_handbook.tres") or not FileAccess.file_exists("res://assets/animations/mixamo_reference_rest.json"):
        push_error("Development export lost Naruto or retarget resources")
        quit(1)
        return
    if FileAccess.file_exists("res://tests/storm_slice_contract.gd") or FileAccess.file_exists("res://assets/animations/source/UAL2_Standard.glb") or FileAccess.file_exists("res://addons/release_asset_gate/plugin.gd"):
        push_error("Development-only pipeline leaked into runtime")
        quit(1)
        return
    game.queue_free()
    for i: int in range(3):
        await physics_frame
    var menu: Node = load("res://selection.tscn").instantiate()
    root.add_child(menu)
    for index: int in range(3):
        await physics_frame
    var sasuke: Resource = load("res://assets/characters/definitions/sasuke.tres")
    if sasuke.jutsus != PackedStringArray(["fireball", "chidori"]) or not ResourceLoader.exists("res://assets/audio/kenney/impactPunch_medium_000.ogg") or not ResourceLoader.exists("res://assets/vfx/fire_core.gdshader"):
        push_error("Selectable character/audio/effect data lost in Android payload")
        quit(1)
        return
    print("SELECTABLE FIGHTERS ANDROID PACK: PASS")
    var catalog: Script = load("res://scripts/character_catalog.gd")
    catalog.initialize()
    var authored_visuals: int = 0
    var roster_placeholders: int = 0
    for definition: Resource in catalog.READY:
        var preferred_exists: bool = ResourceLoader.exists(definition.model_path)
        var fallback_exists: bool = not definition.model_fallback_path.is_empty() and ResourceLoader.exists(definition.model_fallback_path)
        if not preferred_exists and not fallback_exists:
            push_error("Export lost character mesh/profile: " + definition.character_id)
            quit(1)
            return
        if definition.visual_status in ["DEVELOPMENT_ONLY_ORIGINAL_FAN_MODEL", "DEVELOPMENT_ONLY_USER_SUPPLIED_PRE_SHIPPUDEN_RIGGED", "DEVELOPMENT_ONLY_USER_SUPPLIED_2_5D_SPRITES", "DEVELOPMENT_ONLY_USER_SUPPLIED_BASE_BASIC_RIGGED", "DEVELOPMENT_ONLY_USER_SUPPLIED_SAKURA_RIGGED"]:
            authored_visuals += 1
        elif definition.visual_status == "STORM1_ROSTER_SLOT_SHARED_PLACEHOLDER_RIG":
            roster_placeholders += 1
        else:
            push_error("Unexpected roster visual status: " + definition.character_id)
            quit(1)
            return
    if (
        catalog.READY.size() != 25
        or authored_visuals != 4
        or roster_placeholders != 21
        or not catalog.SAKURA.jutsus.has("booby_trap")
        or not catalog.SAKURA.jutsus.has("cherry_blossom_impact")
        or catalog.KAKASHI.jutsus != PackedStringArray(["raikiri", "fireball"])
    ):
        push_error("Export lost Storm 1 roster or current authored ability data")
        quit(1)
        return
    for definition: Resource in catalog.READY:
        for id: String in definition.jutsus:
            if definition.find_jutsu(id) == null:
                push_error("Export lost jutsu Resource: " + id)
                quit(1)
                return
    if not ResourceLoader.exists("res://scripts/booby_trap.gd"):
        push_error("Export lost physical trap strategy")
        quit(1)
        return
    print("CHARACTER JUTSU DATA ANDROID PACK: PASS")
    print("FULL STORM 1 ROSTER, MODEL SLOTS AND FOUR AUTHORED VISUALS ANDROID PACK: PASS")
    menu.queue_free()
    await process_frame
    var village: Node = load("res://world.tscn").instantiate()
    root.add_child(village)
    for i: int in range(8):
        await physics_frame
    if (
        village.points.size() != 10
        or not village.get_node("Player").rig_adapter.rig_loaded
        or not ResourceLoader.exists("res://assets/world/training.tres")
        or not FileAccess.file_exists("res://assets/world/story_campaign.json")
        or not ResourceLoader.exists("res://region.tscn")
    ):
        push_error("Development export lost village/story/region mission or rig resources")
        quit(1)
        return
    print("WORLD ANDROID PACK: PASS")
    print("RPG STORY AND REGIONS ANDROID PACK: PASS")
    village.queue_free()
    print("ANDROID PHASE 1 PACK: PASS")
    await process_frame
    quit(0)
