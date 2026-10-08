class_name FighterReconfiguration
extends RefCounted
## Replace only character-specific modules; keep the body, camera, shared HP,
## hurtbox, controls and target references stable across a leader change.

static func discard_abilities(fighter: Node) -> void:
    if fighter.has_method("_cancel_attack"):
        fighter._cancel_attack()
    fighter.specials.cancel()
    fighter.awakening.stop()
    fighter.ultimate.cancel("leader_change")
    fighter.attack_hitbox.deactivate()
    fighter.dash_hitbox.deactivate()
    for property: String in ["specials", "awakening", "ultimate"]:
        var module: Node = fighter.get(property)
        fighter.remove_child(module)
        module.queue_free()
        fighter.set(property, null)

static func install(fighter: Node, definition: CharacterDefinition) -> void:
    fighter.character_definition = definition
    fighter.moveset = definition.moveset
    fighter.move_speed = definition.movement_speed
    fighter.max_chakra = definition.max_chakra
    if not fighter.has_method("is_cpu_controlled"):
        fighter.run_speed = definition.sprint_speed
    else:
        fighter.ai_profile = CombatSettings.profile_for(definition.ai_profile)
        fighter.decision_interval_min = .18 / maxf(fighter.ai_profile.decision_speed, .35)
        fighter.decision_interval_max = .32 / maxf(fighter.ai_profile.decision_speed, .35)
    var scripts: Array[Script] = [
        preload("res://scripts/combat_specials.gd"),
        preload("res://scripts/henrique_awakening.gd") if definition.character_id == "henrique" else
        preload("res://scripts/naruto_awakening.gd") if definition.character_id == "naruto" else
        preload("res://scripts/roster_awakening.gd"),
        preload("res://scripts/henrique_ultimate.gd") if definition.character_id == "henrique" else
        preload("res://scripts/ultimate_controller.gd") if definition.character_id == "naruto" else
        preload("res://scripts/roster_ultimate_controller.gd")
    ]
    var properties: Array[String] = ["specials", "awakening", "ultimate"]
    var names: Array[String] = ["CombatSpecials", "Awakening", "Ultimate"]
    for index: int in range(scripts.size()):
        var module: Node3D = Node3D.new()
        module.name = names[index]
        module.set_script(scripts[index])
        fighter.set(properties[index], module)
        fighter.add_child(module)
    fighter.rig_adapter.reload_character(definition)
    fighter.selected_attack = null
    fighter.combo_step = 0
    fighter.combo_branch = "neutral"
    if not fighter.has_method("is_cpu_controlled"):
        fighter.combo_timer = 0.0
    fighter.attack_active = false
    fighter.attack_cooldown = 0.0
    fighter.attack_buffer = 0.0
    fighter.attack_confirmed = false
    if fighter.has_method("is_cpu_controlled"):
        fighter.attack_airborne = not fighter.is_on_floor()
        fighter.counter_window = 0.0
        fighter.strike_counter_bonus = 1.0
    fighter.jutsu_timer = 0.0
    fighter.chakra_dash_timer = 0.0
    fighter.dodge_timer = 0.0
    fighter.is_guarding = false
    fighter.is_charging_chakra = false
    fighter.animation_action_id += 1
    fighter.combat_state.clear_transient()
    if fighter.has_method("is_cpu_controlled"):
        fighter.arsenal_delay = .5
    elif fighter.mobile_controls != null:
        fighter.mobile_controls.configure_character(definition)
