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
    for _i: int in range(count):
        await physics_frame

func _has_named_child(root_node: Node, prefix: String) -> bool:
    for child: Node in root_node.get_children():
        if child.name.begins_with(prefix):
            return true
    return false

func run() -> void:
    for path: String in [
        "res://assets/vendor/quaternius_japan/torii.gltf",
        "res://assets/vendor/quaternius_japan/temple_small.gltf",
        "res://assets/vendor/quaternius_japan/temple.gltf",
        "res://assets/vendor/quaternius_japan/shrine.gltf"
    ]:
        check(ResourceLoader.exists(path), "CC0 Japanese architecture must ship: " + path)

    var battle: Node3D = load("res://main.tscn").instantiate() as Node3D
    root.add_child(battle)
    await frames(12)

    var presentation: Node = battle.get_node("ArenaPresentation")
    var scenery: Node = presentation.get_node_or_null("LicensedScenery")
    check(scenery != null, "Battle arena must instantiate licensed scenery")
    if scenery != null:
        check(_has_named_child(scenery, "Japan_torii_"), "Battle arena must show the CC0 torii")
        check(_has_named_child(scenery, "Japan_temple_"), "Battle arena must show the CC0 temple")
        check(_has_named_child(scenery, "Japan_shrine_"), "Battle arena must show the CC0 shrine")

    var camera: Camera3D = battle.get_node("Player/CameraRig/SpringArm3D/Camera3D") as Camera3D
    var spring: SpringArm3D = battle.get_node("Player/CameraRig/SpringArm3D") as SpringArm3D
    check(camera.fov <= 60.5, "Battle camera must keep fighters large on phone screens")
    check(spring.spring_length <= 4.5, "Battle camera base distance must stay close")

    var env_node: WorldEnvironment = presentation.get_node_or_null("ArenaEnvironment") as WorldEnvironment
    check(env_node != null and env_node.environment.adjustment_enabled, "Anime color grading must be enabled")
    if env_node != null:
        check(env_node.environment.adjustment_contrast >= 1.08, "Anime presentation must keep stronger contrast")
        check(env_node.environment.adjustment_saturation >= 1.10, "Anime presentation must keep stronger saturation")

    battle.queue_free()
    await frames(4)

    var world: Node3D = load("res://world.tscn").instantiate() as Node3D
    root.add_child(world)
    await frames(10)
    var world_scenery: Node = world.get_node_or_null("Geometry/LicensedScenery")
    check(world_scenery != null, "Village must instantiate licensed scenery")
    if world_scenery != null:
        check(_has_named_child(world_scenery, "Japan_torii_"), "Village entrance must use the real torii model")
        check(_has_named_child(world_scenery, "Japan_shrine_"), "Village must include the CC0 shrine model")
    world.queue_free()
    await frames(3)

    print("VISUAL OVERHAUL CONTRACT: %s (%d checks, %d failures)" % [
        "PASS" if failures == 0 else "FAIL",
        checks,
        failures
    ])
    quit(1 if failures > 0 else 0)
