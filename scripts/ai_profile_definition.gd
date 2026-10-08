class_name AIProfileDefinition
extends Resource

## CPU personality parameters. These are project-authored gameplay tuning and
## never claimed as extracted Storm AI values.
@export_enum("balanced", "rushdown", "zoner", "controller", "counter", "power") var archetype: String = "balanced"
@export var preferred_distance: float = 3.5
@export var aggression: float = 0.65
@export var guard_bias: float = 0.22
@export var dodge_bias: float = 0.22
@export var strafe_bias: float = 0.30
@export var jutsu_bias: float = 0.42
@export var dash_bias: float = 0.30
@export var ultimate_bias: float = 0.10
@export var awakening_bias: float = 0.40
@export var charge_threshold: float = 34.0
@export var decision_speed: float = 1.0
@export var projectile_reaction: float = 0.70
@export var substitution_chance: float = 0.18
@export var reaction_delay: float = 0.14
@export var evidence: String = "OUR_APPROXIMATION"
