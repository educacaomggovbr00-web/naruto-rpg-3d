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
func silence(node: Node) -> void:
    if node.name == "EnemyDummy": node.process_mode = Node.PROCESS_MODE_DISABLED
func run() -> void:
    var visual: Node3D = Node3D.new()
    visual.set_script(load("res://scripts/elemental_jutsu_visual.gd"))
    root.add_child(visual)
    visual.set_physics_process(false)
    var second: Node3D = Node3D.new()
    second.set_script(load("res://scripts/elemental_jutsu_visual.gd"))
    root.add_child(second)
    second.set_physics_process(false)
    var techniques: Dictionary = {"fire_dragon":["fire","dragon",13],"earth_dragon":["earth","dragon",13],"snake_bind":["snake","snake",13],"puppet_strike":["puppet","puppet",10],"sand_coffin":["sand","sand_hand",11],"water_shark":["water","shark",3]}
    for id: String in techniques:
        var values: Array = techniques[id]
        var data: JutsuDefinition = JutsuDefinition.new()
        data.jutsu_id = id
        data.effect = values[0]
        visual.configure_jutsu(data,.5)
        second.configure_jutsu(data,.5)
        check(visual.construct.visible and not visual.core.visible,id+" uses articulated geometry")
        check(visual.construct.kind == values[1] and visual.construct.skeleton.get_bone_count() == values[2],id+" has complete expected skeleton")
        var animated_bone: int = 2 if values[1] == "sand_hand" else 1
        var initial: Quaternion = visual.construct.skeleton.get_bone_pose_rotation(animated_bone)
        var nodes: int = visual.construct.skeleton.get_child_count()
        visual.heading = Vector3.RIGHT
        visual.update_visual(.19)
        check(not initial.is_equal_approx(visual.construct.skeleton.get_bone_pose_rotation(animated_bone)),id+" has real animated joints")
        check(second.construct.skeleton.get_bone_pose_rotation(animated_bone).is_equal_approx(initial),id+" independent playback")
        for level: int in range(3):
            visual.set_quality(level)
            for step: int in range(30): visual.update_visual(.016)
            check(visual.construct.skeleton.get_child_count() == nodes,id+" bounded geometry at quality "+str(level))
            check(visual.construct.transform.is_finite(),id+" finite orientation")
        visual.configure_jutsu(data,.5)
        check(visual.construct.skeleton.get_bone_pose_rotation(animated_bone).is_equal_approx(initial),id+" resets on pool reuse")
        visual.configure("fire",.4)
        check(not visual.construct.visible and visual.core.visible,id+" releases model for ordinary fireball")
    visual.queue_free()
    second.queue_free()
    await frames(3)
    var flow: Node = root.get_node("GameFlow")
    flow.configure_teams(false,[],[])
    node_added.connect(silence)
    flow.start_versus("henrique","naruto","training")
    await frames(15)
    node_added.disconnect(silence)
    var player: Node3D = current_scene.get_node("Player")
    var enemy: Node3D = current_scene.get_node("EnemyDummy")
    current_scene.get_node("CombatFeedback").hit_stop_enabled = false
    player.chakra = 100
    player.stagger_timer = 0
    player.attack_cooldown = 0
    check(player.ultimate.start(),"Real Ultimate starts")
    check(not player.ultimate.presentation.active,"No cinematic presentation before confirmed hit")
    player.ultimate.entry_box.activate(player.ultimate,4.0,1.5,0.0,.75,.28)
    enemy.invulnerable_timer = 0
    enemy.is_guarding = false
    player.ultimate.entry_box.try_hit(enemy)
    check(player.ultimate.phase == "sequence" and player.ultimate.presentation.active,"Confirmed entry owns presentation")
    var hp: float = enemy.health
    player.ultimate.presentation.update_sequence(.5)
    check(enemy.health == hp,"Visual choreography cannot inflict damage")
    check(player.camera_rig.sequence_shot == "ultimate_sweep","Midpoint changes camera shot")
    player.ultimate.cancel("test")
    check(not player.ultimate.presentation.active and not player.ultimate.presentation.visible,"Cancel clears presentation")
    check(enemy.cinematic_owner == null and player.camera_rig.cinematic_remaining == 0,"Cancel clears target and camera locks")
    flow.enter_selection()
    await frames(8)
    print("JUTSU CONSTRUCT CONTRACT: "+("PASS" if failures == 0 else "FAIL")+" (%d checks)" % checks)
    quit(0 if failures == 0 else 1)
