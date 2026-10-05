class_name AwakeningDefinition
extends Resource

## Mobile-first transformation profile. Current values and generic VFX are
## OUR_APPROXIMATION unless a character-specific implementation says otherwise.
@export var awakening_id: String = "awakening"
@export var display_name: String = "Awakening"
@export var effect: String = "chakra"
@export var health_threshold: float = 0.30
@export var transform_duration: float = 0.85
@export var mode_duration: float = 16.0
@export var recharge_delay: float = 18.0
@export var movement_multiplier: float = 1.15
@export var damage_multiplier: float = 1.22
@export var chakra_regen_per_second: float = 2.0
@export var energy_color: Color = Color(0.08, 0.55, 1.0)
@export var evidence: String = "OUR_APPROXIMATION"
