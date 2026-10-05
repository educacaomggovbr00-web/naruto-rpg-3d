class_name RosterPowerFactory
extends RefCounted

## Development Ultimate/Awakening identities for the 24 non-Naruto fighters.
## Names are kit direction; gameplay tuning and shared choreography are
## OUR_APPROXIMATION until bespoke animation/VFX passes are authored.
const ULTIMATES: Dictionary = {
    "sasuke": ["Lion Barrage Finale", "lightning", 84.0, 34.0, 0.62, 12.0],
    "sakura": ["Cherry Blossom Crash", "earth", 80.0, 38.0, 0.70, 13.0],
    "shikamaru": ["Shadow Strangle Finish", "shadow", 78.0, 30.0, 0.90, 7.0],
    "choji": ["Butterfly Boulder Crash", "earth", 82.0, 40.0, 0.72, 15.0],
    "ino": ["Mind Break Finish", "mind", 78.0, 29.0, 0.95, 6.0],
    "rock_lee": ["Primary Lotus Finale", "taijutsu", 80.0, 37.0, 0.68, 13.0],
    "neji": ["Eight Trigrams 64 Palms", "chakra", 80.0, 35.0, 0.82, 9.0],
    "tenten": ["Twin Dragons Arsenal", "steel", 78.0, 34.0, 0.70, 11.0],
    "shino": ["Parasitic Insect Prison", "insect", 80.0, 32.0, 0.88, 7.0],
    "kiba": ["Fang Over Fang Finale", "wind", 80.0, 36.0, 0.70, 13.0],
    "hinata": ["Gentle Step Finale", "chakra", 78.0, 33.0, 0.84, 8.0],
    "gaara": ["Sand Burial Finale", "sand", 84.0, 41.0, 0.86, 12.0],
    "kankuro": ["Puppet Secret Finale", "puppet", 80.0, 36.0, 0.80, 10.0],
    "temari": ["Great Sickle Storm", "wind", 82.0, 38.0, 0.74, 15.0],
    "kakashi": ["Lightning Blade Finale", "lightning", 84.0, 38.0, 0.68, 13.0],
    "might_guy": ["Hidden Lotus Finale", "taijutsu", 82.0, 40.0, 0.66, 14.0],
    "jiraiya": ["Toad Flame Barrage", "fire", 84.0, 39.0, 0.78, 12.0],
    "tsunade": ["Heaven Shattering Blow", "earth", 82.0, 44.0, 0.75, 16.0],
    "hiruzen": ["Five Style Barrage", "fire", 84.0, 39.0, 0.78, 12.0],
    "orochimaru": ["Serpent Assault Finale", "snake", 82.0, 38.0, 0.86, 10.0],
    "kabuto": ["Medical Scalpel Finale", "chakra", 78.0, 34.0, 0.80, 9.0],
    "kimimaro": ["Bracken Dance Finale", "bone", 82.0, 41.0, 0.76, 14.0],
    "itachi": ["Sharingan Flame Finale", "fire", 84.0, 40.0, 0.84, 11.0],
    "kisame": ["Great Shark Flood", "water", 84.0, 42.0, 0.78, 15.0]
}

const AWAKENINGS: Dictionary = {
    "sasuke": ["Sharingan Focus", "lightning", Color(0.42, 0.62, 1.0), 1.18, 1.25, 16.0],
    "sakura": ["Inner Strength", "earth", Color(1.0, 0.34, 0.58), 1.10, 1.34, 15.0],
    "shikamaru": ["Shadow Tactics", "shadow", Color(0.28, 0.18, 0.42), 1.12, 1.20, 17.0],
    "choji": ["Butterfly Power", "earth", Color(0.92, 0.48, 0.18), 1.10, 1.36, 15.0],
    "ino": ["Mind Focus", "mind", Color(0.92, 0.34, 0.78), 1.14, 1.20, 16.0],
    "rock_lee": ["Gate Release", "taijutsu", Color(0.28, 1.0, 0.38), 1.28, 1.28, 14.0],
    "neji": ["Byakugan Focus", "chakra", Color(0.72, 0.90, 1.0), 1.18, 1.24, 16.0],
    "tenten": ["Arsenal Focus", "steel", Color(0.76, 0.82, 0.90), 1.16, 1.22, 16.0],
    "shino": ["Swarm Focus", "insect", Color(0.38, 0.34, 0.20), 1.12, 1.23, 17.0],
    "kiba": ["Beast Mode", "wind", Color(0.74, 0.92, 0.92), 1.24, 1.25, 15.0],
    "hinata": ["Byakugan Resolve", "chakra", Color(0.74, 0.82, 1.0), 1.18, 1.23, 16.0],
    "gaara": ["Sand Armor Surge", "sand", Color(0.82, 0.58, 0.24), 1.08, 1.30, 18.0],
    "kankuro": ["Puppet Master Focus", "puppet", Color(0.72, 0.60, 0.42), 1.12, 1.25, 17.0],
    "temari": ["Wind Mastery", "wind", Color(0.56, 0.94, 0.88), 1.18, 1.26, 16.0],
    "kakashi": ["Sharingan Focus", "lightning", Color(0.45, 0.82, 1.0), 1.18, 1.27, 16.0],
    "might_guy": ["Gate Release", "taijutsu", Color(0.34, 1.0, 0.30), 1.27, 1.30, 14.0],
    "jiraiya": ["Sage Resolve", "fire", Color(1.0, 0.36, 0.12), 1.14, 1.30, 17.0],
    "tsunade": ["Hundred-Heal Resolve", "earth", Color(0.92, 0.40, 0.70), 1.10, 1.38, 17.0],
    "hiruzen": ["Professor's Resolve", "fire", Color(1.0, 0.48, 0.12), 1.14, 1.28, 17.0],
    "orochimaru": ["Serpent Body", "snake", Color(0.42, 0.82, 0.30), 1.18, 1.28, 17.0],
    "kabuto": ["Medical Focus", "chakra", Color(0.42, 0.94, 0.82), 1.16, 1.24, 17.0],
    "kimimaro": ["Curse Power", "bone", Color(0.78, 0.76, 0.92), 1.18, 1.32, 15.0],
    "itachi": ["Sharingan Focus", "fire", Color(0.96, 0.18, 0.12), 1.18, 1.30, 16.0],
    "kisame": ["Shark Skin Surge", "water", Color(0.12, 0.56, 1.0), 1.14, 1.34, 17.0]
}

static func build_ultimate(id: String) -> UltimateDefinition:
    var values: Array = ULTIMATES.get(id, [])
    if values.is_empty():
        return null
    var data: UltimateDefinition = UltimateDefinition.new()
    data.ultimate_id = id + "_ultimate"
    data.display_name = String(values[0])
    data.effect = String(values[1])
    data.chakra_cost = float(values[2])
    data.finisher_damage = float(values[3])
    data.entry_damage = 4.0
    data.hitbox_radius = float(values[4])
    data.finisher_knockback = float(values[5])
    data.entry_clip = "jutsu"
    data.finisher_clip = "attack_4"
    data.sequence_duration = 1.10
    data.evidence = "OUR_APPROXIMATION"
    return data

static func build_awakening(id: String) -> AwakeningDefinition:
    var values: Array = AWAKENINGS.get(id, [])
    if values.is_empty():
        return null
    var data: AwakeningDefinition = AwakeningDefinition.new()
    data.awakening_id = id + "_awakening"
    data.display_name = String(values[0])
    data.effect = String(values[1])
    data.energy_color = values[2]
    data.movement_multiplier = float(values[3])
    data.damage_multiplier = float(values[4])
    data.mode_duration = float(values[5])
    data.health_threshold = 0.30
    data.transform_duration = 0.82
    data.recharge_delay = 18.0
    data.chakra_regen_per_second = 2.5
    data.evidence = "OUR_APPROXIMATION"
    return data
