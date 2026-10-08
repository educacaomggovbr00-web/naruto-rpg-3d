extends SceneTree
func _initialize(): call_deferred("run")
func run():
    CharacterCatalog.initialize()
    DirAccess.make_dir_recursive_absolute("res://assets/ui/portraits")
    var viewport = SubViewport.new()
    viewport.size = Vector2i(256,256)
    viewport.own_world_3d = true
    viewport.msaa_3d = Viewport.MSAA_4X
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var stage = Node3D.new()
    viewport.add_child(stage)
    var environment = WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("123446")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color.WHITE
    environment.environment.ambient_light_energy = .65
    stage.add_child(environment)
    var key = DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-22,-24,0)
    key.light_energy = 1.2
    stage.add_child(key)
    var camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = .7
    stage.add_child(camera)
    for definition in CharacterCatalog.READY:
        var actor = CharacterBody3D.new()
        actor.set_script(load("res://scripts/ui/fighter_preview_actor.gd"))
        actor.definition = definition
        stage.add_child(actor)
        actor.rig_adapter.set_physics_process(false)
        actor.rig_adapter.animation_tree.active = false
        actor.rig_adapter.animation_player.stop()
        actor.rig_adapter.skeleton.reset_bone_poses()
        for index in range(2): await process_frame
        var adapter = actor.rig_adapter
        var head = adapter.skeleton.global_transform * adapter.skeleton.get_bone_global_pose(adapter._find_mixamo_bone("Head")).origin
        camera.size = .85 if definition.character_id == "henrique" else .52
        camera.position = head + Vector3(0,.08,1.5)
        camera.look_at(head + Vector3(0,.08,0))
        for index in range(2): await process_frame
        await RenderingServer.frame_post_draw
        viewport.get_texture().get_image().save_png("res://assets/ui/portraits/" + definition.character_id + ".png")
        print("PORTRAIT: "+definition.character_id)
        actor.queue_free()
        await process_frame
    viewport.queue_free()
    await process_frame
    quit()
