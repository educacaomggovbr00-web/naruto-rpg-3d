extends SceneTree
var failures := 0
var checks := 0
func _initialize():
    call_deferred("run")
func check(ok: bool, message: String):
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int):
    var pending_flow: Node = root.get_node("GameFlow")
    while pending_flow.busy:
        await process_frame
    for index in range(count):
        await physics_frame
        await process_frame
func silence_fixture_enemy(node: Node):
    if node.name == "EnemyDummy":
        node.process_mode = Node.PROCESS_MODE_DISABLED

func run():
    var forks = MultiMeshInstance3D.new()
    forks.set_script(load("res://scripts/chidori_effect.gd"))
    root.add_child(forks)
    var start = Vector3(.1,-.2,.3)
    var finish = Vector3(.4,.1,-.2)
    forks._segment(0,start,finish)
    var transform = forks.segment_transform(start,finish)
    check((transform.origin - transform.basis.y*.5).is_equal_approx(start), "Electric segment starts at authored endpoint")
    check((transform.origin + transform.basis.y*.5).is_equal_approx(finish), "Electric segment ends at authored endpoint")
    forks.queue_free()
    var effect = Node3D.new()
    effect.set_script(load("res://scripts/elemental_jutsu_visual.gd"))
    root.add_child(effect)
    for kind in ["fire","water","wind","chakra","black_fire","mind","lightning","sand","susanoo"]:
        effect.configure(kind,.5)
        effect.heading = Vector3.RIGHT
        effect.update_visual(.1)
        check(effect.core.visible, kind + " has elemental core")
        check(effect.core_material.get_shader_parameter("energy_color") == RosterVisualStyle.color(kind), kind + " owns elemental palette")
        var tail = effect.tail_tip
        check(tail.x < -.5, kind + " trail follows heading")
        check(tail.is_finite() and tail.length() < 3, kind + " trail bounded")
    effect.set_quality(0)
    check(effect.motes.multimesh.visible_instance_count == 6,"Low quality mote budget")
    effect.configure("lightning",3.2,true)
    effect.update_visual(.18)
    check(not effect.core.visible, "Nagashi is radial, no giant opaque orb")
    check(effect.rings[0].scale.x < 3.2, "Nagashi radius bounded")
    effect.update_visual(.3)
    check(not effect.visible,"Burst expires during recovery")
    effect.scale = Vector3.ONE * .1
    effect.configure("fire",.3)
    check(not effect.burst and effect.visible and is_zero_approx(effect.clock) and effect.scale == Vector3.ONE, "Pool reuse clears radial state, clock and scale")
    effect.configure("fire",.8,false,"wave")
    effect.update_visual(.1)
    check(effect.core.scale.x > effect.core.scale.y*2.0,"Katon wave has a broad silhouette")
    effect.queue_free()
    var flow = root.get_node("GameFlow")
    # Disable AI before _ready/first physics tick: shader compilation can take
    # enough wall time for a live CPU to interrupt this presentation-only test.
    node_added.connect(silence_fixture_enemy)
    check(flow.start_versus("henrique","naruto","training") == OK,"Battle opens")
    await frames(20)
    node_added.disconnect(silence_fixture_enemy)
    var player = current_scene.get_node("Player")
    var enemy = current_scene.get_node("EnemyDummy")
    player.set_physics_process(false)
    enemy.set_physics_process(false)
    var specials = player.specials
    player.jutsu_cooldown = 0
    player.chakra = 100
    check(specials.start("henrique_nagashi"),"Nagashi starts")
    specials._physics_process(specials.release_time()+.01)
    check(specials.cast_visual.burst, "Nagashi uses radial pulse")
    check(not specials.chidori_visual.visible,"Nagashi has no stretched hand forks")
    specials.cancel(false)
    check(specials.cast_visual.visible and specials.rasengan_hitbox.remaining_time == 0, "Normal recovery preserves visual pulse but closes damage")
    specials.cast_visual.update_visual(.4)
    check(not specials.cast_visual.visible, "Recovery pulse expires")
    player.jutsu_cooldown = 0
    player.chakra = 100
    check(specials.start("henrique_chidori"),"Chidori starts after Nagashi")
    check(specials.chidori_visual.scale.is_equal_approx(Vector3.ONE),"Chidori scale resets between jutsus")
    specials._physics_process(.25)
    if DisplayServer.get_name() != "headless":
        await frames(2)
        await RenderingServer.frame_post_draw
    specials.cancel()
    check(not specials.cast_visual.visible,"Cancel hides charge presentation")
    player.jutsu_cooldown = 0
    player.chakra = 100
    player.locked_target = enemy
    check(specials.start("henrique_katon"),"Katon starts")
    specials._physics_process(specials.release_time()+.01)
    player.locked_target = enemy
    var launched = false
    for projectile in specials.projectiles:
        if projectile.active:
            launched = true
            check(projectile.direction.dot((enemy.global_position-player.global_position).normalized()) > .9, "Locked projectile launches toward target")
            check(projectile.elemental_visual.visible,"Launched Katon owns animated flame core")
            check(not projectile.orb.visible,"Plain orb hidden")
            projectile.recycle()
            check(not projectile.visible,"Projectile recycle hides all effects")
    check(launched,"Katon projectile released")
    check(not specials.cast_visual.visible,"Charge cue hides on projectile release")
    specials.cancel()
    current_scene.queue_free()
    await frames(3)
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        await process_frame
    print("JUTSU PRESENTATION CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL",checks])
    quit(0 if failures == 0 else 1)
