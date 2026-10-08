extends SceneTree
var failures: int = 0
var checks: int = 0
var flow: Node

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
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)
    flow = root.get_node("GameFlow")
    flow.save_path = "user://world_contract_save.json"
    flow.progress = {"version": 1, "ryo": 0, "accepted": [], "completed": [], "collected": [], "supplies": 0, "position": [-21,0.95,-41], "yaw": PI}
    flow.save_writable = true
    check(flow.enter_world() == OK, "Battle entry point must open physical village")
    await scene_changed
    await frames(10)
    var village: Node3D = current_scene
    var actor: CharacterBody3D = village.get_node("Player")
    check(village.scene_file_path == "res://world.tscn" and actor.rig_adapter.rig_loaded, "World transition must finish with animated character")
    check(actor.global_position.distance_to(Vector3(0, 0.9, 42)) < 0.2, "Saved position inside geometry must recover at the gate")
    check(village.points.size() == 10, "All data-driven world points, including story/shop/travel, must instantiate")
    check(not flow.collect_scroll("roof_south", "roof_scrolls"), "Quest collection must require accepting the mission")
    actor.global_position = Vector3(-21,0.95,-30)
    await frames(6)
    village.interact()
    check(flow.progress.accepted.has("roof_scrolls"), "Instructor proximity interaction must accept mission")
    check(not flow.claim_collection("roof_scrolls") and flow.progress.ryo == 0, "Incomplete collection cannot award money")
    check(not flow.collect_scroll("invented", "roof_scrolls"), "Only configured collectibles may count")
    # Auto-collect through real Area3D overlaps, not direct distance delivery.
    for id: String in ["roof_south", "roof_academy", "roof_east"]:
        var point: Area3D = village.get_node(NodePath(id))
        actor.global_position = point.global_position
        actor.velocity = Vector3.ZERO
        await frames(12)
        check(flow.progress.collected.has(id) and not point.visible, "Physical scroll contact must collect and hide: " + id)
    check(not flow.collect_scroll("roof_south", "roof_scrolls"), "One scroll cannot count twice")
    actor.global_position = Vector3(-21,0.95,-30)
    actor.velocity = Vector3.ZERO
    await frames(6)
    village.interact()
    check(flow.progress.completed.has("roof_scrolls") and flow.progress.ryo == 150, "Turn-in must award configured reward once")
    village.interact()
    check(flow.progress.ryo == 150, "Repeated NPC dialogue cannot duplicate reward")
    # Obstruction prevents interaction through a building wall.
    actor.global_position = Vector3(-21,0.95,-30)
    actor.velocity = Vector3.ZERO
    var wall: StaticBody3D = StaticBody3D.new()
    var collision: CollisionShape3D = CollisionShape3D.new()
    var wall_shape: BoxShape3D = BoxShape3D.new()
    wall_shape.size = Vector3(3, 3, 0.2)
    collision.shape = wall_shape
    wall.add_child(collision)
    village.add_child(wall)
    wall.global_position = Vector3(-21, 1.5, -31)
    await frames(3)
    village.call("_find_interaction")
    check(village.nearest == null, "NPC interaction must be blocked by a wall within talking range")
    wall.queue_free()
    await frames(3)
    village.toggle_map()
    check(village.map_open and not actor.input_enabled, "Map must suspend movement without changing combat")
    village.toggle_map()
    check(not village.map_open and actor.input_enabled, "Closing map must restore exploration input")
    # Deliver real touch events: header GUI must not be swallowed by camera input.
    var controls: Control = village.get_node("HUD/WorldControls")
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var old_quality: int = village.quality
    var touch: InputEventScreenTouch = InputEventScreenTouch.new()
    touch.index = 11
    touch.position = village.quality_button.global_position + village.quality_button.size * 0.5
    touch.pressed = true
    Input.parse_input_event(touch)
    await frames(2)
    touch = touch.duplicate() as InputEventScreenTouch
    touch.pressed = false
    Input.parse_input_event(touch)
    await frames(2)
    check(village.quality == (old_quality + 1) % 3 and controls.camera_touch == -1, "Quality GUI touch must not reserve camera finger")
    village.apply_quality(0, false)
    check(not village.get_node("Sun").shadow_enabled and is_equal_approx(root.scaling_3d_scale, 0.62), "World LOW must apply Compatibility budgets")
    var npc_meshes: Array[MeshInstance3D] = []
    var npc: CharacterBody3D = village.get_node("academy_guide").actor
    npc.rig_adapter.call("_collect_mesh_instances", npc.rig_adapter.model_instance, npc_meshes)
    check(not npc_meshes.is_empty() and npc_meshes[0].visibility_range_end == 24.0, "LOW must cull distant NPC rendering without removing interactions")
    village.apply_quality(2, false)
    check(village.get_node("Geometry").sectors[0].visibility_range_end == 112, "HIGH cannot lose village sectors")
    check(flow.buy_supplies(40) and flow.progress.ryo == 110 and flow.progress.supplies == 1, "Shop must exchange actual currency for supplies")
    check(not flow.buy_supplies(0) and not flow.buy_supplies(1000), "Invalid or unaffordable purchases cannot change inventory")
    actor.global_position = Vector3(8,0.95,2.5)
    actor.velocity = Vector3.ZERO
    await frames(8)
    var return_position: Vector3 = actor.last_safe_position
    controls.interact_queue = 1
    await scene_changed
    await frames(8)
    var battle: Node3D = current_scene
    check(battle.scene_file_path == "res://main.tscn" and flow.pending_battle == "training", "World trainer must use the original battle scene")
    var fighter: Node = battle.get_node("Player")
    check(fighter.ninja_tools.stock.bomb == 3 and fighter.ninja_tools.stock.food_pills == 3 and flow.progress.supplies == 0, "Purchased supply must apply once to existing ninja tools")
    check(fighter.rig_adapter.real_animation_count == 27 and fighter.specials.projectiles.size() == 3, "Mission battle must retain rig and character projectile pools")
    battle.get_node("EnemyDummy").call("_knock_out")
    await frames(3)
    check(flow.battle_finished and flow.result_layer != null and battle.process_mode == Node.PROCESS_MODE_DISABLED, "CPU KO must open a result and stop active combat")
    check(flow.progress.completed.has("training") and flow.progress.ryo == 210, "First mission victory must award configured reward")
    check(not flow.finish_battle(true) and flow.progress.ryo == 210, "Duplicate KO must not duplicate reward")
    check(flow.enter_world() == OK, "Result must return to exploration")
    await scene_changed
    await frames(8)
    village = current_scene
    actor = village.get_node("Player")
    check(actor.global_position.distance_to(return_position) < 0.2, "Return must restore safe world position")
    check(flow.result_layer == null and flow.pending_battle.is_empty(), "Return must clear result overlay and pending encounter")
    check(root.get_child_count() == 3, "Scene transition must remove old sibling pools")
    flow.start_battle("training", actor.last_safe_position, actor.rotation.y)
    await scene_changed
    await frames(8)
    current_scene.get_node("Player").call("_defeat")
    await frames(3)
    check(flow.battle_finished and flow.progress.ryo == 210, "Player KO must return defeat without reward")
    check(flow.retry_battle() == OK, "Retry must reload the same battle framework")
    await scene_changed
    await frames(8)
    check(not flow.battle_finished and not current_scene.get_node("Player").defeated, "Retry must restore controls and fighter")
    current_scene.get_node("EnemyDummy").call("_knock_out")
    await frames(3)
    check(flow.progress.ryo == 210, "Replay victory cannot farm one-time quest reward")
    flow.enter_world()
    await scene_changed
    await frames(8)
    check(flow.save_progress() == OK, "World progress must save atomically")
    var saved: Dictionary = flow.progress.duplicate(true)
    flow.progress.ryo = 0
    check(flow.load_progress() and flow.progress.ryo == saved.ryo and flow.progress.collected.size() == 3, "Save reload must preserve completed quest and inventory")
    var file: FileAccess = FileAccess.open(flow.save_path, FileAccess.WRITE)
    file.store_string('{"version":999,"keep":"future"}')
    file.close()
    check(not flow.load_progress() and not flow.save_writable, "Future save format must be preserved")
    check(flow.save_progress() == ERR_UNAVAILABLE and FileAccess.get_file_as_string(flow.save_path).contains("future"), "Unknown saves cannot be overwritten by an old build")
    file = FileAccess.open(flow.save_path, FileAccess.WRITE)
    file.store_string('{"version":1,"accepted":[],"collected":[],"completed":[],"position":[0,1,2],"yaw":"invalid"}')
    file.close()
    check(not flow.load_progress(), "Malformed save types must fail without GDScript conversion errors")
    DirAccess.remove_absolute(flow.save_path)
    DirAccess.remove_absolute(flow.save_path + ".tmp")
    current_scene.queue_free()
    await frames(4)
    check(root.get_child_count() == 2 and root.get_node("GameFlow") == flow and root.has_node("GamePreferences"), "World exit must clean up every scene-owned node")
    print("WORLD FLOW CONTRACT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
    quit(1 if failures > 0 else 0)
