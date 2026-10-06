extends SceneTree

var failures: int = 0
var checks: int = 0
var game: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D
var player_state: Node
var enemy_state: Node

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for _index: int in range(count):
        await physics_frame

func run() -> void:
    game = load("res://main.tscn").instantiate() as Node3D
    root.add_child(game)
    player = game.get_node("Player") as CharacterBody3D
    enemy = game.get_node("EnemyDummy") as CharacterBody3D
    await frames(8)

    player_state = player.get_node_or_null("CombatStateMachine")
    enemy_state = enemy.get_node_or_null("CombatStateMachine")

    check(player_state != null, "Player must own CombatStateMachine")
    check(enemy_state != null, "CPU must own CombatStateMachine")
    if player_state == null or enemy_state == null:
        finish()
        return

    check(
        player_state.get_script().resource_path == enemy_state.get_script().resource_path,
        "Player and CPU must use the same state rules"
    )

    player_state.call("clear_transient")
    player_state.call("mark_hit", 2.0, 0.0, 0.24, false, false)
    check(player_state.call("get_state") == "hit_light", "Light hit must get its own logical state")
    check(player_state.call("get_visual_state") == "hit", "Light hit must reuse the hit clip")
    check(not bool(player_state.call("allows_action", "movement")), "Hit reaction must block movement")
    check(bool(player_state.call("allows_action", "substitution")), "Substitution must remain a defensive escape")

    player_state.call("clear_transient")
    player_state.call("mark_hit", 3.0, 8.5, 0.28, false, false)
    check(player_state.call("get_state") == "launcher", "Positive launch must classify as launcher")
    check(player_state.call("get_visual_state") == "knockback", "Launcher must reuse knockback animation")
    check(bool(player_state.get("recovery_pending")), "Launcher must arm ground recovery")

    player_state.call("clear_transient")
    player_state.call("mark_hit", 4.0, -13.0, 0.32, false, false)
    check(player_state.call("get_state") == "slam", "Negative launch must classify as slam")
    check(bool(player_state.get("recovery_pending")), "Slam must arm recovery")

    player_state.call("clear_transient")
    player_state.call("mark_hit", 8.0, 0.0, 0.32, false, false)
    check(player_state.call("get_state") == "knockdown", "Heavy knockback must classify as knockdown")

    player_state.call("clear_transient")
    player_state.call("mark_substitution")
    check(player_state.call("get_state") == "substitution", "Substitution needs a dedicated transient state")
    check(player_state.call("get_visual_state") == "dodge", "Substitution must reuse the lightweight dodge clip")

    player_state.call("clear_transient")
    player_state.call("mark_special_phase", "rasengan_startup", 0.20)
    check(player_state.call("get_state") == "rasengan_startup", "Rasengan startup must be explicit")
    check(player_state.call("get_visual_state") == "jutsu", "Rasengan startup must route to the jutsu adapter")
    player_state.call("mark_special_phase", "rasengan_drive", 0.20)
    var drive_profile: Dictionary = player_state.call("camera_profile") as Dictionary
    check(float(drive_profile.get("fov_offset", 0.0)) > 0.0, "Rasengan drive must widen the camera")
    player_state.call("mark_special_phase", "rasengan_impact", 0.18)
    var impact_profile: Dictionary = player_state.call("camera_profile") as Dictionary
    check(float(impact_profile.get("fov_offset", 0.0)) < 0.0, "Rasengan impact must punch the camera inward")

    player_state.call("clear_transient")
    player_state.call("mark_dash_confirm", false)
    check(player_state.call("get_state") == "dash_confirm", "Dash collision must expose a confirm state")
    check(bool(player_state.call("allows_action", "attack")), "Dash confirm must allow attack continuation")

    enemy_state.call("clear_transient")
    enemy_state.call("mark_hit", 3.0, 8.5, 0.28, false, false)
    check(enemy.call("get_combat_state") == "launcher", "CPU must expose the same launcher state")
    check(enemy.call("get_animation_state") == "knockback", "CPU launcher must map to a supported visual clip")

    check(player.has_method("get_camera_state_profile"), "Player must expose camera-state profile")
    check(player.get_node("CameraRig") != null, "Combat camera must remain attached")

    finish()

func finish() -> void:
    print("COMBAT STATE MACHINE: %s (%d checks, %d failures)" % [
        "PASS" if failures == 0 else "FAIL",
        checks,
        failures
    ])
    quit(1 if failures > 0 else 0)
