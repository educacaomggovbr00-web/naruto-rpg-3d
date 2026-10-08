extends SceneTree
var checks: int = 0
var failures: int = 0
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
    var total: int = 0
    var specific: int = 0
    for hero: CharacterDefinition in CharacterCatalog.READY:
        for id: String in hero.jutsus:
            var data: JutsuDefinition = hero.find_jutsu(id)
            var tuning: Array = [data.damage,data.chakra_cost,data.cooldown,data.hitbox_radius,data.strategy,data.animation_name]
            visual.configure_jutsu(data,.6,data.strategy == "burst")
            var signature: Node3D = visual.signature
            var node_count: int = signature.get_child_count()
            var mesh: Mesh = signature.particles.multimesh.mesh
            check(signature.technique_id == id and not signature.pattern.is_empty(),id+" owns a signature")
            if signature.PATTERNS.has(id): specific += 1
            for level: int in range(3):
                visual.set_quality(level)
                visual.heading = Vector3.ZERO if level == 0 else Vector3.RIGHT
                visual.update_visual(.045)
                check(signature.particles.multimesh.visible_instance_count == [8,16,24][level],id+" quality budget")
                check(signature.get_child_count() == node_count and signature.particles.multimesh.mesh == mesh,id+" no per-frame geometry allocation")
                for index: int in range(signature.particles.multimesh.visible_instance_count):
                    check(signature.particles.multimesh.get_instance_transform(index).is_finite(),id+" finite particle")
            check(tuning == [data.damage,data.chakra_cost,data.cooldown,data.hitbox_radius,data.strategy,data.animation_name],id+" preserves gameplay tuning")
            visual.configure_jutsu(data,.6,data.strategy == "burst")
            check(is_zero_approx(signature.clock),id+" resets on reuse")
            if data.strategy == "burst":
                visual.update_visual(.5)
                check(not visual.visible and not signature.visible,id+" expires during recovery")
            total += 1
    check(total >= 50 and specific >= 25,"Entire roster and technique-specific patterns are covered")
    var shadow: JutsuDefinition = JutsuDefinition.new()
    shadow.jutsu_id = "shadow_bind"
    shadow.effect = "shadow"
    visual.position = Vector3(0,1.5,0)
    visual.scale = Vector3.ONE*.4
    visual.configure_jutsu(shadow,.5)
    visual.scale = Vector3.ONE*.4
    visual.update_visual(.1)
    var local: Vector3 = visual.signature.particles.multimesh.get_instance_transform(0).origin
    # Dummy rendering server does not retain MultiMesh transforms. Verify actual
    # rendered transforms only in OpenGL, not an implementation mirror.
    if DisplayServer.get_name() != "headless":
        check(is_equal_approx(visual.signature.to_global(local).y,.035),"Shadow ribbon stays on ground through scaled casting")
    visual.queue_free()
    await frames(3)
    var flow: Node = root.get_node("GameFlow")
    flow.configure_teams(false,[],[])
    node_added.connect(silence)
    flow.start_versus("kabuto","naruto","training")
    await frames(18)
    node_added.disconnect(silence)
    var player: Node3D = current_scene.get_node("Player")
    player.set_physics_process(false)
    player.specials.set_physics_process(false)
    player.chakra = 100
    player.stagger_timer = 0
    player.attack_cooldown = 0
    check(player.specials.start("chakra_scalpel"),"Bisturi starts in actual combat")
    check(not player.specials.cast_visual.visible,"Preparation does not flash at origin before attachment")
    player.specials._physics_process(.2)
    check(player.specials.cast_visual.visible and player.specials.cast_visual.signature.pattern == "scalpel","Chakra hands use their signature in actual combat")
    check(not player.specials.sphere_visual.visible,"Medical chakra hands do not display a Rasengan orb")
    check(player.specials.cast_visual.global_position.distance_to(player.specials.rasengan_hitbox.global_position) < .01,"Chakra signature follows real hand hitbox")
    player.specials.cancel()
    check(not player.specials.cast_visual.visible,"Interruption clears accents")
    var impact: Node3D = current_scene.get_node("CombatFeedback").elemental_impacts[0]
    impact.activate(Vector3(0,.8,0),"bone",1.0,Vector3.RIGHT)
    check(impact.signature.visible and impact.signature.pattern == "bone_field","Impact includes elemental geometry")
    impact.recycle()
    check(not impact.signature.visible,"Impact pool clears accent on recycle")
    node_added.connect(silence)
    flow.start_versus("naruto","naruto","training")
    await frames(18)
    node_added.disconnect(silence)
    player = current_scene.get_node("Player")
    var projectile: Node3D = player.specials.projectiles[0]
    projectile.set_physics_process(false)
    projectile.launch(player,current_scene.get_node("EnemyDummy"),player.global_position+Vector3.UP,Vector3.BACK)
    check(projectile.signature.visible and projectile.signature.pattern == "arsenal","Demon Wind has a metal trail on actual projectile")
    projectile.signature.update_visual(.1,Vector3.BACK)
    projectile.recycle()
    check(not projectile.signature.visible,"Demon Wind clears trail when recycled")
    flow.enter_selection()
    await frames(8)
    print("JUTSU SIGNATURE CONTRACT: "+("PASS" if failures == 0 else "FAIL")+" (%d checks; %d techniques, %d specific)" % [checks,total,specific])
    quit(0 if failures == 0 else 1)
