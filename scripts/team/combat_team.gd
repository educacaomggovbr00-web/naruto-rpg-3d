class_name CombatTeam
extends Node
## One stable fighter body/HP bar, per-member chakra and ability cooldowns.
## Support calls are timed, interruptible roster actors, not instantaneous damage.
const SUPPORT_COST: float = 35.0
const SWITCH_COST: float = 25.0
const SUPPORT_COOLDOWN: float = 6.0
const AUTO_NAMES: PackedStringArray = ["Strike Back", "Cover Fire", "Charge Assist", "Charge Guard", "Dash Cut"]
var fighter: CharacterBody3D
var opponent: CharacterBody3D
var members: Array[CharacterDefinition] = []
var leader: int = 0
var support: float = 100.0
var storm: float = 0.0
var switch_cooldown: float = 0.0
var switching: bool = false
var linked_remaining: float = 0.0
var linked_authorization: bool = false
var member_state: Array[Dictionary] = []
var tasks: Array[Dictionary] = []
var automatic_cooldown: float = 0.0
var last_action: String = ""
var action_remaining: float = 0.0
var ai_timer: float = 2.0
var phase: String = ""
var sequence_time: float = 0.0
var sequence_target: CharacterBody3D
var sequence_stage: int = 0
var sequence_blocked: bool = false
var sequence_members: Array[Node3D] = []

func configure(actor: CharacterBody3D, enemy: CharacterBody3D, partner_ids: PackedStringArray) -> void:
    fighter = actor
    opponent = enemy
    members.append(fighter.character_definition)
    for id: String in partner_ids:
        var definition: CharacterDefinition = CharacterCatalog.find(id)
        if definition != null and definition not in members and members.size() < 3:
            members.append(definition)
    for definition: CharacterDefinition in members:
        member_state.append({"chakra": definition.max_chakra, "jutsu": 0.0, "ultimate": 0.0, "awakening": 0.0, "support_cd": 0.0})
    fighter.team = self
    process_physics_priority = 25

func _physics_process(delta: float) -> void:
    if fighter == null or not is_instance_valid(fighter):
        return
    if fighter.is_defeated() or not _opponent_alive():
        cancel("ko")
        _clear_supports()
        return
    support = minf(100.0, support + delta * 8.0)
    switch_cooldown = maxf(0.0, switch_cooldown - delta)
    automatic_cooldown = maxf(0.0, automatic_cooldown - delta)
    linked_remaining = maxf(0.0, linked_remaining - delta)
    if linked_remaining > 0.0 and fighter.awakening.active:
        fighter.awakening.remaining = minf(fighter.awakening.remaining, linked_remaining)
    action_remaining = maxf(0.0, action_remaining - delta)
    for index: int in range(member_state.size()):
        member_state[index].support_cd = maxf(0.0, float(member_state[index].support_cd) - delta)
        if index != leader:
            for key: String in ["jutsu", "ultimate", "awakening"]:
                member_state[index][key] = maxf(0.0, float(member_state[index][key]) - delta)
            member_state[index].chakra = minf(members[index].max_chakra, float(member_state[index].chakra) + delta * 2.0)
    _update_supports(delta)
    if not phase.is_empty():
        _update_sequence(delta)
    elif members.size() > 1 and not switching:
        if fighter.has_method("is_cpu_controlled") and GameFlow.arcade_mode == "training":
            return
        _automatic_actions()
        if fighter.has_method("is_cpu_controlled") and GameFlow.arcade_mode != "training":
            ai_timer -= delta
            if ai_timer <= 0.0:
                ai_timer = [3.5, 2.5, 1.7, 1.1][CombatSettings.difficulty]
                _choose_cpu_action()

func partner_indices() -> Array[int]:
    var result: Array[int] = []
    for index: int in range(members.size()):
        if index != leader:
            result.append(index)
    return result

func can_act() -> bool:
    if fighter.has_method("is_cpu_controlled") and GameFlow.arcade_mode == "training":
        return false
    return not switching and phase.is_empty() and not fighter.is_defeated() and _opponent_alive() and not is_instance_valid(fighter.cinematic_owner)

func _opponent_alive() -> bool:
    if is_instance_valid(opponent) and not opponent.is_defeated():
        return true
    for candidate: Node3D in get_tree().get_nodes_in_group("lock_targets"):
        if candidate.collision_layer != fighter.collision_layer and candidate.is_targetable():
            return true
    return false

func _target() -> CharacterBody3D:
    var target: CharacterBody3D = fighter.locked_target as CharacterBody3D
    if is_instance_valid(target) and target.is_targetable():
        return target
    if not opponent.is_defeated():
        return opponent
    for candidate: CharacterBody3D in get_tree().get_nodes_in_group("lock_targets"):
        if candidate.collision_layer != fighter.collision_layer and candidate.is_targetable():
            return candidate
    return opponent

func _clear_path(target: Node3D) -> bool:
    var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(fighter.global_position + Vector3.UP, target.global_position + Vector3.UP, 33)
    return fighter.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func call_support(slot: int = 0) -> bool:
    var partners: Array[int] = partner_indices()
    if not can_act() or slot < 0 or slot >= partners.size() or support < SUPPORT_COST:
        return false
    var index: int = partners[slot]
    var target: CharacterBody3D = _target()
    if member_state[index].support_cd > 0.0 or fighter.global_position.distance_to(target.global_position) > 18.0 or not _clear_path(target):
        return false
    if tasks.size() >= 2 or _active_partner_count() >= 2:
        return false
    var data: JutsuDefinition = _support_technique(members[index])
    if data == null:
        return false
    support -= SUPPORT_COST
    member_state[index].support_cd = SUPPORT_COOLDOWN
    var actor: CharacterBody3D = _create_partner(index)
    actor.global_position = fighter.global_position + fighter.global_basis.x * (1.35 if slot == 0 else -1.35)
    actor.global_position.x = clampf(actor.global_position.x, -27.0, 27.0)
    actor.global_position.z = clampf(actor.global_position.z, -27.0, 27.0)
    actor.rotation.y = atan2(target.global_position.x - actor.global_position.x, target.global_position.z - actor.global_position.z)
    actor.preview_animation(data.animation_name)
    var timing: Dictionary = data.animation_timing(actor.rig_adapter.manifest)
    var impact: float = clampf(float(timing.get("impact", .4)), .2, .9)
    tasks.append({"index": index, "actor": actor, "target": target, "data": data, "time": 0.0, "impact": impact, "released": false, "projectile": null})
    fighter.combat_feedback.spawn_substitution(actor.global_position)
    _announce(members[index].display_name + " • " + data.display_name)
    return true

func _support_technique(definition: CharacterDefinition) -> JutsuDefinition:
    for data: JutsuDefinition in definition.jutsu_definitions:
        if data.strategy in ["projectile", "hand", "burst"] and data.effect != "susanoo":
            return data.duplicate(true) as JutsuDefinition
    return null

func _create_partner(index: int) -> CharacterBody3D:
    var actor: CharacterBody3D = CharacterBody3D.new()
    actor.set_script(preload("res://scripts/team/support_actor.gd"))
    actor.definition = members[index]
    actor.squad = self
    actor.member_index = index
    add_child(actor)
    return actor

func _active_partner_count() -> int:
    var count: int = 0
    for squad: Node in get_tree().get_nodes_in_group("combat_teams"):
        count += squad.tasks.size() + squad.sequence_members.size()
    return count

func _update_supports(delta: float) -> void:
    for task: Dictionary in tasks.duplicate():
        var actor: CharacterBody3D = task.actor
        var target: CharacterBody3D = task.target
        if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not is_instance_valid(target) or target.is_defeated():
            _finish_task(task)
            continue
        task.time += delta
        var data: JutsuDefinition = task.data
        if not task.released and data.strategy != "projectile":
            var offset: Vector3 = target.global_position - actor.global_position
            actor.velocity = offset.limit_length(1.0) * 14.0
            actor.collision_mask = 33
            actor.move_and_slide()
        if not task.released and task.time >= task.impact:
            task.released = true
            data.damage *= .55 * (1.2 if linked_remaining > 0.0 else 1.0)
            if data.strategy == "projectile":
                var projectile: Node3D = Node3D.new()
                projectile.set_script(preload("res://scripts/generic_jutsu_projectile.gd"))
                add_child(projectile)
                projectile.launch_jutsu(fighter, target, actor.global_position + Vector3.UP * .4, (target.global_position - actor.global_position).normalized(), data)
                task.projectile = projectile
            elif actor.global_position.distance_to(target.global_position) <= maxf(1.8, data.hitbox_radius) and _clear_path(target):
                var blocked: bool = target.get_is_guarding()
                var dealt: float = target.receive_combat_hit(data.damage * fighter.get_damage_multiplier(), (target.global_position - actor.global_position).normalized(), data.knockback * .6, data.launch_force, data.hitstun)
                if dealt > 0.0:
                    ElementalStates.apply_hit(target, fighter, data.effect, blocked)
                    fighter.on_attack_connected(target, dealt, data.launch_force)
        if task.time >= task.impact + 1.5:
            _finish_task(task)

func _finish_task(task: Dictionary) -> void:
    for key: String in ["actor", "projectile"]:
        var node: Node = task[key]
        if is_instance_valid(node):
            if node.has_method("recycle"):
                node.recycle()
            node.queue_free()
    tasks.erase(task)

func interrupt_support(index: int) -> void:
    for task: Dictionary in tasks.duplicate():
        if int(task.index) == index:
            member_state[index].support_cd = SUPPORT_COOLDOWN + 2.0
            _finish_task(task)
            _announce("Suporte interrompido")

func _clear_supports() -> void:
    for task: Dictionary in tasks.duplicate():
        _finish_task(task)

func request_change(slot: int = 0) -> bool:
    var partners: Array[int] = partner_indices()
    if not can_act() or slot < 0 or slot >= partners.size() or support < SWITCH_COST or switch_cooldown > 0.0:
        return false
    if fighter.stagger_timer > 0.0 or fighter.jutsu_timer > 0.0 or fighter.chakra_dash_timer > 0.0 or fighter.dodge_timer > 0.0 or fighter.awakening.transforming or (fighter.awakening.active and linked_remaining <= 0.0):
        return false
    if fighter.attack_active and not _combo_change_open():
        return false
    switching = true
    call_deferred("_complete_change", partners[slot])
    return true

func _combo_change_open() -> bool:
    if not fighter.attack_confirmed or fighter.selected_attack == null:
        return false
    var timing: Dictionary = fighter.selected_attack.animation_timing(fighter.rig_adapter.manifest)
    return fighter.attack_elapsed >= float(timing.get("cancel_open", 0.0)) and fighter.attack_elapsed <= float(timing.get("cancel_close", 0.0))

func _complete_change(index: int) -> void:
    if fighter.is_defeated() or is_instance_valid(fighter.cinematic_owner) or fighter.stagger_timer > 0.0:
        switching = false
        return
    var chaining: bool = fighter.attack_active and fighter.attack_confirmed
    member_state[leader].chakra = fighter.chakra
    member_state[leader].jutsu = fighter.jutsu_cooldown
    member_state[leader].ultimate = fighter.ultimate.cooldown
    fighter.awakening.stop()
    member_state[leader].awakening = fighter.awakening.cooldown
    _clear_supports()
    FighterReconfiguration.discard_abilities(fighter)
    leader = index
    FighterReconfiguration.install(fighter, members[leader])
    var hud: Node = fighter.get_parent().get_node_or_null("HUD")
    if hud != null and not fighter.has_method("is_cpu_controlled"):
        hud._apply_anime_hud_style()
    var quality: Node = fighter.get_parent().get_node_or_null("MobileQuality")
    if quality != null:
        quality._apply_effect_quality(fighter)
    fighter.chakra = minf(fighter.max_chakra, float(member_state[leader].chakra))
    fighter.jutsu_cooldown = float(member_state[leader].jutsu)
    fighter.ultimate.cooldown = float(member_state[leader].ultimate)
    fighter.awakening.cooldown = float(member_state[leader].awakening)
    support -= SWITCH_COST
    switch_cooldown = 1.5
    switching = false
    fighter.combat_feedback.spawn_substitution(fighter.global_position)
    if linked_remaining > 0.0:
        linked_authorization = true
        fighter.awakening.start()
        linked_authorization = false
        fighter.awakening.remaining = minf(fighter.awakening.remaining, linked_remaining)
    elif chaining:
        if fighter.has_method("is_cpu_controlled"):
            fighter.combo_step = 1
            fighter._begin_strike()
        else:
            fighter.combo_step = 0
            fighter.combo_timer = .8
            fighter._try_attack()
    _announce("LÍDER • " + members[leader].display_name)

func record_hit(damage: float, launch: float, blocked: bool) -> void:
    if damage <= 0.0 or members.size() < 2:
        return
    storm = minf(100.0, storm + minf(damage * 1.35, 20.0) * (.5 if blocked else 1.0))
    if launch >= 5.0 and not blocked and automatic_cooldown <= 0.0 and support >= SUPPORT_COST and storm >= 40.0:
        if call_support(0):
            automatic_cooldown = 7.0
            _announce("Strike Back")

func incoming_damage(damage: float, guard_broken: bool = false) -> float:
    if damage <= 0.0 or members.size() < 2:
        return damage
    storm = minf(100.0, storm + minf(damage * .55, 10.0))
    if can_act() and guard_broken and storm >= 40.0 and support >= 25.0 and automatic_cooldown <= 0.0:
        support -= 25.0
        automatic_cooldown = 7.0
        fighter.guard_meter = maxf(fighter.guard_meter, 15.0)
        fighter.stagger_timer = minf(fighter.stagger_timer, .25)
        fighter.combat_state.force_state("guard_hit", .25)
        _announce("Charge Guard")
        _present_automatic("guard")
        return damage * .55
    return damage

func _automatic_actions() -> void:
    if not can_act() or storm < 40.0 or support < 25.0 or automatic_cooldown > 0.0:
        return
    var threat: CharacterBody3D = _target()
    if fighter.is_charging_chakra and fighter.chakra < fighter.max_chakra * .85:
        fighter.chakra = minf(fighter.max_chakra, fighter.chakra + 12.0)
        support -= 25.0
        automatic_cooldown = 7.0
        _present_automatic("chakra_charge")
        _announce("Charge Assist")
    elif threat.chakra_dash_timer > .06 and fighter.global_position.distance_to(threat.global_position) < 4.0:
        var dealt: float = threat.receive_combat_hit(3.0, (threat.global_position - fighter.global_position).normalized(), 5.0, 0.0, .25)
        if dealt > 0.0:
            threat.chakra_dash_timer = 0.0
            threat.dash_hitbox.deactivate()
            support -= 25.0
            automatic_cooldown = 7.0
            _present_automatic("guard")
            _announce("Dash Cut")
    elif fighter.ninja_tools.pending in ["shuriken", "kunai_rain", "bomb"]:
        if call_support(0):
            automatic_cooldown = 7.0
            _announce("Cover Fire")

func _present_automatic(clip: String) -> void:
    if _active_partner_count() >= 2:
        return
    var index: int = partner_indices()[0]
    var actor: CharacterBody3D = _create_partner(index)
    actor.global_position = fighter.global_position + fighter.global_basis.x * 1.2
    actor.preview_animation(clip)
    tasks.append({"index": index, "actor": actor, "target": opponent, "data": _support_technique(members[index]), "time": 0.0, "impact": .2, "released": true, "projectile": null})

func start_ultimate() -> bool:
    var target: CharacterBody3D = _target()
    if not can_act() or members.size() < 2 or storm < 100.0 or support < 50.0 or fighter.chakra < 65.0 or not fighter._can_use_movement_action() or fighter.awakening.active:
        return false
    if fighter.global_position.distance_to(target.global_position) > 5.5 or target.invulnerable_timer > 0.0 or not _clear_path(target) or _active_partner_count() > 0:
        return false
    sequence_blocked = target.get_is_guarding()
    if not fighter.begin_cinematic_lock(self):
        return false
    if not target.begin_cinematic_lock(self):
        fighter.end_cinematic_lock(self)
        return false
    storm = 0.0
    support -= 50.0
    fighter.chakra -= 65.0
    phase = "team"
    sequence_time = 0.0
    sequence_stage = 0
    sequence_target = target
    fighter.camera_rig.begin_sequence(target, 2.5)
    fighter.camera_rig.set_sequence_shot("chain")
    for index: int in partner_indices():
        var actor: CharacterBody3D = _create_partner(index)
        actor.global_position = fighter.global_position + fighter.global_basis.x * (1.5 if sequence_members.is_empty() else -1.5)
        actor.rotation.y = fighter.rotation.y
        actor.preview_animation(_support_technique(members[index]).animation_name)
        sequence_members.append(actor)
    _announce("TEAM ULTIMATE • " + members[leader].display_name)
    return true

func _update_sequence(delta: float) -> void:
    sequence_time += delta
    if not is_instance_valid(sequence_target) or fighter.is_defeated() or sequence_target.is_defeated() or not fighter.refresh_cinematic_lock(self) or not sequence_target.refresh_cinematic_lock(self):
        cancel("interrupted")
        return
    if fighter.character_definition.character_id == "henrique" and sequence_stage >= 2:
        fighter.ultimate.avatar.visible = true
        fighter.ultimate.avatar.update_pose(delta, true, clampf((sequence_time - .95) / 1.35, 0.0, 1.0), Vector3.ZERO, .55)
    if sequence_time < .35 and sequence_target.has_method("is_cpu_controlled") and sequence_target.reactive_substitution and sequence_target.substitutions > 0 and sequence_target.substitution_cooldown <= 0.0 and sequence_target.decision_rng.randf() < sequence_target.ai_profile.substitution_chance * delta * 4.0:
        var escaping: Node = sequence_target
        cancel("substitution")
        escaping._substitute()
        return
    var deadlines: Array[float] = [.45, .95, 1.5, 2.0]
    if sequence_stage < deadlines.size() and sequence_time >= deadlines[sequence_stage]:
        var data: JutsuDefinition = _support_technique(members[sequence_stage % members.size()])
        var blocked: bool = sequence_blocked
        sequence_target.is_guarding = blocked
        var dealt: float = sequence_target.receive_combat_hit(18.0 if sequence_stage == 3 else 9.0, fighter.global_basis.z, 9.0 if sequence_stage == 3 else 0.0, -5.0 if sequence_stage == 3 else 0.0, .2)
        sequence_target.is_guarding = false
        if dealt > 0.0:
            ElementalStates.apply_hit(sequence_target, fighter, data.effect, blocked)
        fighter.combat_feedback.spawn_elemental_impact(sequence_target.global_position + Vector3.UP * .4,data.effect,.9 if sequence_stage == 3 else .55,fighter.global_basis.z)
        fighter.camera_rig.add_combat_impact(.12, 2.5)
        sequence_stage += 1
        fighter.animation_action_id += 1
    if sequence_time >= 2.3:
        cancel("finished")

func cancel(_reason: String = "cancelled") -> void:
    if phase.is_empty():
        return
    phase = ""
    if is_instance_valid(fighter):
        fighter.end_cinematic_lock(self)
        fighter.camera_rig.end_sequence()
        if fighter.character_definition.character_id == "henrique" and is_instance_valid(fighter.ultimate):
            fighter.ultimate.avatar.visible = false
            fighter.ultimate.avatar.reset_pose()
    if is_instance_valid(sequence_target):
        sequence_target.end_cinematic_lock(self)
    sequence_target = null
    for actor: Node3D in sequence_members:
        if is_instance_valid(actor):
            actor.queue_free()
    sequence_members.clear()

func start_linked_awakening() -> bool:
    if not can_act() or members.size() < 2 or storm < 100.0 or support < 50.0 or fighter.chakra < fighter.max_chakra * .8 or linked_remaining > 0.0 or fighter.health > fighter.max_health * .5 or not fighter._can_use_movement_action() or not fighter.is_on_floor():
        return false
    for index: int in range(members.size()):
        if not members[index].has_awakening or (index != leader and member_state[index].awakening > 0.0):
            return false
    if fighter.awakening.cooldown > 0.0:
        return false
    linked_authorization = true
    var started: bool = fighter.awakening.start()
    linked_authorization = false
    if not started:
        return false
    storm = 0.0
    support -= 50.0
    linked_remaining = 12.0
    _announce("LINKED AWAKENING • EQUIPE")
    return true

func _choose_cpu_action() -> void:
    if CombatSettings.difficulty == 0 or not can_act():
        return
    if storm >= 100.0 and start_ultimate():
        return
    if storm >= 100.0 and start_linked_awakening():
        return
    if fighter.chakra < 20.0 and request_change(0):
        return
    call_support(0 if fighter.decision_rng.randf() < .5 or partner_indices().size() < 2 else 1)

func _announce(value: String) -> void:
    last_action = value
    action_remaining = 2.0

func animation_clip() -> String:
    if sequence_stage >= 3:
        return members[leader].ultimate_definition.finisher_clip
    return _support_technique(members[leader]).animation_name

func _exit_tree() -> void:
    cancel("scene_exit")
    if is_instance_valid(fighter):
        fighter.team = null

func reset() -> void:
    cancel("reset")
    _clear_supports()
    support = 100.0
    storm = 0.0
    switch_cooldown = 0.0
    switching = false
    linked_remaining = 0.0
    automatic_cooldown = 0.0
    for index: int in range(member_state.size()):
        member_state[index] = {"chakra": members[index].max_chakra, "jutsu": 0.0, "ultimate": 0.0, "awakening": 0.0, "support_cd": 0.0}
