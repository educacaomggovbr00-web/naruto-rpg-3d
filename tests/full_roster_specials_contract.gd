extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    var pending_flow: Node = root.get_node("GameFlow")
    while pending_flow.busy:
        await process_frame
    for _index: int in range(count):
        await physics_frame

func reset_fighter(fighter: CharacterBody3D) -> void:
    fighter.specials.cancel()
    fighter.jutsu_cooldown = 0.0
    fighter.stagger_timer = 0.0
    fighter.invulnerable_timer = 0.0
    fighter.attack_active = false
    fighter.jutsu_timer = 0.0
    fighter.chakra_dash_timer = 0.0
    fighter.dodge_timer = 0.0
    fighter.chakra = fighter.max_chakra
    fighter.velocity = Vector3.ZERO

func run() -> void:
    CharacterCatalog.initialize()

    check(CharacterCatalog.READY.size() == 26, "Full roster must contain 25 fighters")

    var special_ids: Dictionary = {}
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        check(fighter.moveset != null, "Every fighter needs a moveset: " + fighter.character_id)
        check(fighter.moveset.ground.size() == 4, "Every fighter needs four ground attacks: " + fighter.character_id)
        check(fighter.moveset.aerial.size() == 4, "Every fighter needs four aerial attacks: " + fighter.character_id)
        check(not fighter.jutsus.is_empty(), "Every fighter needs at least one jutsu: " + fighter.character_id)

        for jutsu_id: String in fighter.jutsus:
            var data: JutsuDefinition = fighter.find_jutsu(jutsu_id)
            check(data != null, "Jutsu data missing: " + fighter.character_id + "/" + jutsu_id)
            if data != null:
                check(data.strategy in ["hand", "projectile", "clones", "barrage", "trap", "burst"], "Unsupported jutsu strategy: " + jutsu_id)
                check(data.chakra_cost > 0.0 and data.damage >= 0.0, "Jutsu needs valid gameplay values: " + jutsu_id)
                special_ids[jutsu_id] = fighter.character_id

    check(special_ids.size() >= 25, "Roster should expose at least 25 distinct selectable special ids")

    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("shikamaru", "gaara", "training") == OK, "Generic-special versus battle opens")
    await frames(12)

    var arena: Node3D = current_scene
    var player: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")
    player.set_physics_process(false)
    cpu.set_physics_process(false)
    player.specials.set_physics_process(false)
    cpu.specials.set_physics_process(false)
    cpu.enable_arsenal = false
    cpu.react_to_projectiles = false

    player.global_position = Vector3(0.0, 0.96, -5.0)
    player.rotation.y = 0.0
    cpu.global_position = Vector3(0.0, 0.96, 5.0)
    await frames(2)

    reset_fighter(player)
    check(player.character_definition.character_id == "shikamaru", "Player uses Shikamaru definition")
    check(player.specials.projectiles.size() == 3, "Projectile fighter receives bounded projectile pool")
    check(player.specials.start("shadow_bind"), "Shikamaru special starts")
    player.specials._physics_process(0.25)
    var projectile: Node3D = player.specials.projectiles[0]
    check(projectile.active, "Generic projectile releases after animation impact")
    check(projectile.definition != null and projectile.definition.jutsu_id == "shadow_bind", "Generic projectile keeps character-specific jutsu data")
    projectile.call("recycle")
    player.specials.cancel()

    reset_fighter(cpu)
    check(cpu.character_definition.character_id == "gaara", "CPU uses Gaara definition")
    check(cpu.specials.start("sand_coffin"), "Gaara burst special starts")
    cpu.specials._physics_process(0.25)
    check(cpu.specials.rasengan_hitbox.remaining_time > 0.0, "Burst strategy opens a physical combat hitbox")
    check(cpu.specials.move_definition != null and cpu.specials.move_definition.hitbox_radius > 1.0, "Gaara burst preserves its own radius")
    cpu.specials.cancel()

    var lee: CharacterDefinition = CharacterCatalog.find("rock_lee")
    var lee_jutsu: JutsuDefinition = lee.find_jutsu("leaf_whirlwind")
    check(lee_jutsu != null and lee_jutsu.strategy == "hand", "Rock Lee receives rush/hand special data")
    check(lee.movement_speed > CharacterCatalog.SAKURA.movement_speed, "Rock Lee profile remains mobility-focused")

    var tsunade: CharacterDefinition = CharacterCatalog.find("tsunade")
    var tsunade_jutsu: JutsuDefinition = tsunade.find_jutsu("heaven_kick")
    check(tsunade_jutsu != null and tsunade_jutsu.damage >= 30.0, "Tsunade receives heavy melee special profile")

    arena.queue_free()
    await frames(4)

    print("FULL ROSTER SPECIALS CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
