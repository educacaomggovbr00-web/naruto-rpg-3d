class_name HenriqueKit
extends RefCounted

## Original protagonist kit; uses existing hit, guard, dodge and animation contracts.
static func complete(hero: CharacterDefinition) -> void:
    hero.moveset = RosterMovesetFactory.build_moveset("henrique")
    # Distinct choreography, same damage/branches/cancel and save contracts.
    var ground_clips: PackedStringArray = ["combat_jab_center", "combat_cross_center", "combat_hook_left", "combat_uppercut_center"]
    var air_clips: PackedStringArray = ["combat_jab_aerial", "combat_cross_aerial", "combat_hook_aerial", "combat_overhead_aerial"]
    for index: int in range(4):
        hero.moveset.ground[index].animation_name = ground_clips[index]
        hero.moveset.aerial[index].animation_name = air_clips[index]
    hero.moveset.up_finisher.animation_name = "combat_uppercut_high"
    hero.moveset.down_finisher.animation_name = "combat_overhead_low"
    hero.moveset.side_finisher.animation_name = "combat_hook_right"
    hero.ai_profile = RosterAIProfileFactory.build("sasuke")
    hero.jutsu_definitions = []
    var fire: JutsuDefinition = _jutsu("henrique_katon", "Katon: Bola de Fogo", "projectile", "fire", "combat_cast_center", 24.0, 22.0)
    fire.movement_speed = 20.0
    fire.tracking_strength = 2.5
    fire.hitbox_radius = 0.48
    var lightning: JutsuDefinition = _jutsu("henrique_chidori", "Chidori", "hand", "lightning", "combat_thrust_center", 32.0, 28.0)
    lightning.movement_speed = 15.0
    lightning.tracking_strength = 7.0
    var slash: JutsuDefinition = _jutsu("henrique_susanoo_slash", "Susanoo: Corte de Chakra", "burst", "susanoo", "combat_slash_center", 28.0, 30.0)
    slash.hitbox_radius = 1.85
    slash.knockback = 13.0
    hero.jutsu_definitions.assign([fire, lightning, slash])
    hero.jutsus = PackedStringArray([fire.jutsu_id, lightning.jutsu_id, slash.jutsu_id])
    var mode: AwakeningDefinition = AwakeningDefinition.new()
    mode.awakening_id = "henrique_awakening"
    mode.display_name = "Mangekyou • Susanoo"
    mode.effect = "susanoo"
    mode.energy_color = hero.energy_color
    mode.health_threshold = 0.50
    mode.mode_duration = 14.0
    mode.damage_multiplier = 1.30
    mode.movement_multiplier = 1.08
    hero.awakening_definition = mode
    var finish: UltimateDefinition = UltimateDefinition.new()
    finish.ultimate_id = "henrique_ultimate"
    finish.display_name = "Susanoo: Espada do Uchiha"
    finish.effect = "susanoo"
    finish.entry_clip = "chakra_dash"
    finish.finisher_clip = "combat_overhead_center"
    finish.chakra_cost = 80.0
    finish.finisher_damage = 38.0
    finish.finisher_knockback = 15.0
    hero.ultimate_definition = finish

static func _jutsu(id: String, title: String, strategy: String, effect: String, clip: String, cost: float, damage: float) -> JutsuDefinition:
    var data: JutsuDefinition = JutsuDefinition.new()
    data.jutsu_id = id
    data.display_name = title
    data.strategy = strategy
    data.effect = effect
    data.animation_name = clip
    data.chakra_cost = cost
    data.damage = damage
    data.behavior_evidence = "OUR_APPROXIMATION"
    return data
