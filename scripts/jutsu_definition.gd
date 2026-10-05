@tool
class_name JutsuDefinition
extends Resource
## Independent runtime tuning; clip startup/active/recovery come from the bake.
@export var jutsu_id: String = ""
@export var display_name: String = ""
@export_enum("hand", "projectile", "clones", "barrage", "trap", "burst") var strategy: String = "hand"
@export var animation_name: String = "rasengan"
@export var chakra_cost: float = 32.0
@export var cooldown: float = 1.5
@export var damage: float = 26.0
@export var knockback: float = 11.0
@export var launch_force: float = 4.5
@export var hitstun: float = 0.6
@export var hitbox_radius: float = 0.55
@export var movement_speed: float = 13.0
@export var tracking_strength: float = 7.0
@export var movement_lead: float = 0.1
@export var effect: String = "chakra"
@export var trap_lifetime: float = 10.0
@export var trap_width: float = 2.4
@export var fall_speed: float = 22.0
@export var behavior_evidence: String = "COMMUNITY_RESEARCH"
@export var tuning_evidence: String = "OUR_APPROXIMATION"
@export var source_url: String = ""

func animation_timing(manifest: Dictionary) -> Dictionary:
    var clips: Dictionary = manifest.get("clips", {})
    return clips.get(animation_name, {})
