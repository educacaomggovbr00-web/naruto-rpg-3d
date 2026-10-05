class_name RosterModelSlotDefinition
extends Resource

## Preferred/fallback model routing for roster fighters that are still waiting
## for a dedicated mobile-ready GLB.
@export_file("*.glb") var preferred_path: String = ""
@export_file("*.glb") var fallback_path: String = "res://assets/characters/rigged.glb"
@export var require_combat_bones: bool = true
@export var procedural_identity_on_fallback: bool = true
@export var target_height: float = 1.75
@export var yaw_degrees: float = 180.0
@export var evidence: String = "OUR_APPROXIMATION"
