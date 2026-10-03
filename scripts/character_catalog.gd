class_name CharacterCatalog
extends RefCounted

const NARUTO: CharacterDefinition = preload("res://assets/characters/definitions/naruto.tres")
const SASUKE: CharacterDefinition = preload("res://assets/characters/definitions/sasuke.tres")
const SAKURA: CharacterDefinition = preload("res://assets/characters/definitions/sakura.tres")
const KAKASHI: CharacterDefinition = preload("res://assets/characters/definitions/kakashi.tres")

# Dedicated visuals: supplied textured Naruto and three project-authored meshes.
# Download research/status is recorded in docs/CHARACTER_MODEL_DOWNLOAD_AUDIT.md.
const AUTHORED_VISUALS: Array[CharacterDefinition] = [NARUTO, SASUKE, SAKURA, KAKASHI]

# Storm 1 has 25 playable fighters. The remaining entries are activated as
# development roster slots using the shared rig + shared base combo until each
# fighter receives its own model, moveset, jutsu, Ultimate and Awakening data.

# Original Storm 1 support-only roster. Kept separate from playable selection.
const SUPPORT_ONLY: PackedStringArray = [
    "Asuma Sarutobi",
    "Kurenai Yuhi",
    "Anko Mitarashi",
    "Shizune",
    "Hashirama Senju",
    "Tobirama Senju",
    "Kidomaru",
    "Sakon/Ukon",
    "Jirobo",
    "Tayuya"
]

static var READY: Array[CharacterDefinition] = [NARUTO, SASUKE, SAKURA, KAKASHI]
static var _initialized: bool = false

static func initialize() -> void:
    if _initialized:
        return
    _initialized = true
    # Insert the remaining fighters in the original Storm 1 roster order.
    var ordered: Array[CharacterDefinition] = [
        NARUTO,
        SASUKE,
        SAKURA,
        _placeholder("shikamaru", "Shikamaru Nara"),
        _placeholder("choji", "Choji Akimichi"),
        _placeholder("ino", "Ino Yamanaka"),
        _placeholder("rock_lee", "Rock Lee"),
        _placeholder("neji", "Neji Hyuga"),
        _placeholder("tenten", "Tenten"),
        _placeholder("shino", "Shino Aburame"),
        _placeholder("kiba", "Kiba Inuzuka"),
        _placeholder("hinata", "Hinata Hyuga"),
        _placeholder("gaara", "Gaara"),
        _placeholder("kankuro", "Kankuro"),
        _placeholder("temari", "Temari"),
        KAKASHI,
        _placeholder("might_guy", "Might Guy"),
        _placeholder("jiraiya", "Jiraiya"),
        _placeholder("tsunade", "Tsunade"),
        _placeholder("hiruzen", "Hiruzen Sarutobi"),
        _placeholder("orochimaru", "Orochimaru"),
        _placeholder("kabuto", "Kabuto Yakushi"),
        _placeholder("kimimaro", "Kimimaro"),
        _placeholder("itachi", "Itachi Uchiha"),
        _placeholder("kisame", "Kisame Hoshigaki")
    ]
    READY = ordered

static func _placeholder(id: String, name: String) -> CharacterDefinition:
    var definition: CharacterDefinition = CharacterDefinition.new()
    definition.character_id = id
    definition.display_name = name
    definition.model_path = "res://assets/characters/rigged.glb"
    definition.visual_status = "STORM1_ROSTER_SLOT_SHARED_PLACEHOLDER_RIG"
    definition.summary = "%s — slot jogável do elenco original de Storm 1. Usa temporariamente o rig e combo-base compartilhados; moveset, jutsus, Ultimate, Awakening e visual próprios ainda serão substituídos." % name
    definition.stylized_material = false
    definition.moveset = NARUTO.moveset
    definition.jutsus = PackedStringArray()
    definition.has_ultimate = false
    definition.has_awakening = false
    return definition

static func find(id: String) -> CharacterDefinition:
    initialize()
    for character: CharacterDefinition in READY:
        if character.character_id == id:
            return character
    return null
