class_name WorldMissionDefinition
extends Resource
@export var mission_id: String = ""
@export var title: String = ""
@export_enum("collect", "battle") var kind: String = "collect"
@export var required_collectibles: PackedStringArray = PackedStringArray()
@export var reward_ryo: int = 100
