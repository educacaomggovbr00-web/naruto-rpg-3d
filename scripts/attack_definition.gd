class_name AttackDefinition
extends Resource
## Runtime units are Godot metres/seconds; never assume PRM/XML units match.
@export var attack_id: String = ""
@export var display_name: String = ""
@export var animation_name: String = "attack_1"
@export var damage: float = 7.0
@export var knockback: float = 1.8
@export var launch_force: float = 0.0
@export var hitstun: float = 0.18
@export var evidence: String = "OUR_APPROXIMATION"
@export var source_url: String = ""
@export var camera_event: CameraEventDefinition

func animation_timing(manifest: Dictionary) -> Dictionary:
    # The baked animation contract remains the single timing authority.
    var clips: Dictionary = manifest.get("clips", {})
    return clips.get(animation_name, {})
