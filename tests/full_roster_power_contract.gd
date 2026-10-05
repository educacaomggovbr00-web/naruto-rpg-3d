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
    for _index: int in range(count):
        await physics_frame

func ground_fighter(fighter: CharacterBody3D) -> void:
    fighter.velocity = Vector3.DOWN * 50.0
    fighter.move_and_slide()
    fighter.velocity = Vector3.ZERO

func clear_generic_fighter(fighter: CharacterBody3D) -> void:
    fighter.specials.call("cancel")
    fighter.ultimate.call("cancel")
    fighter.awakening.call("reset")
    fighter.attack_active = false
    fighter.stagger_timer = 0.0
    fighter.invulnerable_timer = 0.0
    fighter.jutsu_timer = 0.0
    fighter.jutsu_cooldown = 0.0
    fighter.chakra_dash_timer = 0.0
    fighter.dodge_timer = 0.0
    fighter.is_guarding = false
    fighter.is_charging_chakra = false
    fighter.chakra = fighter.max_chakra

func run() -> void:
    CharacterCatalog.initialize()

    check(CharacterCatalog.READY.size() == 25, "Power contract expects the full 25-fighter roster")
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        check(fighter.jutsus.size() >= 2, "Every fighter needs at least two jutsus: " + fighter.character_id)
        check(fighter.has_ultimate, "Every fighter needs an Ultimate: " + fighter.character_id)
        check(fighter.has_awakening, "Every fighter needs an Awakening: " + fighter.character_id)
        for jutsu_id: String in fighter.jutsus:
            check(fighter.find_jutsu(jutsu_id) != null, "Jutsu id must resolve: " + fighter.character_id + "/" + jutsu_id)

        if fighter.character_id != "naruto":
            check(fighter.ultimate_definition != null, "Generic Ultimate data missing: " + fighter.character_id)
            check(fighter.awakening_definition != null, "Generic Awakening data missing: " + fighter.character_id)
            if fighter.ultimate_definition != null:
                check(fighter.ultimate_definition.ultimate_id == fighter.character_id + "_ultimate", "Ultimate id must be character-owned: " + fighter.character_id)
                check(fighter.ultimate_definition.evidence == "OUR_APPROXIMATION", "Generic Ultimate must disclose approximation")
            if fighter.awakening_definition != null:
                check(fighter.awakening_definition.awakening_id == fighter.character_id + "_awakening", "Awakening id must be character-owned: " + fighter.character_id)
                check(fighter.awakening_definition.evidence == "OUR_APPROXIMATION", "Generic Awakening must disclose approximation")

    var flow: Node = root.get_node("GameFlow")
    check(flow.start_versus("sasuke", "sakura", "training") == OK, "Generic power test battle opens")
    await frames(12)

    var arena: Node3D = current_scene
    var player: CharacterBody3D = arena.get_node("Player")
    var cpu: CharacterBody3D = arena.get_node("EnemyDummy")

    player.set_physics_process(false)
    cpu.set_physics_process(false)
    cpu.enable_arsenal = false
    cpu.react_to_projectiles = false
    arena.get_node("CombatFeedback").hit_stop_enabled = false

    player.global_position = Vector3(0.0, 0.96, -1.8)
    player.rotation.y = 0.0
    cpu.global_position = Vector3(0.0, 0.96, 0.0)
    cpu.guarding = false
    cpu.invulnerable_timer = 0.0
    await frames(2)
    ground_fighter(player)
    ground_fighter(cpu)

    clear_generic_fighter(player)
    clear_generic_fighter(cpu)

    check(player.character_definition.character_id == "sasuke", "Player must use Sasuke")
    check(player.ultimate.definition != null and player.ultimate.definition.ultimate_id == "sasuke_ultimate", "Sasuke generic Ultimate is wired")
    check(player.awakening.definition != null and player.awakening.definition.awakening_id == "sasuke_awakening", "Sasuke generic Awakening is wired")

    var chakra_before: float = player.chakra
    check(player.ultimate.start(), "Generic Ultimate can start through shared resource gate")
    check(player.ultimate.phase == "entry" and player.chakra < chakra_before, "Ultimate consumes chakra and enters physical startup")

    player.ultimate._physics_process(0.17)
    check(player.ultimate.entry_box.remaining_time > 0.0, "Ultimate opens a physical entry hitbox")
    var cpu_health_before: float = cpu.health
    player.ultimate.entry_box.call("try_hit", cpu)
    check(player.ultimate.cinematic_started and player.ultimate.phase == "sequence", "Clean hit confirms generic Ultimate cinematic")
    check(cpu.cinematic_owner == player.ultimate, "Ultimate owns defender cinematic lock only after hit")
    check(cpu.health < cpu_health_before, "Ultimate entry hit applies real damage")

    player.ultimate._physics_process(player.ultimate.definition.sequence_duration + 0.01)
    check(player.ultimate.phase == "finish", "Ultimate advances to finisher after profile duration")
    player.ultimate._physics_process(0.19)
    check(player.ultimate.entry_box.remaining_time > 0.0, "Ultimate finisher opens a physical hitbox")
    var health_before_finish: float = cpu.health
    player.ultimate.entry_box.call("try_hit", cpu)
    check(cpu.health < health_before_finish, "Ultimate finisher damage comes from collision")
    player.ultimate._physics_process(0.50)
    check(player.ultimate.phase.is_empty(), "Generic Ultimate restores control after finisher")

    clear_generic_fighter(player)
    player.health = player.max_health * 0.25
    player.chakra = player.max_chakra
    ground_fighter(player)
    check(player.awakening.start(), "Generic Awakening starts at low health/full chakra")
    check(player.awakening.transforming and player.awakening.aura.visible, "Awakening exposes mobile aura during transform")
    player.awakening._physics_process(player.awakening.definition.transform_duration + 0.01)
    check(player.awakening.active, "Awakening reaches active mode")
    check(player.awakening.movement_multiplier() > 1.0, "Awakening modifies real movement")
    check(player.awakening.damage_multiplier() > 1.0 and player.get_damage_multiplier() > 1.0, "Awakening modifies real outgoing damage")
    var charge_before: float = player.chakra
    player.awakening._physics_process(0.5)
    check(player.chakra > charge_before, "Generic Awakening profile can regenerate chakra")
    player.awakening.stop()
    check(not player.awakening.active and not player.awakening.aura.visible, "Awakening cleanup hides VFX and restores normal mode")

    var sakura: CharacterDefinition = CharacterCatalog.SAKURA
    check(sakura.jutsus.size() >= 2 and sakura.find_jutsu("cherry_blossom_impact") != null, "Sakura receives second jutsu")
    check(sakura.has_ultimate and sakura.has_awakening, "Sakura receives full power kit")

    arena.queue_free()
    await frames(4)

    print("FULL ROSTER POWER CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
