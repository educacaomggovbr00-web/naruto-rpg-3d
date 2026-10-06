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
func frames() -> void:
    for i: int in range(12):
        await physics_frame
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await frames()
    var arena: Node = current_scene
    var scenery: Node = arena.get_node("ArenaPresentation/LicensedScenery")
    check(scenery.instance_total == 35, "Arena contains licensed vegetation plus visible Fantasy Town props")
    check(scenery.props.size() == 11, "Arena instantiates all selected CC0 town props")
    check(scenery.batches.size() <= 32, "Arena vegetation uses bounded sector batches")
    var fighter: Node = arena.get_node("Player")
    check(fighter.rig_adapter.real_animation_count == 27, "Player's 27 combat clips survive asset integration")
    var tool: Node = fighter.ninja_tools.projectiles[0]
    check(tool.shuriken.get_child_count() == 1 and tool.kunai.get_child_count() == 1, "Pooled tools use one imported mesh each")
    check(tool.shuriken.get_child(0).mesh == preload("res://assets/vendor/mehrasaur_weapons/shaken-juji.obj"), "Shuriken uses the licensed pack")
    check(tool.sweep_shape.radius > 0.0, "Projectile retains physical swept collision")
    var feedback: Node = arena.get_node("CombatFeedback")
    feedback.spawn_substitution(Vector3.ZERO)
    var material: StandardMaterial3D = feedback.flashes[0].mesh.material
    check(material.albedo_texture == preload("res://assets/vendor/kenney_particles/smoke_01.png"), "Substitution renders actual smoke texture")
    check(material.billboard_mode == BaseMaterial3D.BILLBOARD_ENABLED and not material.no_depth_test, "Effects face camera and respect scene depth")
    for level: int in [0, 1, 2]:
        arena.get_node("MobileQuality").apply(level, false)
        check(scenery.batches[0].visibility_range_end == [48.0, 78.0, 112.0][level], "Vegetation respects all mobile quality levels")
        check(feedback.effect_budget == [8, 16, 28][level], "Texture effects retain bounded quality pool")
    change_scene_to_file("res://world.tscn")
    await frames()
    var village: Node = current_scene
    var village_scenery: Node = village.get_node("Geometry/LicensedScenery")
    check(village_scenery.instance_total == 37, "Village contains licensed vegetation plus CC0 street props")
    check(village_scenery.props.size() == 19, "Village instantiates gates, stalls, carts, benches, lanterns and banners")
    var npc: Node = village.get_node("academy_guide").actor
    check(npc.rig_adapter.rig_loaded, "Licensed ninja NPC imports its own rig")
    check(npc.rig_adapter.animation_player.is_playing(), "Ninja NPC plays native animation")
    npc.rig_adapter.set_active(false)
    check(not npc.rig_adapter.animation_player.active, "Distant NPC skeleton evaluation can pause")
    npc.rig_adapter.set_active(true)
    check(npc.rig_adapter.animation_player.active, "Nearby NPC native animation resumes")
    var meshes: Array[MeshInstance3D] = []
    npc.rig_adapter._collect_mesh_instances(npc.rig_adapter.model_instance, meshes)
    check(not meshes.is_empty(), "Licensed NPC has visible 3D mesh")
    if not meshes.is_empty():
        var posed_bounds: AABB = npc.rig_adapter.posed_mesh_bounds(meshes[0])
        var world_bounds: AABB = npc.rig_adapter.model_instance.global_transform * posed_bounds
        check(absf(world_bounds.position.y - npc.global_position.y) < 0.15, "Native idle skin stays grounded rather than using bind-pose AABB")
        var npc_material: StandardMaterial3D = meshes[0].get_surface_override_material(0)
        check(npc_material.next_pass == null, "Scaled FBX ninja avoids fragmented outline hull and extra draw pass")
    village.apply_quality(0, false)
    check(meshes[0].visibility_range_end == 24.0, "NPC render culling preserves interaction")
    check(village.get_node("Player").rig_adapter.real_animation_count == 27, "Exploration retains player combat rig")
    current_scene.queue_free()
    await frames()
    print("LICENSED GAMEPLAY ASSETS: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
