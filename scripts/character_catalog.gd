class_name CharacterCatalog
extends RefCounted

const NARUTO: CharacterDefinition = preload("res://assets/characters/definitions/naruto.tres")
const SASUKE: CharacterDefinition = preload("res://assets/characters/definitions/sasuke.tres")
const SAKURA: CharacterDefinition = preload("res://assets/characters/definitions/sakura.tres")
const KAKASHI: CharacterDefinition = preload("res://assets/characters/definitions/kakashi.tres")
const HENRIQUE: CharacterDefinition = preload("res://assets/characters/definitions/henrique.tres")

# Dedicated visuals: supplied textured Naruto and three project-authored meshes.
# Download research/status is recorded in docs/CHARACTER_MODEL_DOWNLOAD_AUDIT.md.
const AUTHORED_VISUALS: Array[CharacterDefinition] = [NARUTO, SASUKE, SAKURA, KAKASHI, HENRIQUE]

# Storm 1 has 25 playable fighters. The remaining entries use the shared
# development rig for now, but each receives an independent approximation
# moveset so no roster slot borrows Naruto's combo data. Jutsu/Ultimate/
# Awakening and final choreography are still filled character by character.

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
        _roster_fighter("shikamaru", "Shikamaru Nara"),
        _roster_fighter("choji", "Choji Akimichi"),
        _roster_fighter("ino", "Ino Yamanaka"),
        _roster_fighter("rock_lee", "Rock Lee"),
        _roster_fighter("neji", "Neji Hyuga"),
        _roster_fighter("tenten", "Tenten"),
        _roster_fighter("shino", "Shino Aburame"),
        _roster_fighter("kiba", "Kiba Inuzuka"),
        _roster_fighter("hinata", "Hinata Hyuga"),
        _roster_fighter("gaara", "Gaara"),
        _roster_fighter("kankuro", "Kankuro"),
        _roster_fighter("temari", "Temari"),
        KAKASHI,
        _roster_fighter("might_guy", "Might Guy"),
        _roster_fighter("jiraiya", "Jiraiya"),
        _roster_fighter("tsunade", "Tsunade"),
        _roster_fighter("hiruzen", "Hiruzen Sarutobi"),
        _roster_fighter("orochimaru", "Orochimaru"),
        _roster_fighter("kabuto", "Kabuto Yakushi"),
        _roster_fighter("kimimaro", "Kimimaro"),
        _roster_fighter("itachi", "Itachi Uchiha"),
        _roster_fighter("kisame", "Kisame Hoshigaki")
    ]
    for fighter: CharacterDefinition in ordered:
        _complete_power_kit(fighter)
    HenriqueKit.complete(HENRIQUE)
    # Keep original roster indices stable for saved selections and existing UI.
    ordered.append(HENRIQUE)
    READY = ordered

static func _roster_fighter(id: String, name: String) -> CharacterDefinition:
    var definition: CharacterDefinition = CharacterDefinition.new()
    definition.character_id = id
    definition.display_name = name
    definition.model_slot = RosterModelSlotFactory.build(id)
    definition.model_path = definition.model_slot.preferred_path
    definition.model_fallback_path = definition.model_slot.fallback_path
    definition.model_target_height = definition.model_slot.target_height
    definition.model_yaw_degrees = definition.model_slot.yaw_degrees
    definition.visual_status = "ORIGINAL_STYLIZED_SKINNED_MODEL"
    definition.summary = "%s — modelo estilizado próprio, roupa e acessórios skinados, 65 ossos e mãos articuladas. Interpretação original OUR_APPROXIMATION; fallback preservado." % name
    definition.stylized_material = true
    definition.model_ground_to_collision = true

    var profile: Dictionary = RosterMovesetFactory.profile(id)
    definition.moveset = RosterMovesetFactory.build_moveset(id)
    definition.movement_speed = float(profile.get("speed", 7.5))
    definition.sprint_speed = float(profile.get("sprint", 12.0))
    definition.max_health = float(profile.get("health", 100.0))

    definition.jutsus = RosterJutsuFactory.ids_for(id)
    definition.jutsu_definitions = RosterJutsuFactory.definitions_for(id)
    definition.has_ultimate = true
    definition.has_awakening = true
    definition.ultimate_definition = RosterPowerFactory.build_ultimate(id)
    definition.awakening_definition = RosterPowerFactory.build_awakening(id)
    if definition.awakening_definition != null:
        definition.energy_color = definition.awakening_definition.energy_color
    definition.ai_profile = RosterAIProfileFactory.build(id)
    definition.visual_profile = RosterVisualProfileFactory.build(id)
    return definition

static func _complete_power_kit(definition: CharacterDefinition) -> void:
    if definition == null:
        return

    definition.ai_profile = RosterAIProfileFactory.build(definition.character_id)

    if definition.character_id == "naruto":
        return

    if definition.jutsus.size() < 2:
        var extra: JutsuDefinition = RosterJutsuFactory.build_secondary(definition.character_id)
        if extra != null and definition.find_jutsu(extra.jutsu_id) == null:
            definition.jutsu_definitions.append(extra)
            definition.jutsus.append(extra.jutsu_id)

    definition.ultimate_definition = RosterPowerFactory.build_ultimate(definition.character_id)
    definition.awakening_definition = RosterPowerFactory.build_awakening(definition.character_id)
    definition.has_ultimate = definition.ultimate_definition != null
    definition.has_awakening = definition.awakening_definition != null

static func find(id: String) -> CharacterDefinition:
    initialize()
    for character: CharacterDefinition in READY:
        if character.character_id == id:
            return character
    return null
