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
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)
    check(flow.configure_teams(true, ["sasuke", "sasuke"], []) == ERR_INVALID_PARAMETER, "Duplicate partners rejected before changing settings")
    check(flow.configure_teams(true, ["missing"], []) == ERR_INVALID_PARAMETER, "Unknown team member rejected")
    check(flow.configure_teams(true, ["sasuke", "sakura"], ["kisame", "orochimaru"]) == OK, "Valid three-fighter formation accepted")
    flow.battle_rules_enabled = true
    check(flow.start_versus("henrique", "itachi", "ruins") == OK, "Team battle starts through the existing flow")
    await frames(12)
    var fighter: CharacterBody3D = current_scene.get_node("Player")
    var enemy: CharacterBody3D = current_scene.get_node("EnemyDummy")
    var team: Node = fighter.team
    fighter.set_physics_process(false)
    enemy.set_physics_process(false)
    team.set_physics_process(false)
    enemy.team.set_physics_process(false)
    enemy.reactive_substitution = false
    current_scene.get_node("CombatFeedback").hit_stop_enabled = false
    current_scene.get_node("BattleBridge").set_physics_process(false)
    fighter.global_position = Vector3(0, 1, 2)
    enemy.global_position = Vector3(0, 1, -1)
    fighter.locked_target = enemy
    fighter.invulnerable_timer = 0.0
    enemy.invulnerable_timer = 0.0
    check(team.members.size() == 3 and enemy.team.members.size() == 3, "Both sides use three unique roster members")
    check(team.tasks.is_empty() and team.sequence_members.is_empty(), "No inactive partner rigs allocated")
    check(current_scene.get_node("TeamHUD").buttons.size() == 5, "Support, leader, ultimate and linked awakening have touch buttons")
    check(root.get_node("CombatSettings").DIFFICULTIES.size() == 4 and InputMap.has_action("pad_leader_change"), "Difficulty and controller mapping retained")
    check(not team.call_support(2) and team.support == 100.0, "Invalid support slot cannot consume gauge")
    check(team.call_support(0), "Support summons selected Sasuke technique")
    check(team.tasks.size() == 1 and team.tasks[0].actor.definition.character_id == "sasuke", "Support uses the partner model and technique")
    check(team.tasks[0].actor.rig_adapter.real_animation_count == 127, "Support retains real combat rig")
    check(not team.call_support(0), "Support cannot bypass member cooldown")
    check(is_equal_approx(team.support, 65.0), "Support consumes its shared gauge exactly once")
    var health_before: float = enemy.health
    for frame: int in range(30):
        team._update_supports(.05)
        await frames(1)
    check(enemy.health < health_before, "Timed partner approach actually connects a technique")
    check(team.storm > 0.0, "Real connected support damage contributes to Storm")
    team._clear_supports()
    team.member_state[2].support_cd = 0.0
    team.support = 100.0
    check(team.call_support(1), "Second partner can be called")
    var interrupted: Node = team.tasks[0].actor
    interrupted.receive_combat_hit(2.0, Vector3.ZERO, 0.0, 0.0, 0.0)
    check(team.tasks.is_empty() and team.member_state[2].support_cd > 6.0, "Opponent can interrupt a vulnerable support and extend recharge")
    await frames(3)
    fighter.health = 71.0
    fighter.chakra = 31.0
    fighter.substitutions = 3
    fighter.jutsu_cooldown = 2.0
    fighter.ultimate.cooldown = 4.0
    fighter.stagger_timer = 0.0
    fighter.jutsu_timer = 0.0
    fighter.attack_active = false
    team.support = 100.0
    check(team.request_change(0), "Neutral leader change accepted")
    check(not team.request_change(0), "Concurrent changes rejected")
    await frames(4)
    check(fighter.character_definition.character_id == "sasuke" and fighter.rig_adapter.character_definition.character_id == "sasuke", "Leader change replaces kit and actual mesh")
    check(fighter.health == 71.0 and fighter.max_health == CharacterCatalog.HENRIQUE.max_health and fighter.substitutions == 3, "Health and substitution resources remain shared")
    check(fighter.moveset == CharacterCatalog.SASUKE.moveset and fighter.specials.selected == "fireball", "Switched leader uses own moveset and abilities")
    check(team.member_state[0].chakra == 31.0 and team.member_state[0].ultimate == 4.0, "Inactive leader retains chakra and ultimate recharge")
    team.switch_cooldown = 0.0
    team.support = 100.0
    check(team.request_change(0), "Switch back to Henrique accepted")
    await frames(4)
    check(fighter.character_definition.character_id == "henrique" and fighter.chakra == 31.0 and fighter.jutsu_cooldown == 2.0, "Switching back cannot refill spent chakra or erase cooldown")
    fighter.selected_attack = fighter.moveset.attack(1, false)
    fighter.attack_active = true
    fighter.attack_confirmed = false
    team.switch_cooldown = 0.0
    check(not team.request_change(0), "Leader change cannot cancel an unconfirmed startup")
    fighter.attack_confirmed = true
    fighter.attack_elapsed = float(fighter.selected_attack.animation_timing(fighter.rig_adapter.manifest).get("cancel_open", .2))
    fighter.jutsu_cooldown = 0.0
    fighter.chakra = 100.0
    check(team.request_change(0), "Confirmed attack window permits combo handoff")
    await frames(3)
    check(fighter.character_definition.character_id == "sasuke" and fighter.attack_active and fighter.combo_step == 1, "New leader continues the combo with its own strike")
    fighter._cancel_attack()
    fighter.attack_cooldown = 0.0
    fighter.health = 40.0
    fighter.chakra = 100.0
    fighter.ultimate.cooldown = 0.0
    team.support = 100.0
    team.storm = 99.0
    enemy.health = 100.0
    enemy.stagger_timer = 0.0
    enemy.global_position = Vector3(0, 1, -1)
    check(not team.start_ultimate() and team.storm == 99.0, "Team supreme requires a full Storm bar")
    team.storm = 100.0
    check(team.start_ultimate(), "Team supreme begins only at valid range and resources")
    check(fighter.cinematic_owner == team and enemy.cinematic_owner == team, "Team cinematic owns both locks")
    check(team.sequence_members.size() == 2 and team.storm == 0.0 and fighter.chakra == 35.0, "Supreme presents both actual partners and consumes resources")
    for index: int in range(47):
        team._update_sequence(.05)
    check(team.phase.is_empty() and fighter.cinematic_owner == null and enemy.cinematic_owner == null, "Cinematic releases both fighters on completion")
    check(enemy.health < 80.0 and enemy.health > 0.0, "Team supreme applies bounded real combat damage")
    await frames(4)
    team.support = 100.0
    team.storm = 100.0
    fighter.chakra = 100.0
    enemy.health = 100.0
    check(team.start_ultimate(), "Second cinematic can start after spending another full gauge")
    team.cancel("substitution")
    check(team.phase.is_empty() and team.sequence_members.is_empty() and enemy.cinematic_owner == null, "Substitution/interruption cleans up cinematic partners and locks")
    await frames(3)
    team.reset()
    fighter.attack_active = false
    fighter.stagger_timer = 0.0
    fighter.jutsu_timer = 0.0
    fighter.chakra = 100.0
    fighter.health = 40.0
    fighter.awakening.cooldown = 0.0
    team.storm = 100.0
    check(team.start_linked_awakening(), "Shared low-health/full-Storm linked awakening accepted")
    check(fighter.awakening.transforming and team.linked_remaining == 12.0, "Linked awakening uses real leader transformation and a bounded shared window")
    check(team.call_support(0), "Linked awakening permits an awakened partner call")
    check(team.tasks[0].actor.linked_avatar != null, "Henrique support displays its real Susanoo while linked")
    fighter.awakening._physics_process(1.0)
    team._physics_process(.1)
    check(fighter.awakening.active and fighter.awakening.remaining <= team.linked_remaining, "Leader awakening duration cannot outlive the shared window")
    team.support = 100.0
    team.switch_cooldown = 0.0
    check(team.request_change(0), "Linked awakening permits a leader handoff")
    await frames(4)
    check(fighter.character_definition.character_id == "henrique" and fighter.awakening.transforming, "Switched linked leader uses its own real transformation")
    fighter.awakening.stop()
    team.linked_remaining = 0.0
    team.reset()
    fighter.health = 100.0
    fighter.stagger_timer = 0.0
    fighter.is_charging_chakra = true
    fighter.chakra = 20.0
    team.storm = 50.0
    team._automatic_actions()
    check(team.last_action == "Charge Assist" and fighter.chakra == 32.0 and team.support == 75.0, "Charge Assist spends support to replenish chakra")
    team._clear_supports()
    team.automatic_cooldown = 0.0
    check(team.incoming_damage(20.0, true) == 11.0 and team.last_action == "Charge Guard", "Charge Guard protects a broken guard with bounded reduction and recharge")
    fighter.is_charging_chakra = false
    team._clear_supports()
    team.automatic_cooldown = 0.0
    team.support = 100.0
    team.storm = 60.0
    enemy.global_position = fighter.global_position + Vector3.FORWARD * 2.5
    enemy.chakra_dash_timer = .2
    enemy.invulnerable_timer = 0.0
    enemy.is_guarding = false
    team._automatic_actions()
    check(team.last_action == "Dash Cut" and enemy.chakra_dash_timer == 0.0, "Dash Cut actually stops an incoming chakra dash")
    team._clear_supports()
    team.automatic_cooldown = 0.0
    team.support = 100.0
    team.member_state[team.partner_indices()[0]].support_cd = 0.0
    fighter.ninja_tools.pending = "shuriken"
    team._automatic_actions()
    check(team.last_action == "Cover Fire" and team.tasks.size() == 1, "Cover Fire accompanies the leader's ninja tools")
    fighter.ninja_tools.pending = ""
    team._clear_supports()
    team.automatic_cooldown = 0.0
    team.support = 100.0
    team.member_state[team.partner_indices()[0]].support_cd = 0.0
    team.record_hit(12.0, 8.0, false)
    check(team.last_action == "Strike Back" and team.tasks.size() == 1, "Strike Back calls a real follow-up after launch")
    await frames(3)
    team._clear_supports()
    for definition: CharacterDefinition in CharacterCatalog.READY:
        if definition == fighter.character_definition:
            continue
        var roster: Array[CharacterDefinition] = [fighter.character_definition, definition]
        team.members = roster
        var stored: Array[Dictionary] = [
            {"chakra": fighter.max_chakra, "jutsu": 0.0, "ultimate": 0.0, "awakening": 0.0, "support_cd": 0.0},
            {"chakra": definition.max_chakra, "jutsu": 0.0, "ultimate": 0.0, "awakening": 0.0, "support_cd": 0.0}
        ]
        team.member_state = stored
        team.leader = 0
        team.support = 100.0
        team.switch_cooldown = 0.0
        fighter.attack_active = false
        fighter.attack_cooldown = 0.0
        fighter.jutsu_timer = 0.0
        fighter.awakening.stop()
        fighter.stagger_timer = 0.0
        var hp: float = fighter.health
        check(team.request_change(0), "Roster leader switch accepted: " + definition.character_id)
        await frames(4)
        check(fighter.character_definition == definition and fighter.health == hp, "Roster switch keeps shared health: " + definition.character_id)
        check(fighter.rig_adapter.rig_loaded and fighter.rig_adapter.real_animation_count == 127, "Roster switch retains all real clips: " + definition.character_id)
        check(fighter.specials.selected in definition.jutsus and fighter.ultimate.definition != null, "Roster switch installs own full kit: " + definition.character_id)
    var adapter_script: Script = load("res://scripts/rigged_character_adapter.gd")
    check(adapter_script.library_cache.size() <= 4, "Repeated roster switches retain the bounded animation cache")
    check(current_scene.get_node("HUD/MobileControls")._expansion_overlay_contains(Vector2(150, 300)), "Team buttons do not also begin camera touches")
    flow.enter_selection()
    await frames(10)
    check(get_nodes_in_group("combat_teams").is_empty(), "Scene swap releases teams and support rigs")
    var menu: Node = current_scene
    menu._show_team_options()
    await frames(2)
    check(menu.get_node("TeamOptions").size.y <= 720, "Team setup dialog fits landscape viewport")
    menu.get_node("TeamOptions").queue_free()
    flow.configure_teams(true, ["sasuke", "sakura"], ["kakashi", "hinata"])
    flow.start_arcade("training", "henrique", "naruto", "training")
    await frames(10)
    fighter = current_scene.get_node("Player")
    enemy = current_scene.get_node("EnemyDummy")
    enemy.team.storm = 100.0
    fighter.chakra_dash_timer = .2
    enemy.team._physics_process(.1)
    check(not enemy.team.can_act() and enemy.team.tasks.is_empty(), "Training team cannot attack or assist against the learner")
    var team_panel: Control = current_scene.get_node("TeamHUD").panel
    var coach_panel: Control = current_scene.get_node("BattleBridge/TrainingCoach").panel
    check(not team_panel.get_global_rect().intersects(coach_panel.get_global_rect()), "Team controls do not cover guided training instructions")
    flow.enter_selection()
    await frames(8)
    current_scene.queue_free()
    await frames(4)
    check(root.get_child_count() == initial, "No team objects leak outside the scene")
    print("TEAM BATTLE CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
