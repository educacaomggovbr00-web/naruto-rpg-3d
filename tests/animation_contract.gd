extends SceneTree

var failures: int = 0
var game: Node3D
var player: CharacterBody3D
var adapter: Node3D
var enemy: CharacterBody3D

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for i: int in range(count):
        await physics_frame

func _run() -> void:
    game = load("res://main.tscn").instantiate() as Node3D
    root.add_child(game)
    player = game.get_node("Player") as CharacterBody3D
    adapter = player.get_node("RiggedCharacterAdapter") as Node3D
    enemy = game.get_node("EnemyDummy") as CharacterBody3D
    enemy.set_physics_process(false)
    await frames(8)
    check(adapter.is_rig_loaded(), "Rig must load with real clips")
    check(adapter.real_animation_count == 22, "All 22 clips must be installed")
    check(adapter.right_hand_bone >= 0 and adapter.left_hand_bone >= 0, "Godot bone names must resolve")
    check(not adapter.animation_player.has_animation_library(&"proc"), "No procedural combat library")
    player.set_physics_process(false)
    adapter.set_physics_process(false)
    var library: AnimationLibrary = adapter.animation_player.get_animation_library(&"combat")
    var snapshots: Dictionary = {}
    var skeleton: Skeleton3D = adapter.skeleton
    for name: StringName in library.get_animation_list():
        var clip: Animation = library.get_animation(name)
        check(clip.get_track_count() == 130, "Every clip must cover 65 bones: " + String(name))
        check(clip.length > 0.0, "Clip must have duration")
        var moved: int = 0
        for track: int in range(clip.get_track_count()):
            var path: NodePath = clip.track_get_path(track)
            check(skeleton.find_bone(path.get_subname(0)) >= 0, "Unresolved animation target")
            if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
                var first: Quaternion = clip.track_get_key_value(track, 0)
                for key: int in range(clip.track_get_key_count(track)):
                    var q: Quaternion = clip.track_get_key_value(track, key)
                    check(is_finite(q.x) and absf(q.length() - 1.0) < 0.001, "Invalid quaternion")
                    if first.angle_to(q) > 0.01:
                        moved += 1
                        break
        check(moved > 8, "Clip must animate the whole body: " + String(name))
        # Evaluate through AnimationTree, not AnimationPlayer, at three points.
        var poses: Array = []
        for phase: float in [0.0, 0.45, 0.85]:
            adapter.playback.start(name, true)
            adapter.animation_tree.advance(0.0)
            adapter.animation_tree.advance(clip.length * phase)
            var pose: Dictionary = {}
            for i: int in range(skeleton.get_bone_count()):
                if String(skeleton.get_bone_name(i)).begins_with("mixamorig_"):
                    var transform: Transform3D = skeleton.get_bone_global_pose(i)
                    var q: Quaternion = transform.basis.orthonormalized().get_rotation_quaternion()
                    pose[String(skeleton.get_bone_name(i))] = {
                        "position": [transform.origin.x, transform.origin.y, transform.origin.z],
                        "rotation": [q.x, q.y, q.z, q.w]
                    }
            poses.append(pose)
        snapshots[String(name)] = poses
    if "--dump-poses" in OS.get_cmdline_user_args():
        var file: FileAccess = FileAccess.open("res://tests/animation_poses.json", FileAccess.WRITE)
        file.store_string(JSON.stringify(snapshots))
        print("POSES: ", ProjectSettings.globalize_path("res://tests/animation_poses.json"))
    # Actual controller/physics + animated bone hitbox integration.
    adapter.set_physics_process(true)
    player.set_physics_process(true)
    player.global_position = Vector3(0, 0.91, 0)
    player.rotation.y = 0.0
    enemy.global_position = Vector3(0, 0.96, 1.1)
    enemy.guarding = false
    enemy.health = 120.0
    await frames(4)
    for step: int in range(1, 5):
        player.invulnerable_timer = 2.0
        player.call("_try_attack")
        check(player.combo_step == step, "Combo step must progress")
        await frames(2)
        check(adapter.playback.get_current_node() == StringName("attack_%d" % step), "Tree must select exact attack")
        await frames(30)
    check(enemy.health < 100.0, "Real animated strikes must hit through bone hitboxes")
    check(enemy.velocity.y > 0.0, "Fourth strike must launch enemy")
    # Air combo selection and slam must also follow the actual strike hand.
    player.global_position = Vector3(0, 3.0, 0)
    player.combo_timer = 0.0
    player.combo_step = 0
    player.attack_cooldown = 0.0
    enemy.health = 120.0
    enemy.global_position = Vector3(0, 3.0, 1.1)
    enemy.velocity = Vector3.ZERO
    await frames(2)
    for step: int in range(1, 5):
        player.call("_try_attack")
        check(player.attack_is_airborne, "Aerial strike must remain airborne")
        await frames(2)
        check(adapter.playback.get_current_node() == StringName("air_attack_%d" % step), "Tree must select aerial strike")
        await frames(28)
    check(enemy.velocity.y < 0.0, "Fourth air strike must apply slam")
    # Interruptions must close the attack window immediately.
    player.attack_cooldown = 0.0
    player.call("_try_attack")
    player.attack_hitbox.call("activate", player, 7.0, 1.0, 0.0, 0.2)
    player.invulnerable_timer = 0.0
    player.receive_combat_hit(5.0, Vector3.FORWARD, 1.0, 0.0, 0.3)
    check(not player.attack_active and player.attack_hitbox.remaining_time == 0.0, "Hit must cancel strike")
    player.stagger_timer = 0.0
    player.attack_cooldown = 0.0
    player.call("_try_attack")
    player.call("_start_dodge")
    check(not player.attack_active, "Dodge must cancel strike")
    player.dodge_timer = 0.0
    player.attack_cooldown = 0.0
    player.call("_try_attack")
    player.call("_try_substitution")
    check(not player.attack_active, "Substitution must cancel strike")
    # Same-state attacks must restart instead of holding their last frame.
    player.stagger_timer = 0.0
    player.dodge_timer = 0.0
    player.attack_cooldown = 0.0
    player.combo_timer = 0.0
    player.call("_try_attack")
    await frames(2)
    player.call("_cancel_attack")
    player.combo_timer = 0.0
    player.attack_cooldown = 0.0
    player.call("_try_attack")
    await frames(2)
    check(adapter.playback.get_current_play_position() < 0.1, "Repeated strike must reset time")
    player.call("_cancel_attack")
    # Jutsu consumes resources immediately, applies damage only at release.
    player.global_position = Vector3(0, 0.91, 0)
    player.rotation.y = 0.0
    player.jutsu_cooldown = 0.0
    player.chakra = 100.0
    player.locked_target = enemy
    var health_before: float = enemy.health
    player.call("_try_jutsu")
    check(enemy.health == health_before, "Jutsu must not damage during startup")
    await frames(20)
    check(enemy.health < health_before, "Jutsu must damage at release")
    player.call("_defeat")
    await frames(3)
    check(adapter.playback.get_current_node() == &"defeat", "KO must use death clip")
    player.call("_respawn")
    await frames(3)
    check(adapter.playback.get_current_node() != &"defeat", "Respawn must leave KO")
    Engine.time_scale = 1.0
    print("ANIMATION CONTRACT: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
    game.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
