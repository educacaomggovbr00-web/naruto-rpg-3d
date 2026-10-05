class_name RosterJutsuFactory
extends RefCounted

## Development-special profiles for the Storm 1 roster slots that do not yet
## have authored character Resources. Names identify the intended fantasy, but
## all gameplay tuning and current shared-animation choreography are
## OUR_APPROXIMATION until character-specific research/animation passes land.
const PROFILES: Dictionary = {
    "shikamaru": {"id": "shadow_bind", "name": "Shadow Bind", "strategy": "projectile", "effect": "shadow", "cost": 24.0, "cooldown": 1.7, "damage": 10.0, "knockback": 1.0, "lift": 0.0, "stun": 0.95, "radius": 0.52, "speed": 15.0, "tracking": 3.0},
    "choji": {"id": "human_boulder", "name": "Human Boulder", "strategy": "hand", "effect": "earth", "cost": 26.0, "cooldown": 1.5, "damage": 24.0, "knockback": 12.0, "lift": 3.0, "stun": 0.62, "radius": 0.78, "speed": 15.0, "tracking": 4.0},
    "ino": {"id": "mind_transfer", "name": "Mind Transfer", "strategy": "projectile", "effect": "mind", "cost": 28.0, "cooldown": 2.0, "damage": 8.0, "knockback": 0.5, "lift": 0.0, "stun": 1.05, "radius": 0.46, "speed": 16.0, "tracking": 2.6},
    "rock_lee": {"id": "leaf_whirlwind", "name": "Leaf Whirlwind", "strategy": "hand", "effect": "taijutsu", "cost": 20.0, "cooldown": 1.1, "damage": 20.0, "knockback": 8.0, "lift": 6.5, "stun": 0.52, "radius": 0.64, "speed": 17.0, "tracking": 7.5},
    "neji": {"id": "rotation", "name": "Eight Trigrams Rotation", "strategy": "burst", "effect": "chakra", "cost": 28.0, "cooldown": 1.8, "damage": 18.0, "knockback": 11.0, "lift": 2.0, "stun": 0.58, "radius": 1.75, "speed": 0.0, "tracking": 0.0},
    "tenten": {"id": "weapon_volley", "name": "Weapon Volley", "strategy": "projectile", "effect": "steel", "cost": 22.0, "cooldown": 1.3, "damage": 17.0, "knockback": 6.0, "lift": 1.0, "stun": 0.46, "radius": 0.42, "speed": 22.0, "tracking": 1.2},
    "shino": {"id": "insect_swarm", "name": "Insect Swarm", "strategy": "projectile", "effect": "insect", "cost": 25.0, "cooldown": 1.6, "damage": 15.0, "knockback": 3.0, "lift": 0.0, "stun": 0.72, "radius": 0.70, "speed": 14.0, "tracking": 4.2},
    "kiba": {"id": "fang_over_fang", "name": "Fang Over Fang", "strategy": "hand", "effect": "wind", "cost": 24.0, "cooldown": 1.3, "damage": 22.0, "knockback": 10.0, "lift": 3.0, "stun": 0.54, "radius": 0.72, "speed": 18.0, "tracking": 6.5},
    "hinata": {"id": "gentle_fist", "name": "Gentle Fist", "strategy": "hand", "effect": "chakra", "cost": 22.0, "cooldown": 1.2, "damage": 18.0, "knockback": 5.0, "lift": 1.0, "stun": 0.78, "radius": 0.52, "speed": 14.5, "tracking": 8.0},
    "gaara": {"id": "sand_coffin", "name": "Sand Coffin", "strategy": "burst", "effect": "sand", "cost": 30.0, "cooldown": 2.0, "damage": 23.0, "knockback": 6.0, "lift": 5.0, "stun": 0.85, "radius": 1.65, "speed": 0.0, "tracking": 0.0},
    "kankuro": {"id": "puppet_strike", "name": "Puppet Strike", "strategy": "projectile", "effect": "puppet", "cost": 25.0, "cooldown": 1.6, "damage": 20.0, "knockback": 8.0, "lift": 2.0, "stun": 0.58, "radius": 0.55, "speed": 17.0, "tracking": 2.8},
    "temari": {"id": "wind_scythe", "name": "Wind Scythe", "strategy": "projectile", "effect": "wind", "cost": 26.0, "cooldown": 1.5, "damage": 21.0, "knockback": 12.0, "lift": 3.0, "stun": 0.58, "radius": 0.76, "speed": 18.0, "tracking": 1.6},
    "might_guy": {"id": "dynamic_entry", "name": "Dynamic Entry", "strategy": "hand", "effect": "taijutsu", "cost": 22.0, "cooldown": 1.1, "damage": 23.0, "knockback": 10.0, "lift": 6.0, "stun": 0.52, "radius": 0.66, "speed": 18.0, "tracking": 7.0},
    "jiraiya": {"id": "toad_oil_bullet", "name": "Toad Oil Bullet", "strategy": "projectile", "effect": "oil", "cost": 27.0, "cooldown": 1.7, "damage": 19.0, "knockback": 8.0, "lift": 2.0, "stun": 0.60, "radius": 0.68, "speed": 16.0, "tracking": 2.2},
    "tsunade": {"id": "heaven_kick", "name": "Heaven Kick", "strategy": "hand", "effect": "earth", "cost": 28.0, "cooldown": 1.5, "damage": 30.0, "knockback": 14.0, "lift": -7.0, "stun": 0.82, "radius": 0.74, "speed": 14.0, "tracking": 5.0},
    "hiruzen": {"id": "fire_dragon", "name": "Fire Dragon", "strategy": "projectile", "effect": "fire", "cost": 28.0, "cooldown": 1.6, "damage": 23.0, "knockback": 9.0, "lift": 2.0, "stun": 0.58, "radius": 0.62, "speed": 18.0, "tracking": 1.8},
    "orochimaru": {"id": "snake_bind", "name": "Snake Bind", "strategy": "projectile", "effect": "snake", "cost": 27.0, "cooldown": 1.7, "damage": 17.0, "knockback": 4.0, "lift": 0.0, "stun": 0.92, "radius": 0.58, "speed": 17.0, "tracking": 3.8},
    "kabuto": {"id": "chakra_scalpel", "name": "Chakra Scalpel", "strategy": "hand", "effect": "chakra", "cost": 23.0, "cooldown": 1.3, "damage": 20.0, "knockback": 6.0, "lift": 1.0, "stun": 0.72, "radius": 0.52, "speed": 15.5, "tracking": 7.0},
    "kimimaro": {"id": "bone_dance", "name": "Bone Dance", "strategy": "burst", "effect": "bone", "cost": 28.0, "cooldown": 1.6, "damage": 24.0, "knockback": 10.0, "lift": 5.0, "stun": 0.65, "radius": 1.45, "speed": 0.0, "tracking": 0.0},
    "itachi": {"id": "fire_style", "name": "Fire Style", "strategy": "projectile", "effect": "fire", "cost": 26.0, "cooldown": 1.5, "damage": 22.0, "knockback": 8.0, "lift": 2.0, "stun": 0.58, "radius": 0.58, "speed": 19.0, "tracking": 1.6},
    "kisame": {"id": "water_shark", "name": "Water Shark", "strategy": "projectile", "effect": "water", "cost": 29.0, "cooldown": 1.7, "damage": 25.0, "knockback": 11.0, "lift": 3.0, "stun": 0.64, "radius": 0.78, "speed": 17.0, "tracking": 2.4}
}

const SECONDARY: Dictionary = {
    "sakura": {"id": "cherry_blossom_impact", "name": "Cherry Blossom Impact", "strategy": "burst", "effect": "earth", "cost": 26.0, "cooldown": 1.5, "damage": 28.0, "knockback": 13.0, "lift": 4.0, "stun": 0.72, "radius": 1.30, "speed": 0.0, "tracking": 0.0},
    "shikamaru": {"id": "shadow_sewing", "name": "Shadow Sewing", "strategy": "projectile", "effect": "shadow", "cost": 28.0, "cooldown": 1.9, "damage": 16.0, "knockback": 4.0, "lift": 1.0, "stun": 0.82, "radius": 0.48, "speed": 18.0, "tracking": 4.2},
    "choji": {"id": "partial_expansion", "name": "Partial Expansion", "strategy": "burst", "effect": "earth", "cost": 28.0, "cooldown": 1.7, "damage": 27.0, "knockback": 13.0, "lift": 4.0, "stun": 0.70, "radius": 1.35, "speed": 0.0, "tracking": 0.0},
    "ino": {"id": "chakra_flower_burst", "name": "Chakra Flower Burst", "strategy": "burst", "effect": "mind", "cost": 24.0, "cooldown": 1.6, "damage": 18.0, "knockback": 7.0, "lift": 2.0, "stun": 0.62, "radius": 1.20, "speed": 0.0, "tracking": 0.0},
    "rock_lee": {"id": "primary_lotus", "name": "Primary Lotus", "strategy": "hand", "effect": "taijutsu", "cost": 30.0, "cooldown": 1.8, "damage": 29.0, "knockback": 8.0, "lift": -12.0, "stun": 0.80, "radius": 0.68, "speed": 19.0, "tracking": 8.5},
    "neji": {"id": "sixty_four_palms", "name": "64 Palms", "strategy": "hand", "effect": "chakra", "cost": 30.0, "cooldown": 1.8, "damage": 27.0, "knockback": 6.0, "lift": 2.0, "stun": 0.92, "radius": 0.58, "speed": 16.0, "tracking": 8.5},
    "tenten": {"id": "twin_dragons", "name": "Twin Rising Dragons", "strategy": "burst", "effect": "steel", "cost": 28.0, "cooldown": 1.7, "damage": 25.0, "knockback": 10.0, "lift": 4.0, "stun": 0.66, "radius": 1.45, "speed": 0.0, "tracking": 0.0},
    "shino": {"id": "beetle_sphere", "name": "Beetle Sphere", "strategy": "burst", "effect": "insect", "cost": 29.0, "cooldown": 1.9, "damage": 23.0, "knockback": 8.0, "lift": 2.0, "stun": 0.78, "radius": 1.50, "speed": 0.0, "tracking": 0.0},
    "kiba": {"id": "beast_combo", "name": "Beast Human Combo", "strategy": "hand", "effect": "wind", "cost": 28.0, "cooldown": 1.6, "damage": 28.0, "knockback": 12.0, "lift": 5.0, "stun": 0.68, "radius": 0.72, "speed": 19.0, "tracking": 7.5},
    "hinata": {"id": "protective_palms", "name": "Protective Eight Trigrams", "strategy": "burst", "effect": "chakra", "cost": 28.0, "cooldown": 1.8, "damage": 22.0, "knockback": 9.0, "lift": 2.0, "stun": 0.74, "radius": 1.45, "speed": 0.0, "tracking": 0.0},
    "gaara": {"id": "sand_burial", "name": "Sand Burial", "strategy": "burst", "effect": "sand", "cost": 34.0, "cooldown": 2.2, "damage": 31.0, "knockback": 12.0, "lift": -8.0, "stun": 0.92, "radius": 1.85, "speed": 0.0, "tracking": 0.0},
    "kankuro": {"id": "poison_puppet", "name": "Poison Puppet Volley", "strategy": "projectile", "effect": "puppet", "cost": 29.0, "cooldown": 1.8, "damage": 24.0, "knockback": 7.0, "lift": 1.0, "stun": 0.82, "radius": 0.58, "speed": 18.0, "tracking": 3.6},
    "temari": {"id": "great_sickle_wind", "name": "Great Sickle Wind", "strategy": "burst", "effect": "wind", "cost": 31.0, "cooldown": 1.9, "damage": 28.0, "knockback": 14.0, "lift": 4.0, "stun": 0.72, "radius": 1.75, "speed": 0.0, "tracking": 0.0},
    "might_guy": {"id": "leaf_hurricane", "name": "Leaf Hurricane", "strategy": "hand", "effect": "taijutsu", "cost": 27.0, "cooldown": 1.5, "damage": 27.0, "knockback": 11.0, "lift": 6.0, "stun": 0.65, "radius": 0.70, "speed": 19.0, "tracking": 8.0},
    "jiraiya": {"id": "jiraiya_rasengan", "name": "Rasengan", "strategy": "hand", "effect": "chakra", "cost": 32.0, "cooldown": 1.8, "damage": 30.0, "knockback": 12.0, "lift": 4.0, "stun": 0.72, "radius": 0.64, "speed": 15.0, "tracking": 7.5},
    "tsunade": {"id": "ground_smash", "name": "Ground Smash", "strategy": "burst", "effect": "earth", "cost": 31.0, "cooldown": 1.9, "damage": 34.0, "knockback": 15.0, "lift": 5.0, "stun": 0.85, "radius": 1.65, "speed": 0.0, "tracking": 0.0},
    "hiruzen": {"id": "earth_dragon", "name": "Earth Dragon", "strategy": "projectile", "effect": "earth", "cost": 30.0, "cooldown": 1.8, "damage": 27.0, "knockback": 10.0, "lift": 3.0, "stun": 0.66, "radius": 0.68, "speed": 17.0, "tracking": 2.3},
    "orochimaru": {"id": "striking_snakes", "name": "Striking Shadow Snakes", "strategy": "hand", "effect": "snake", "cost": 29.0, "cooldown": 1.7, "damage": 26.0, "knockback": 8.0, "lift": 3.0, "stun": 0.82, "radius": 0.66, "speed": 16.0, "tracking": 7.0},
    "kabuto": {"id": "nerve_rupture", "name": "Nervous System Rupture", "strategy": "hand", "effect": "chakra", "cost": 28.0, "cooldown": 1.7, "damage": 24.0, "knockback": 6.0, "lift": 1.0, "stun": 0.95, "radius": 0.56, "speed": 16.0, "tracking": 7.5},
    "kimimaro": {"id": "clematis_dance", "name": "Clematis Dance", "strategy": "hand", "effect": "bone", "cost": 31.0, "cooldown": 1.8, "damage": 31.0, "knockback": 12.0, "lift": 6.0, "stun": 0.75, "radius": 0.72, "speed": 17.0, "tracking": 7.5},
    "itachi": {"id": "phoenix_flower", "name": "Phoenix Flower", "strategy": "projectile", "effect": "fire", "cost": 29.0, "cooldown": 1.7, "damage": 27.0, "knockback": 8.0, "lift": 3.0, "stun": 0.66, "radius": 0.58, "speed": 21.0, "tracking": 2.0},
    "kisame": {"id": "water_prison", "name": "Water Prison", "strategy": "burst", "effect": "water", "cost": 32.0, "cooldown": 2.0, "damage": 28.0, "knockback": 7.0, "lift": 2.0, "stun": 0.96, "radius": 1.60, "speed": 0.0, "tracking": 0.0}
}

static func build(id: String) -> JutsuDefinition:
    return _build_profile(PROFILES.get(id, {}))

static func build_secondary(id: String) -> JutsuDefinition:
    return _build_profile(SECONDARY.get(id, {}))

static func _build_profile(profile: Dictionary) -> JutsuDefinition:
    if profile.is_empty():
        return null

    var data: JutsuDefinition = JutsuDefinition.new()
    data.jutsu_id = String(profile["id"])
    data.display_name = String(profile["name"])
    data.strategy = String(profile["strategy"])
    data.animation_name = "rasengan" if data.strategy == "hand" else "jutsu"
    data.chakra_cost = float(profile["cost"])
    data.cooldown = float(profile["cooldown"])
    data.damage = float(profile["damage"])
    data.knockback = float(profile["knockback"])
    data.launch_force = float(profile["lift"])
    data.hitstun = float(profile["stun"])
    data.hitbox_radius = float(profile["radius"])
    data.movement_speed = float(profile["speed"])
    data.tracking_strength = float(profile["tracking"])
    data.effect = String(profile["effect"])
    data.behavior_evidence = "OUR_APPROXIMATION"
    data.tuning_evidence = "OUR_APPROXIMATION"
    return data

static func ids_for(id: String) -> PackedStringArray:
    var result: PackedStringArray = PackedStringArray()
    var primary: JutsuDefinition = build(id)
    var secondary: JutsuDefinition = build_secondary(id)
    if primary != null:
        result.append(primary.jutsu_id)
    if secondary != null:
        result.append(secondary.jutsu_id)
    return result

static func definitions_for(id: String) -> Array[JutsuDefinition]:
    var result: Array[JutsuDefinition] = []
    var primary: JutsuDefinition = build(id)
    var secondary: JutsuDefinition = build_secondary(id)
    if primary != null:
        result.append(primary)
    if secondary != null:
        result.append(secondary)
    return result
