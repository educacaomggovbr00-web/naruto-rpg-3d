class_name RosterVisualProfileDefinition
extends Resource

## Lightweight runtime identity for fighters still sharing the development rig.
## This is an original project-authored approximation layer, not extracted art.
@export var primary_color: Color = Color(0.20, 0.35, 0.70)
@export var secondary_color: Color = Color(0.08, 0.10, 0.14)
@export var accent_color: Color = Color(0.85, 0.85, 0.85)
@export var tint_strength: float = 0.28
@export var accessories: PackedStringArray = PackedStringArray()
@export var evidence: String = "OUR_APPROXIMATION"
