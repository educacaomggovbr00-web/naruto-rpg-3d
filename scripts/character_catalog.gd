class_name CharacterCatalog
extends RefCounted
const NARUTO: CharacterDefinition = preload("res://assets/characters/definitions/naruto.tres")
const SASUKE: CharacterDefinition = preload("res://assets/characters/definitions/sasuke.tres")
const READY: Array[CharacterDefinition] = [NARUTO, SASUKE]
const PENDING: PackedStringArray = ["Sakura", "Kakashi", "Gaara"]
static func find(id: String) -> CharacterDefinition:
    for character: CharacterDefinition in READY:
        if character.character_id == id:
            return character
    return null
