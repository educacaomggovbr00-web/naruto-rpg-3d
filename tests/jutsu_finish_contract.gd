extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int) -> void:
    while root.get_node("GameFlow").busy: await process_frame
    for index: int in range(count):
        await physics_frame
        await process_frame
func silence_cpu(node: Node) -> void:
    if node.name == "EnemyDummy": node.process_mode = Node.PROCESS_MODE_DISABLED
func run() -> void:
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1280,720)
    var visual: Node3D = Node3D.new()
    visual.set_script(load("res://scripts/elemental_jutsu_visual.gd"))
    root.add_child(visual)
    visual.set_physics_process(false)
    var impact: Node3D = Node3D.new()
    impact.set_script(load("res://scripts/jutsu_impact.gd"))
    root.add_child(impact)
    impact.set_process(false)
    var base_nodes: int = visual.get_child_count()
    for kind: String in RosterVisualStyle.EFFECTS:
        visual.configure(kind,.6)
        visual.heading = Vector3.RIGHT
        visual.update_visual(.12)
        check(visual.core.scale.is_finite() and visual.tail_tip.is_finite(),kind+" finite core and trail")
        check(visual.get_child_count() == base_nodes,kind+" reuses preallocated geometry")
        for ribbon: MeshInstance3D in visual.ribbons:
            check(ribbon.transform.is_finite(),kind+" ribbon follows finite heading")
        impact.activate(Vector3(0,.9,0),kind,.8,Vector3.RIGHT)
        impact.update_visual(.12)
        check(impact.active and impact.shell.scale.is_finite(),kind+" owns persistent impact")
        impact.update_visual(1.0)
        check(not impact.active and not impact.visible,kind+" impact expires")
    for definition: CharacterDefinition in CharacterCatalog.READY:
        for id: String in definition.jutsus:
            var data: JutsuDefinition = definition.find_jutsu(id)
            var tuning: Array = [data.damage,data.chakra_cost,data.cooldown,data.hitbox_radius,data.strategy]
            visual.configure_jutsu(data,.4,data.strategy == "burst")
            visual.update_visual(.1)
            check(visual.technique_id == id and tuning == [data.damage,data.chakra_cost,data.cooldown,data.hitbox_radius,data.strategy],definition.character_id+" visual preserves technique tuning")
    visual.configure("wind",.6)
    check(visual.core.mesh is ArrayMesh and visual.profile == "crescent","Wind uses an authored arc instead of an orb")
    visual.configure("steel",.6)
    check(visual.weapons.visible and visual.weapons.get_child_count() == 3 and not visual.core.visible,"Steel renders actual weapon meshes")
    visual.heading = Vector3.ZERO
    visual.update_visual(.1)
    check(visual.weapons.transform.is_finite(),"Zero heading keeps weapon presentation finite")
    visual.configure("fire",.6)
    check(not visual.weapons.visible and visual.profile == "flame","Pool reuse clears weapon presentation")
    for kind: String in ["fire","black_fire","water"]:
        visual.configure(kind,.2)
        visual.heading = Vector3.RIGHT
        visual.update_visual(.1)
        check(visual.core.scale.length() < .5,kind+" heading rotation preserves the authored small radius")
    for level: int in range(3):
        visual.set_quality(level)
        visual.update_visual(0.0)
        impact.set_quality(level)
        check(impact.sparks.multimesh.visible_instance_count == [8,16,24][level],"Quality bounds instanced impact fragments")
        check(impact.smoke.multimesh.visible_instance_count == [2,4,6][level],"Quality bounds smoke layers")
        check(visual.ribbons[0].visible and visual.ribbons[1].visible == (level>0),"Quality bounds translucent flame layers")
    impact.activate(Vector3.ZERO,"water",.7,Vector3.BACK)
    impact.update_visual(.4)
    impact.activate(Vector3.ZERO,"lightning",.5,Vector3.RIGHT)
    check(is_zero_approx(impact.clock) and impact.scale == Vector3.ONE and impact.kind == "lightning","Impact reuse clears timing, scale and family")
    visual.queue_free()
    impact.queue_free()
    node_added.connect(silence_cpu)
    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("henrique","naruto","training") == OK,"Polished battle opens")
    await frames(12)
    node_added.disconnect(silence_cpu)
    var scene: Node = current_scene
    var player: CharacterBody3D = scene.get_node("Player")
    var enemy: CharacterBody3D = scene.get_node("EnemyDummy")
    player.set_physics_process(false)
    scene.get_node("BattleBridge").set_physics_process(false)
    player.global_position = Vector3(0,1,2)
    enemy.global_position = Vector3(0,1,-2)
    player.locked_target = enemy
    var feedback: Node = scene.get_node("CombatFeedback")
    var feedback_nodes: int = feedback.get_child_count()
    for level: int in range(3):
        scene.get_node("MobileQuality").apply(level,false)
        for index: int in range(20):
            feedback.spawn_elemental_impact(enemy.global_position,"fire",.7,Vector3.BACK)
        check(feedback.elemental_impacts.filter(func(node: Node3D) -> bool: return node.active).size() <= [2,4,6][level],"Repeated hits cannot exceed active impact budget")
        check(feedback.get_child_count() == feedback_nodes,"Repeated hits never allocate effect nodes")
    player.jutsu_cooldown = 0.0
    player.stagger_timer = 0.0
    player.invulnerable_timer = 0.0
    player.chakra = player.max_chakra
    check(player.specials.start("henrique_chidori"),"Close hand technique starts")
    check(player.specials.owns_camera and player.camera_rig.sequence_shot == "jutsu","Close technique has short preparation framing")
    player.specials.cancel()
    check(not player.specials.owns_camera and player.camera_rig.cinematic_remaining == 0.0,"Interruption immediately releases camera")
    scene.get_node("HUD")._process(.2)
    check(not scene.get_node("HUD/Status").text.contains("EnemyDummy") and not scene.get_node("HUD/Status").text.contains("IDLE"),"Player HUD hides internal actor/state names")
    check(scene.get_node("HUD/Resources").text.contains("GUARDA"),"Compact HUD retains useful resources")
    if DisplayServer.get_name() != "headless":
        await frames(3)
        await RenderingServer.frame_post_draw
    current_scene.queue_free()
    await frames(4)
    print("JUTSU FINISH CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL",checks])
    quit(0 if failures == 0 else 1)
