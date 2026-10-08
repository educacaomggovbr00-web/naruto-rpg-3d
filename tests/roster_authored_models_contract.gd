extends SceneTree
var failures := 0
var checks := 0
func _initialize():
    call_deferred("run")
func check(ok: bool, message: String):
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func run():
    CharacterCatalog.initialize()
    var count := 0
    var paths := {}
    for definition in CharacterCatalog.READY:
        if definition.character_id in ["naruto", "sasuke", "sakura", "kakashi", "henrique"]: continue
        var actor = CharacterBody3D.new()
        actor.set_script(load("res://scripts/ui/fighter_preview_actor.gd"))
        actor.definition = definition
        root.add_child(actor)
        var adapter = actor.rig_adapter
        check(adapter.rig_loaded, definition.character_id + " must load skin")
        check(not adapter.using_model_fallback, definition.character_id + " must use own model")
        check(adapter.resolved_model_path == definition.model_path, "Dedicated path")
        check(adapter.skeleton.get_bone_count() == 65, "Complete skeleton")
        check(adapter.available_animations.size() >= 127, "Existing combat library preserved")
        check(adapter.roster_accessories.is_empty(), "No duplicate fallback accessories")
        check(adapter.detected_source_height > 150 and adapter.detected_source_height < 220, "Human body bounds")
        check(adapter.applied_model_scale > .007 and adapter.applied_model_scale < .014, "Finite normal scale")
        for side in ["Left", "Right"]:
            check(adapter._find_mixamo_bone(side + "HandIndex3") >= 0, "Articulated fingers")
        for clip in ["idle", "run", "attack_1", "jump", "hit"]:
            actor.preview_animation(clip)
            adapter.animation_tree.advance(.15)
            var hand = adapter.skeleton.get_bone_global_pose(adapter.right_hand_bone).origin
            check(hand.is_finite() and hand.length() < 500, "Stable animated hand: " + clip)
        paths[adapter.resolved_model_path] = true
        count += 1
        actor.queue_free()
        await process_frame
    check(count == 21 and paths.size() == 21, "Twenty-one independent models")
    print("ROSTER AUTHORED MODELS CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
