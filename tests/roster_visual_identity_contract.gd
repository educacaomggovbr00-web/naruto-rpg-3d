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
    for _index: int in range(count):
        await physics_frame

func run() -> void:
    CharacterCatalog.initialize()

    var procedural_count: int = 0
    var accessory_signatures: Dictionary = {}
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        if fighter.character_id in ["naruto", "sasuke", "sakura", "kakashi", "henrique"]:
            continue

        procedural_count += 1
        check(fighter.visual_profile != null, "Shared-rig fighter needs procedural visual profile: " + fighter.character_id)
        if fighter.visual_profile == null:
            continue

        check(fighter.visual_profile.evidence == "OUR_APPROXIMATION", "Procedural visual must disclose approximation: " + fighter.character_id)
        check(not fighter.visual_profile.accessories.is_empty(), "Procedural fighter needs silhouette accessories: " + fighter.character_id)

        var signature: String = ",".join(fighter.visual_profile.accessories)
        accessory_signatures[signature] = true

    check(procedural_count == 21, "Exactly 21 roster slots should use procedural shared-rig identity")
    check(accessory_signatures.size() >= 16, "Procedural roster should expose many distinct accessory silhouettes")

    var gaara: CharacterDefinition = CharacterCatalog.find("gaara")
    var temari: CharacterDefinition = CharacterCatalog.find("temari")
    var kisame: CharacterDefinition = CharacterCatalog.find("kisame")
    var kabuto: CharacterDefinition = CharacterCatalog.find("kabuto")
    var tenten: CharacterDefinition = CharacterCatalog.find("tenten")
    var itachi: CharacterDefinition = CharacterCatalog.find("itachi")

    check("gourd" in gaara.visual_profile.accessories, "Gaara needs gourd silhouette")
    check("fan" in temari.visual_profile.accessories, "Temari needs fan silhouette")
    check("sword_back" in kisame.visual_profile.accessories, "Kisame needs back sword silhouette")
    check("glasses" in kabuto.visual_profile.accessories, "Kabuto needs glasses silhouette")
    check("twin_buns" in tenten.visual_profile.accessories, "Tenten needs twin-bun silhouette")
    check("cloak" in itachi.visual_profile.accessories, "Itachi needs cloak silhouette")

    for fighter: CharacterDefinition in [gaara, temari, kisame, kabuto, tenten, itachi]:
        check(fighter.model_slot != null, "Procedural fighter needs final-model slot metadata: " + fighter.character_id)
        check(fighter.model_path == RosterModelSlotFactory.expected_path(fighter.character_id), "Preferred model path must be character-owned: " + fighter.character_id)
        check(fighter.model_fallback_path == RosterModelSlotFactory.SHARED_FALLBACK, "Procedural identity keeps one shared heavy fallback GLB: " + fighter.character_id)

    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("gaara", "temari", "training") == OK, "Procedural visual runtime battle opens")
    await frames(14)

    var arena: Node3D = current_scene
    var player: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    player.set_physics_process(false)
    cpu.set_physics_process(false)

    var player_adapter: Node3D = player.get_node("RiggedCharacterAdapter")
    var cpu_adapter: Node3D = cpu.get_node("RiggedCharacterAdapter")

    check(bool(player_adapter.get("rig_loaded")), "Gaara runtime rig loads")
    check(bool(cpu_adapter.get("rig_loaded")), "Temari runtime rig loads")
    check(bool(player_adapter.get("using_model_fallback")), "Gaara uses shared fallback until final GLB arrives")
    check(bool(cpu_adapter.get("using_model_fallback")), "Temari uses shared fallback until final GLB arrives")
    check(String(player_adapter.get("resolved_model_path")) == RosterModelSlotFactory.SHARED_FALLBACK, "Gaara resolves fallback path")
    check(String(cpu_adapter.get("resolved_model_path")) == RosterModelSlotFactory.SHARED_FALLBACK, "Temari resolves fallback path")

    var gaara_accessories: Array = player_adapter.get("roster_accessories")
    var temari_accessories: Array = cpu_adapter.get("roster_accessories")
    check(gaara_accessories.size() >= 2, "Gaara runtime creates procedural accessories")
    check(temari_accessories.size() >= 2, "Temari runtime creates procedural accessories")

    player_adapter.call("_sync_roster_accessories")
    cpu_adapter.call("_sync_roster_accessories")

    for entry_value: Variant in gaara_accessories:
        var entry: Dictionary = entry_value
        var node: MeshInstance3D = entry.get("node") as MeshInstance3D
        check(node != null and node.mesh != null, "Gaara accessory must own a lightweight primitive mesh")
        if node != null:
            check(node.global_position.length() < 1000.0, "Gaara accessory transform must stay finite")

    arena.queue_free()
    await frames(4)

    print("ROSTER VISUAL IDENTITY CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
