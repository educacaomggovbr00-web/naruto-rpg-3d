class_name UltimateDefinition
extends Resource
## Timings are our animation-derived tuning, not measured Storm frame data.
@export var display_name: String = "Naruto's Ninja Handbook"
@export var chakra_cost: float = 80.0
@export var cooldown: float = 12.0
@export var entry_clip: String = "jutsu"
@export var entry_bone: String = "LeftHand"
@export var entry_damage: float = 3.0
@export var clash_duration: float = 1.0
@export var clash_presses: int = 4
# Independent opponent rhythm; these are mobile tuning, not measured Storm timings.
@export var cpu_clash_reaction_min: float = 0.18
@export var cpu_clash_reaction_max: float = 0.30
@export var cpu_clash_interval_min: float = 0.18
@export var cpu_clash_interval_max: float = 0.28
@export var dogpile_duration: float = 0.9
@export var chain_duration: float = 0.65
@export var finisher_clip: String = "attack_4"
@export var finisher_bone: String = "RightHand"
@export var finisher_damage: float = 28.0
