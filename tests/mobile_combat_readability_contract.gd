extends SceneTree

var failures: int = 0
var checks: int = 0

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
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)

    var flow: Node = root.get_node("GameFlow")
    flow.versus_mode = false
    flow.pending_battle = ""
    flow.pending_story_id = ""
    flow.world_region = "konoha"
    flow.return_message = "Teste de resultado"
    flow.call("_show_result", true)
    check(flow.result_layer != null, "Result overlay must build without typed Array assignment errors")
    flow.call("_clear_result")

    var battle: Node3D = load("res://main.tscn").instantiate() as Node3D
    root.add_child(battle)
    await frames(12)

    var player: CharacterBody3D = battle.get_node("Player") as CharacterBody3D
    var cpu: CharacterBody3D = battle.get_node("EnemyDummy") as CharacterBody3D
    var camera_rig: Node3D = player.get_node("CameraRig")
    var camera: Camera3D = player.get_node("CameraRig/SpringArm3D/Camera3D") as Camera3D
    var spring: SpringArm3D = player.get_node("CameraRig/SpringArm3D") as SpringArm3D
    var hud: CanvasLayer = battle.get_node("HUD") as CanvasLayer
    var feedback: Node3D = battle.get_node("CombatFeedback") as Node3D
    var manga_overlay: ColorRect = hud.get_node_or_null("MangaImpactOverlay") as ColorRect

    check(manga_overlay != null, "Combat HUD must include the manga impact overlay")
    if manga_overlay != null:
        check(not manga_overlay.visible, "Manga impact overlay must stay dormant outside impacts")
        feedback.call("spawn_impact", cpu.global_position + Vector3.UP, "slam")
        await frames(1)
        check(manga_overlay.visible, "Heavy combat impacts must activate the manga overlay")
        var manga_material: ShaderMaterial = manga_overlay.material as ShaderMaterial
        check(manga_material != null and float(manga_material.get_shader_parameter("impact")) > 0.20, "Heavy hits must drive visible manga impact strength")

    check(not cpu.get_node("HealthLabel").visible, "Enemy 3D health text must stay hidden during normal combat")
    check(hud.get("enemy_health_bar") != null, "HUD must expose a readable enemy health bar")
    check(hud.get("enemy_name_label") != null, "HUD must expose enemy name and numeric health")

    player.call("_toggle_lock_on")
    await frames(45)

    check(player.call("get_locked_target") == cpu, "Initial nearby CPU must be lockable")
    check(spring.spring_length <= 6.2, "Close-range lock camera must keep fighters visually large")
    check(camera.fov <= 68.0, "Combat camera must avoid excessive wide-angle framing")
    check(float(camera_rig.get("lock_max_distance")) <= 12.0, "Lock camera maximum distance must remain mobile-readable")

    var enemy_bar: ProgressBar = hud.get("enemy_health_bar") as ProgressBar
    check(enemy_bar.max_value >= float(cpu.max_health) - 0.01, "Enemy HUD bar must track CPU max health")
    cpu.health = cpu.max_health * 0.5
    await frames(8)
    check(absf(enemy_bar.value - cpu.health) < 1.0, "Enemy HUD bar must follow live CPU health")

    battle.queue_free()
    await frames(4)

    print("MOBILE COMBAT READABILITY: %s (%d checks, %d failures)" % [
        "PASS" if failures == 0 else "FAIL",
        checks,
        failures
    ])
    quit(1 if failures > 0 else 0)
