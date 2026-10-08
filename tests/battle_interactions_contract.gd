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
func frames(count: int = 4) -> void:
    var flow: Node = root.get_node("GameFlow")
    while flow.busy:
        await process_frame
    for index: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    var initial: int = root.get_child_count()
    var flow: Node = root.get_node("GameFlow")
    flow.team_enabled = false
    flow.battle_rules_enabled = true
    check(flow.start_versus("henrique", "temari", "valley") == OK, "Interaction battle uses existing scene and roster")
    await frames(12)
    var fighter: CharacterBody3D = current_scene.get_node("Player")
    var enemy: CharacterBody3D = current_scene.get_node("EnemyDummy")
    var arena: Node = current_scene.get_node("ArenaInteractions")
    fighter.set_physics_process(false)
    enemy.set_physics_process(false)
    enemy.reactive_substitution = false
    current_scene.get_node("CombatFeedback").hit_stop_enabled = false
    current_scene.get_node("BattleBridge").set_physics_process(false)
    fighter.invulnerable_timer = 0.0
    enemy.invulnerable_timer = 0.0
    enemy.health = 100.0
    enemy.is_guarding = false
    check(fighter.battle_condition != null and enemy.battle_condition != null, "Damage condition attached without replacing actors")
    ElementalStates.apply_hit(enemy, fighter, "fire", true)
    check(not enemy.has_node("ElementalStates"), "Blocked fire cannot apply burning")
    enemy.invulnerable_timer = .5
    ElementalStates.apply_hit(enemy, fighter, "fire")
    check(not enemy.has_node("ElementalStates"), "Substitution invulnerability prevents status")
    enemy.invulnerable_timer = 0.0
    ElementalStates.apply_hit(enemy, fighter, "fire")
    var states: Node = enemy.get_node("ElementalStates")
    states.set_physics_process(false)
    check(states.states.has("fire") and states.visuals.size() == 4, "Normal fire has a bounded status and visible marks")
    var health: float = enemy.health
    enemy.attack_active = true
    enemy.stagger_timer = 0.0
    states._physics_process(.76)
    check(is_equal_approx(enemy.health, health - 1.5), "Fire deals periodic damage through the victim contract")
    check(enemy.attack_active and enemy.stagger_timer == 0.0, "Burn ticks do not interrupt attacks or reset hitstun")
    ElementalStates.apply_hit(enemy, fighter, "fire")
    check(enemy.get_node("ElementalStates") == states, "Repeated fire refreshes one bounded state container")
    states.apply_element("oil", fighter)
    health = enemy.health
    states._physics_process(.76)
    check(is_equal_approx(enemy.health, health - 2.25), "Oil increases existing ordinary burning")
    states.apply_element("water", fighter)
    check(states.states.has("wet") and not states.states.has("fire"), "Water extinguishes normal fire and applies wetness")
    health = enemy.health
    states.apply_element("lightning", fighter)
    check(is_equal_approx(enemy.health, health - 3.0) and not states.states.has("wet"), "Electricity consumes wetness for one conduction pulse")
    health = enemy.health
    states.apply_element("lightning", fighter)
    check(enemy.health == health, "Repeated dry lightning cannot repeat the wet bonus")
    states.apply_element("water", fighter)
    states.apply_element("fire", fighter)
    check(not states.states.has("wet") and not states.states.has("fire"), "First fire consumes wetness without also igniting")
    states.apply_element("fire", fighter)
    check(states.states.has("fire"), "Later fire can ignite a dry target")
    ElementalStates.apply_hit(enemy, fighter, "black_fire")
    check(enemy.has_node("BlackFlames"), "Amaterasu retains its own black flame effect")
    states.apply_element("water", fighter)
    check(enemy.has_node("BlackFlames"), "Ordinary water does not remove black flames")
    enemy.invulnerable_timer = .4
    health = enemy.health
    check(enemy.receive_status_damage(10.0) == 0.0 and enemy.health == health, "Invulnerability also blocks damage ticks")
    enemy.invulnerable_timer = 0.0
    enemy.attack_active = false
    enemy.is_guarding = true
    check(is_equal_approx(enemy.receive_status_damage(10.0), 2.2), "Guard reduces periodic status damage")
    enemy.is_guarding = false
    enemy._respawn()
    await frames(3)
    check(not enemy.has_node("ElementalStates") and not enemy.has_node("BlackFlames"), "Respawn clears all elemental effects")
    enemy.set_physics_process(false)
    enemy.invulnerable_timer = 0.0
    enemy.reactive_substitution = false
    enemy.health = 100.0
    enemy.battle_condition.reset()
    enemy.receive_combat_hit(40.0, Vector3.BACK, 8.0, 0.0, .3)
    check(enemy.battle_condition.armor_broken, "Heavy received hits break armor")
    check(is_equal_approx(enemy.battle_condition.received_multiplier(), 1.06) and is_equal_approx(enemy.battle_condition.damage_multiplier(), 1.08), "Armor damage changes defense and attack by bounded amounts")
    enemy.battle_condition._sync_marks()
    check(enemy.battle_condition.damage_marks[0].visible, "Damage overlay follows the real skeleton")
    enemy.battle_condition.reset()
    enemy.health = 100.0
    enemy.guard_meter = 100.0
    enemy.is_guarding = true
    enemy.receive_combat_hit(28.0, Vector3.BACK, 8.0, 0.0, .3)
    check(enemy.battle_condition.weapon_broken and not enemy.battle_condition.armor_broken, "Heavy defended attack can break a weapon-user's weapon")
    check(is_equal_approx(enemy.battle_condition.damage_multiplier(), .9), "Broken equipment has a bounded offense penalty")
    check(arena.props.size() == 8 and arena.marks.multimesh.instance_count == 24, "Scenery and ground marks have fixed mobile budgets")
    var prop: Node = arena.props[0]
    prop.receive_scenery_hit(5.0)
    check(not prop.broken and prop.health == 13.0, "Prop withstands a light impact")
    arena.area_damage(prop.global_position, 1.0, 20.0)
    await frames(2)
    check(prop.broken and prop.collision_layer == 0 and not prop.mesh.visible, "Destroyed prop releases physical collision")
    check(prop.debris.multimesh.instance_count == 6, "Debris is preallocated and bounded")
    for index: int in range(60):
        arena.mark_impact(Vector3(index % 4, 0, 0), "fire", 1.0)
    check(arena.mark_life.size() == 24 and arena.marks.multimesh.instance_count == 24, "Repeated jutsus recycle marks without adding nodes")
    arena._physics_process(15.0)
    check(arena.mark_life.all(func(value: float): return value <= 0.0), "Old ground marks expire")
    fighter.stagger_timer = 0.0
    fighter.substitution_cooldown = 0.0
    fighter.substitutions = 4
    fighter._try_substitution()
    check(fighter.substitutions == 3 and fighter.counter_window > 0.0, "Substitution opens a bounded player counterattack window")
    enemy.is_guarding = false
    enemy.substitution_cooldown = 0.0
    enemy.substitutions = 4
    enemy._substitute()
    enemy._start_attack()
    check(enemy.strike_counter_bonus == 1.25, "CPU can punish with its own substitution counter")
    flow.enter_selection()
    await frames(8)
    flow.battle_rules_enabled = false
    check(flow.start_versus("henrique", "naruto", "training") == OK, "Classic solo rules remain selectable")
    await frames(8)
    check(current_scene.get_node("Player").battle_condition == null and current_scene.get_node("ArenaInteractions").props.is_empty(), "Classic rules preserve previous battle layout")
    flow.enter_selection()
    await frames(8)
    current_scene.queue_free()
    await frames(4)
    check(root.get_child_count() == initial, "Interaction scene teardown preserves autoloads")
    print("BATTLE INTERACTIONS CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
