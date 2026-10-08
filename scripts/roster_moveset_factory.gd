class_name RosterMovesetFactory
extends RefCounted

## Development combat profiles for Storm 1 roster slots that do not yet have
## character-specific authored choreography. Values are OUR_APPROXIMATION and
## keep every fighter mechanically distinct without borrowing Naruto's moveset.
const PROFILES: Dictionary = {
    "henrique": {"speed": 8.0, "sprint": 12.5, "health": 105.0, "damage": [6.5, 8.5, 11.0, 16.5], "knockback": 9.0, "lift": 8.5, "stun": 0.24, "third": "attack_3"},
    "shikamaru": {"speed": 7.1, "sprint": 11.2, "health": 96.0, "damage": [5.5, 7.0, 9.0, 13.5], "knockback": 7.0, "lift": 7.2, "stun": 0.23, "third": "attack_3"},
    "choji": {"speed": 6.3, "sprint": 10.2, "health": 118.0, "damage": [8.0, 10.5, 13.0, 19.0], "knockback": 10.5, "lift": 8.8, "stun": 0.30, "third": "attack_4"},
    "ino": {"speed": 7.5, "sprint": 11.9, "health": 94.0, "damage": [5.8, 7.8, 9.8, 14.2], "knockback": 7.5, "lift": 7.8, "stun": 0.20, "third": "attack_3"},
    "rock_lee": {"speed": 8.6, "sprint": 13.8, "health": 102.0, "damage": [6.2, 7.4, 9.2, 15.0], "knockback": 8.2, "lift": 9.6, "stun": 0.17, "third": "air_attack_2"},
    "neji": {"speed": 8.0, "sprint": 12.6, "health": 100.0, "damage": [6.0, 8.2, 10.6, 15.5], "knockback": 7.2, "lift": 8.4, "stun": 0.24, "third": "attack_3"},
    "tenten": {"speed": 7.7, "sprint": 12.1, "health": 95.0, "damage": [5.8, 7.6, 10.0, 14.8], "knockback": 8.6, "lift": 7.5, "stun": 0.20, "third": "air_attack_2"},
    "shino": {"speed": 7.0, "sprint": 11.2, "health": 101.0, "damage": [5.6, 7.4, 9.6, 14.0], "knockback": 7.4, "lift": 7.2, "stun": 0.26, "third": "attack_3"},
    "kiba": {"speed": 8.4, "sprint": 13.3, "health": 99.0, "damage": [6.4, 8.2, 10.4, 15.8], "knockback": 9.0, "lift": 8.8, "stun": 0.18, "third": "air_attack_2"},
    "hinata": {"speed": 7.8, "sprint": 12.2, "health": 97.0, "damage": [5.8, 7.8, 10.2, 15.0], "knockback": 7.0, "lift": 8.0, "stun": 0.25, "third": "attack_3"},
    "gaara": {"speed": 6.5, "sprint": 10.5, "health": 112.0, "damage": [7.0, 9.2, 12.0, 18.0], "knockback": 10.0, "lift": 9.0, "stun": 0.31, "third": "attack_4"},
    "kankuro": {"speed": 6.9, "sprint": 11.0, "health": 104.0, "damage": [6.5, 8.5, 11.0, 16.5], "knockback": 9.2, "lift": 8.0, "stun": 0.27, "third": "attack_3"},
    "temari": {"speed": 7.1, "sprint": 11.3, "health": 102.0, "damage": [6.8, 9.0, 11.8, 17.2], "knockback": 11.0, "lift": 8.2, "stun": 0.28, "third": "attack_4"},
    "might_guy": {"speed": 8.5, "sprint": 13.7, "health": 108.0, "damage": [6.8, 8.4, 10.8, 17.0], "knockback": 9.3, "lift": 9.8, "stun": 0.18, "third": "air_attack_2"},
    "jiraiya": {"speed": 7.0, "sprint": 11.2, "health": 112.0, "damage": [7.0, 9.0, 11.5, 17.5], "knockback": 9.5, "lift": 8.5, "stun": 0.26, "third": "attack_3"},
    "tsunade": {"speed": 6.9, "sprint": 11.0, "health": 120.0, "damage": [8.5, 11.0, 14.0, 21.0], "knockback": 12.0, "lift": 10.0, "stun": 0.32, "third": "attack_4"},
    "hiruzen": {"speed": 7.3, "sprint": 11.6, "health": 106.0, "damage": [6.5, 8.5, 11.0, 16.5], "knockback": 8.8, "lift": 8.4, "stun": 0.24, "third": "attack_3"},
    "orochimaru": {"speed": 7.6, "sprint": 12.0, "health": 108.0, "damage": [6.4, 8.7, 11.5, 17.0], "knockback": 9.2, "lift": 8.8, "stun": 0.27, "third": "attack_3"},
    "kabuto": {"speed": 7.8, "sprint": 12.3, "health": 99.0, "damage": [6.0, 8.2, 10.6, 15.8], "knockback": 8.0, "lift": 8.3, "stun": 0.23, "third": "attack_3"},
    "kimimaro": {"speed": 7.9, "sprint": 12.5, "health": 110.0, "damage": [6.8, 9.0, 11.8, 18.0], "knockback": 10.0, "lift": 9.2, "stun": 0.26, "third": "air_attack_2"},
    "itachi": {"speed": 8.2, "sprint": 12.9, "health": 98.0, "damage": [6.2, 8.3, 10.8, 16.2], "knockback": 8.4, "lift": 8.6, "stun": 0.22, "third": "attack_3"},
    "kisame": {"speed": 6.8, "sprint": 10.9, "health": 116.0, "damage": [8.0, 10.0, 13.2, 19.5], "knockback": 11.5, "lift": 9.0, "stun": 0.30, "third": "attack_4"}
}

static func profile(id: String) -> Dictionary:
    return PROFILES.get(id, {})

static func build_moveset(id: String) -> MovesetDefinition:
    var data: Dictionary = profile(id)
    if data.is_empty():
        return null

    var values: Array = data["damage"]
    var moveset: MovesetDefinition = MovesetDefinition.new()

    var light_event: CameraEventDefinition = _camera_event(0.065, 1.0, 0.032, "normal")
    var heavy_event: CameraEventDefinition = _camera_event(0.14, 3.0, 0.052, "normal")
    var launch_event: CameraEventDefinition = _camera_event(0.13, 2.7, 0.055, "launcher")
    var slam_event: CameraEventDefinition = _camera_event(0.17, 3.8, 0.07, "slam")

    var ground: Array[AttackDefinition] = []
    ground.append(_attack(id + "_ground1", "attack_1", float(values[0]), 1.8, 0.0, float(data["stun"]), light_event))
    ground.append(_attack(id + "_ground2", "attack_2", float(values[1]), 2.4, 0.0, float(data["stun"]), light_event))
    ground.append(_attack(id + "_ground3", String(data["third"]), float(values[2]), 3.0, 0.0, float(data["stun"]), light_event))
    ground.append(_attack(id + "_ground4", "attack_4", float(values[3]), float(data["knockback"]), 0.0, float(data["stun"]) + 0.18, heavy_event))

    var aerial: Array[AttackDefinition] = []
    aerial.append(_attack(id + "_air1", "air_attack_1", float(values[0]), 1.8, 0.0, float(data["stun"]), light_event))
    aerial.append(_attack(id + "_air2", "air_attack_2", float(values[1]), 2.4, 0.0, float(data["stun"]), light_event))
    aerial.append(_attack(id + "_air3", "air_attack_3", float(values[2]), 3.0, 0.0, float(data["stun"]), light_event))
    aerial.append(_attack(id + "_air4", "air_attack_4", float(values[3]), 5.0, -13.0, float(data["stun"]) + 0.22, slam_event))

    moveset.ground = ground
    moveset.aerial = aerial
    moveset.neutral_finisher = ground[3]
    moveset.up_finisher = _attack(id + "_up_finisher", "attack_4", float(values[3]), 5.0, float(data["lift"]), float(data["stun"]) + 0.18, launch_event)
    moveset.down_finisher = _attack(id + "_down_finisher", "attack_4", float(values[3]), 5.0, -4.0, float(data["stun"]) + 0.42, slam_event)
    moveset.side_finisher = _attack(id + "_side_finisher", "attack_4", float(values[3]), float(data["knockback"]) + 2.0, 2.0, float(data["stun"]) + 0.18, launch_event)
    moveset.branch_step = 3
    return moveset

static func _attack(id: String, clip: String, damage: float, knockback: float, lift: float, hitstun: float, camera: CameraEventDefinition) -> AttackDefinition:
    var attack: AttackDefinition = AttackDefinition.new()
    attack.attack_id = id
    attack.display_name = id.replace("_", " ").capitalize()
    attack.animation_name = clip
    attack.damage = damage
    attack.knockback = knockback
    attack.launch_force = lift
    attack.hitstun = hitstun
    attack.evidence = "OUR_APPROXIMATION"
    attack.camera_event = camera
    return attack

static func _camera_event(shake: float, fov: float, stop: float, kind: String) -> CameraEventDefinition:
    var event: CameraEventDefinition = CameraEventDefinition.new()
    event.shake = shake
    event.fov_kick = fov
    event.hit_stop = stop
    event.impact_kind = kind
    return event
