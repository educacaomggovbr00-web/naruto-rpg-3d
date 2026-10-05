@tool
class_name CharacterDefinition
extends Resource
@export var character_id: String = "naruto"
@export var display_name: String = "Naruto"
@export_file("*.glb") var model_path: String = "res://assets/characters/rigged.glb"
@export_file("*.glb") var model_fallback_path: String = ""
@export var visual_status: String = "DEVELOPMENT_ONLY_SHARED_RIG"
@export_multiline var summary: String = "Base de combate em desenvolvimento."
@export var stylized_material: bool = false
@export_enum("rig_3d", "sprite_2_5d") var visual_mode: String = "rig_3d"
@export_file("*.png") var sprite_atlas_path: String = ""
@export var sprite_cell_size: Vector2i = Vector2i(192, 192)
@export var sprite_pixel_size: float = 0.013
@export var sprite_offset: Vector3 = Vector3(0.0, 0.30, 0.0)
@export var model_auto_scale: bool = true
@export var model_ground_to_collision: bool = false
@export var model_scale_multiplier: float = 1.0
@export var model_target_height: float = 1.75
@export var model_offset: Vector3 = Vector3(0.0, -0.95, 0.0)
@export var model_yaw_degrees: float = 180.0
@export var model_fallback_import_scale: float = 0.01
@export var prefer_native_locomotion: bool = false
@export var idle_animation_override: String = ""
@export var moveset: MovesetDefinition
@export var jutsus: PackedStringArray = PackedStringArray(["demon", "rasengan", "clones", "whirlwind", "barrage"])
@export var jutsu_definitions: Array[JutsuDefinition] = []
@export var movement_speed: float = 7.5
@export var sprint_speed: float = 12.0
@export var max_health: float = 100.0
@export var max_chakra: float = 100.0
@export var has_ultimate: bool = true
@export var has_awakening: bool = true
@export var ultimate_definition: UltimateDefinition
@export var awakening_definition: AwakeningDefinition
@export var energy_color: Color = Color(0.08, 0.55, 1.0)

func find_jutsu(id: String) -> JutsuDefinition:
    for definition: JutsuDefinition in jutsu_definitions:
        if definition.jutsu_id == id:
            return definition
    return null
