extends SceneTree
var failures: int = 0
var checks: int = 0
var village: Node3D
var actor: CharacterBody3D
var controls: Control

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for i: int in range(count):
        await physics_frame

func run() -> void:
    village = load("res://world.tscn").instantiate() as Node3D
    root.add_child(village)
    actor = village.get_node("Player")
    controls = village.get_node("HUD/WorldControls")
    await frames(10)
    var geometry: Node3D = village.get_node("Geometry")
    check(geometry.sectors.size() <= 65 and geometry.sectors.size() > 20, "Village must merge meshes in bounded sectors")
    check(geometry.triangles < 16000 and geometry.triangles > 1000, "Original environment geometry must remain mobile-sized")
    check(geometry.collision_count > 50, "Buildings, stairs and roof terraces need real collision")
    check(actor.rig_adapter.rig_loaded and actor.rig_adapter.real_animation_count == 27, "Exploration must preserve the existing real clips and rig")
    check(actor.is_on_floor(), "Village spawn must be on a physical street")
    check(actor.get_node("AttackHitbox").collision_mask == 0, "Exploration cannot enable combat hitboxes")
    check(actor.get_node("WorldCamera/SpringArm3D").shape is SphereShape3D, "World camera must use volume collision")
    var start: Vector3 = actor.global_position
    controls.move_vector = Vector2(0, -1)
    await frames(35)
    controls.move_vector = Vector2.ZERO
    check(actor.global_position.z < start.z - 3.0, "Touch stick must physically traverse the avenue")
    check(actor.rig_adapter.current_state in ["run", "sprint"], "World movement must play actual locomotion animation")
    await frames(12)
    controls.jump_queue = 1
    await frames(8)
    check(actor.global_position.y > 1.4 and not actor.is_on_floor(), "Jump must leave physical ground")
    controls.jump_queue = 1
    await frames(3)
    check(actor.air_jumps == 1 and actor.velocity.y > 0.0, "Exploration must allow one bounded air jump")
    controls.jump_queue = 1
    await frames(2)
    check(actor.air_jumps == 1 and controls.jump_queue == 0, "Repeated touch cannot create infinite jumps")
    await frames(90)
    check(actor.is_on_floor() and actor.air_jumps == 0, "Landing must restore exploration jump budget")
    # Walk the full access ramp; visual stairs must not trap a capsule on risers.
    actor.global_position = Vector3(-31, 0.95, 49)
    actor.velocity = Vector3.ZERO
    actor.camera_rig.yaw = 0.0
    await frames(4)
    controls.move_vector = Vector2(0, -0.8)
    await frames(150)
    controls.move_vector = Vector2.ZERO
    await frames(8)
    check(actor.global_position.y > 4.2 and actor.is_on_floor(), "Touch movement must climb stairs onto the south roof access")
    check(actor.global_position.z < 36.6, "Roof access cannot stall against visible step risers")
    # Roof collision exists at the documented collection terrace.
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(-25, 12, 31), Vector3(-25, 0, 31), 1)
    var roof: Dictionary = village.get_world_3d().direct_space_state.intersect_ray(query)
    check(not roof.is_empty() and float(roof.position.y) > 3.0, "Rooftop route must have actual walkable geometry")
    geometry.set_quality(0)
    check(geometry.sectors[0].visibility_range_end == 70.0, "LOW must limit sector render distance")
    geometry.set_quality(2)
    check(geometry.sectors[0].visibility_range_end == 130.0, "HIGH must restore sector render distance")
    check(geometry.collision_count > 50, "Quality culling cannot remove traversal collision")
    controls.joystick_touch = 2
    controls.sprint_touch = 3
    controls.camera_touch = 4
    controls.move_vector = Vector2.ONE
    controls.camera_delta = Vector2.ONE
    controls.interact_queue = 1
    controls.call("_notification", Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(controls.joystick_touch == -1 and controls.sprint_touch == -1 and controls.camera_touch == -1 and controls.move_vector == Vector2.ZERO and controls.interact_queue == 0, "Focus loss must release every exploration touch")
    if "--dump-world" in OS.get_cmdline_user_args():
        var output: Array[Dictionary] = []
        for sector: MeshInstance3D in geometry.sectors:
            var arrays: Array = sector.mesh.surface_get_arrays(0)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
            var points: Array = []
            var shades: Array = []
            for i: int in range(vertices.size()):
                var p: Vector3 = sector.global_transform * vertices[i]
                points.append([p.x, p.y, p.z])
                shades.append([colors[i].r, colors[i].g, colors[i].b])
            output.append({"vertices": points, "colors": shades})
        var file: FileAccess = FileAccess.open("res://tests/world_geometry.json", FileAccess.WRITE)
        file.store_string(JSON.stringify(output))
        print("WORLD DUMP: ", ProjectSettings.globalize_path("res://tests/world_geometry.json"))
    village.queue_free()
    await frames(3)
    check(root.get_child_count() == 1 and root.get_child(0).name == "GameFlow", "Leaving exploration must clean up rig and world nodes")
    print("WORLD CONTRACT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
    quit(1 if failures > 0 else 0)
