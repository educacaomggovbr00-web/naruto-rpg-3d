@tool
class_name CharacterDefinition
extends Resource
@export var character_id: String = "naruto"
@export var display_name: String = "Naruto"
@export_file("*.glb") var model_path: String = "res://assets/characters/rigged.glb"
@export var visual_status: String = "DEVELOPMENT_ONLY_SHARED_RIG"
@export var moveset: MovesetDefinition
@export var jutsus: PackedStringArray = PackedStringArray(["demon", "rasengan", "clones", "whirlwind", "barrage"])
@export var movement_speed: float = 7.5
@export var sprint_speed: float = 12.0
@export var max_health: float = 100.0
@export var max_chakra: float = 100.0
@export var has_ultimate: bool = true
@export var has_awakening: bool = true
@export var energy_color: Color = Color(0.08, 0.55, 1.0)
