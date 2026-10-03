extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for index: int in range(count):
        await physics_frame

func run() -> void:
    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("naruto", "naruto", "training") == OK, "Naruto match opens")
    await frames(8)
    var arena: Node3D = current_scene
    var fighter: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    fighter.set_physics_process(false)
    cpu.set_physics_process(false)
    for actor: CharacterBody3D in [fighter, cpu]:
        var adapter: Node3D = actor.rig_adapter
        check(adapter.sprite_mode, "Both Naruto fighters load the sprite")
        if not adapter.sprite_mode:
            continue
        check(not adapter.model_instance.visible, "No 3D mesh overlaps the sprite")
        check(adapter.real_animation_count == 27, "Bone timing remains available to combat")
        for key: String in adapter.SPRITE_LAYOUT:
            var frame: AtlasTexture = adapter.sprite_frames[key]
            var pixels: Image = frame.get_image()
            check(pixels != null and not pixels.is_empty(), "Texture imports: " + key)
            if pixels == null or pixels.is_empty():
                continue
            var bounds: Rect2i = pixels.get_used_rect()
            check(bounds.size.x > 20 and bounds.size.y > 20, "Complete nonempty pose: " + key)
            check(bounds.position.x >= 8 and bounds.end.x <= 184 and bounds.position.y >= 8 and bounds.end.y == 184, "No clipping and consistent foot baseline: " + key)
        var collision: CollisionShape3D = actor.get_node("CollisionShape3D")
        var foot_y: float = adapter.sprite_visual.position.y - 88.0 * adapter.sprite_visual.pixel_size
        check(is_equal_approx(foot_y, collision.position.y - collision.shape.height * 0.5), "Sprite feet meet physical floor")
        var camera: Camera3D = actor.get_viewport().get_camera_3d()
        var right: Vector3 = camera.global_basis.x
        actor.rotation.y = atan2(right.x, right.z)
        adapter._sync_sprite_state()
        check(not adapter.sprite_visual.flip_h, "Face screen right")
        actor.rotation.y += PI
        adapter._sync_sprite_state()
        check(adapter.sprite_visual.flip_h, "Facing updates without changing pose")
        for clone: Node3D in actor.specials.clones:
            check(clone.sprite_visual != null and not clone.model.visible, "Clones use sprites with independent combat rigs")
    fighter.combo_step = 3
    fighter.animation_state = "attack"
    fighter.attack_active = true
    fighter.rig_adapter._sync_sprite_state()
    check(fighter.rig_adapter.sprite_last_key == "attack_3", "Combat selects the combo pose")
    fighter.attack_active = false
    fighter.animation_state = "defeat"
    fighter.defeated = true
    fighter.rig_adapter._sync_sprite_state()
    check(fighter.rig_adapter.sprite_last_key == "defeat", "KO selects a visible defeat pose")
    check(flow.start_versus("sasuke", "sakura", "training") == OK, "Other characters remain playable")
    await frames(8)
    check(not current_scene.get_node("Player").rig_adapter.sprite_mode, "Sasuke retains the 3D model")
    check(current_scene.get_node("Player").rig_adapter.model_instance.visible, "3D fallback stays visible")
    print("SPRITE VISUAL CONTRACT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
    quit(0 if failures == 0 else 1)
