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
    var pending_flow: Node = root.get_node("GameFlow")
    while pending_flow.busy:
        await process_frame
    for _index: int in range(count):
        await physics_frame

func load_manifest() -> Dictionary:
    var file: FileAccess = FileAccess.open("res://assets/animations/combat_manifest.json", FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}

func run() -> void:
    CharacterCatalog.initialize()
    var manifest: Dictionary = load_manifest()
    var clips: Dictionary = manifest.get("clips", {})
    check(not clips.is_empty(), "Combat manifest must be readable")

    var archetypes: Dictionary = {}
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        check(fighter.ai_profile != null, "Every fighter needs a CPU identity: " + fighter.character_id)
        if fighter.ai_profile != null:
            check(fighter.ai_profile.evidence == "OUR_APPROXIMATION", "AI tuning must disclose approximation: " + fighter.character_id)
            check(fighter.ai_profile.preferred_distance > 0.0, "AI spacing must be positive: " + fighter.character_id)
            check(fighter.ai_profile.aggression >= 0.0 and fighter.ai_profile.aggression <= 1.0, "AI aggression range invalid: " + fighter.character_id)
            archetypes[fighter.ai_profile.archetype] = true

        for jutsu_id: String in fighter.jutsus:
            var jutsu: JutsuDefinition = fighter.find_jutsu(jutsu_id)
            check(jutsu != null, "Jutsu must resolve: " + fighter.character_id + "/" + jutsu_id)
            if jutsu != null:
                check(clips.has(jutsu.animation_name), "Jutsu choreography clip must exist: " + fighter.character_id + "/" + jutsu_id + " -> " + jutsu.animation_name)

        if fighter.character_id != "naruto":
            check(fighter.ultimate_definition != null, "Non-Naruto Ultimate data missing: " + fighter.character_id)
            if fighter.ultimate_definition != null:
                check(clips.has(fighter.ultimate_definition.entry_clip), "Ultimate entry clip must exist: " + fighter.character_id)
                check(clips.has(fighter.ultimate_definition.finisher_clip), "Ultimate finisher clip must exist: " + fighter.character_id)

    check(archetypes.size() >= 6, "Roster AI should expose all major archetypes")

    var gaara: CharacterDefinition = CharacterCatalog.find("gaara")
    var lee: CharacterDefinition = CharacterCatalog.find("rock_lee")
    var neji: CharacterDefinition = CharacterCatalog.find("neji")
    var temari: CharacterDefinition = CharacterCatalog.find("temari")
    var kiba: CharacterDefinition = CharacterCatalog.find("kiba")

    check(gaara.ai_profile.archetype == "zoner" and gaara.ai_profile.preferred_distance > 8.0, "Gaara CPU should control long range")
    check(lee.ai_profile.archetype == "rushdown" and lee.ai_profile.aggression > gaara.ai_profile.aggression, "Rock Lee CPU should pressure harder than Gaara")
    check(neji.ai_profile.guard_bias > lee.ai_profile.guard_bias, "Neji CPU should defend more often than Lee")
    check(temari.ai_profile.jutsu_bias > kiba.ai_profile.jutsu_bias, "Temari CPU should prefer jutsu more than Kiba")

    check(RosterVisualStyle.projectile_mesh("fire") is SphereMesh, "Fire style uses rounded projectile silhouette")
    check(RosterVisualStyle.projectile_mesh("wind") is CylinderMesh, "Wind style uses disc projectile silhouette")
    check(RosterVisualStyle.projectile_mesh("bone") is BoxMesh, "Bone style uses elongated projectile silhouette")

    check(RosterJutsuFactory.build("rock_lee").animation_name == "air_attack_2", "Lee primary special uses kick choreography")
    check(RosterJutsuFactory.build_secondary("gaara").animation_name == "attack_4", "Gaara burial uses heavy choreography")
    check(RosterJutsuFactory.build("neji").animation_name == "dodge", "Neji Rotation uses rotational body choreography")
    check(RosterJutsuFactory.build_secondary("shikamaru").animation_name == "attack_3", "Shikamaru secondary uses distinct choreography")

    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("rock_lee", "gaara", "training") == OK, "Identity runtime battle opens")
    await frames(12)

    var arena: Node3D = current_scene
    var player: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    var controls: Control = arena.get_node("HUD/MobileControls")

    player.set_physics_process(false)
    cpu.set_physics_process(false)
    cpu.enable_arsenal = false

    check(cpu.ai_profile != null and cpu.ai_profile.archetype == "zoner", "CPU receives selected Gaara AI profile")
    check(is_equal_approx(cpu.ai_profile.preferred_distance, gaara.ai_profile.preferred_distance), "Runtime CPU uses catalog spacing profile")
    check(Color(controls.get("character_accent")) == player.character_definition.energy_color, "Touch UI uses selected fighter accent")
    var clone_center: Vector2 = Vector2(controls.get("clone_center"))
    var barrage_center: Vector2 = Vector2(controls.get("barrage_center"))
    check(not bool(controls.get("clones_enabled")) and clone_center.x < 0.0 and barrage_center.x < 0.0, "Non-Naruto mobile layout removes clone-only buttons")

    cpu._decide_neutral(2.0)
    check(cpu.neutral_motion == "retreat", "Gaara CPU retreats when opponent breaches preferred range")

    var generic_awakening: Node3D = cpu.awakening
    var accent: MultiMeshInstance3D = generic_awakening.get("accent") as MultiMeshInstance3D
    check(accent != null, "Generic Awakening owns pooled accent VFX")
    generic_awakening.call("set_quality", 0)
    check(accent.multimesh.visible_instance_count == 4, "LOW limits Awakening accents")
    generic_awakening.call("set_quality", 2)
    check(accent.multimesh.visible_instance_count == 10, "HIGH restores Awakening accents")

    arena.queue_free()
    await frames(4)

    print("ROSTER IDENTITY CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
