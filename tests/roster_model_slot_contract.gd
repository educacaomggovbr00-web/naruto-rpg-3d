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

    var slot_count: int = 0
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        if fighter.character_id in ["naruto", "sasuke", "sakura", "kakashi"]:
            continue

        slot_count += 1
        check(fighter.model_slot != null, "Shared-rig fighter needs model slot: " + fighter.character_id)
        if fighter.model_slot == null:
            continue

        check(fighter.model_path == RosterModelSlotFactory.expected_path(fighter.character_id), "Preferred path must be deterministic: " + fighter.character_id)
        check(fighter.model_fallback_path == RosterModelSlotFactory.SHARED_FALLBACK, "Fallback path must stay shared: " + fighter.character_id)
        check(fighter.model_slot.require_combat_bones, "Final model slot must require combat bones: " + fighter.character_id)
        check(fighter.model_slot.procedural_identity_on_fallback, "Procedural visual must only cover fallback state: " + fighter.character_id)

    check(slot_count == 21, "Exactly 21 fighters should wait on final model slots")

    var gaara: CharacterDefinition = CharacterCatalog.find("gaara")
    var original_preferred: String = gaara.model_path
    var original_fallback: String = gaara.model_fallback_path

    check(ResourceLoader.exists(original_fallback), "Shared fallback rig must exist")

    gaara.model_path = "res://assets/characters/final/__contract_missing__/never_mobile.glb"
    gaara.model_fallback_path = original_fallback
    var missing_preferred: String = gaara.model_path

    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("gaara", "temari", "training") == OK, "Missing-final fallback battle opens")
    await frames(14)

    var arena: Node3D = current_scene
    var player: CharacterBody3D = arena.get_node("Player")
    player.set_physics_process(false)
    var adapter: Node3D = player.get_node("RiggedCharacterAdapter")

    check(bool(adapter.get("rig_loaded")), "Missing final model must not break runtime")
    check(bool(adapter.get("using_model_fallback")), "Missing final model must activate fallback")
    check(String(adapter.get("requested_model_path")) == missing_preferred, "Adapter preserves requested final path for diagnostics")
    check(String(adapter.get("resolved_model_path")) == original_fallback, "Adapter resolves shared fallback")
    var attempts: PackedStringArray = adapter.get("model_attempt_log")
    check(attempts.size() >= 2, "Adapter records preferred and fallback attempts")
    check("ausente" in attempts[0], "Missing final model is recorded as absent")
    check("OK" in attempts[attempts.size() - 1], "Fallback success is recorded")

    arena.queue_free()
    await frames(4)

    # Existing but incompatible scene: tiny fixture intentionally has no Skeleton3D.
    gaara.model_path = "res://tests/fixtures/no_skeleton_model.tscn"
    gaara.model_fallback_path = original_fallback
    check(ResourceLoader.exists(gaara.model_path), "Tiny incompatible model fixture must exist for fallback test")

    check(flow.start_versus("gaara", "temari", "training") == OK, "Invalid-final fallback battle opens")
    await frames(14)

    arena = current_scene
    player = arena.get_node("Player")
    player.set_physics_process(false)
    adapter = player.get_node("RiggedCharacterAdapter")

    check(bool(adapter.get("rig_loaded")), "Invalid existing final model must not break runtime")
    check(bool(adapter.get("using_model_fallback")), "Invalid existing final model must fall back")
    check(String(adapter.get("resolved_model_path")) == original_fallback, "Invalid primary resolves shared fallback")
    attempts = adapter.get("model_attempt_log")
    check(attempts.size() >= 2, "Invalid primary and fallback both appear in diagnostics")
    check("Skeleton3D ausente" in attempts[0], "Invalid model fixture is rejected for missing skeleton")
    check("OK" in attempts[attempts.size() - 1], "Fallback succeeds after incompatible primary")
    var fallback_accessories: Array = adapter.get("roster_accessories")
    check(fallback_accessories.size() > 0, "Procedural identity remains active only on fallback")

    arena.queue_free()
    await frames(4)

    gaara.model_path = original_preferred
    gaara.model_fallback_path = original_fallback

    print("ROSTER MODEL SLOT CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
