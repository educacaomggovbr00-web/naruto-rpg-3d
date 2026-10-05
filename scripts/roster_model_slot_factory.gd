class_name RosterModelSlotFactory
extends RefCounted

const SLOT_IDS: PackedStringArray = [
    "shikamaru", "choji", "ino", "rock_lee", "neji", "tenten", "shino",
    "kiba", "hinata", "gaara", "kankuro", "temari", "might_guy", "jiraiya",
    "tsunade", "hiruzen", "orochimaru", "kabuto", "kimimaro", "itachi", "kisame"
]

const SHARED_FALLBACK: String = "res://assets/characters/rigged.glb"
const FINAL_ROOT: String = "res://assets/characters/final"

static func build(id: String) -> RosterModelSlotDefinition:
    if id not in SLOT_IDS:
        return null

    var slot: RosterModelSlotDefinition = RosterModelSlotDefinition.new()
    slot.preferred_path = "%s/%s/%s_mobile.glb" % [FINAL_ROOT, id, id]
    slot.fallback_path = SHARED_FALLBACK
    slot.require_combat_bones = true
    slot.procedural_identity_on_fallback = true
    slot.target_height = 1.75
    slot.yaw_degrees = 180.0
    slot.evidence = "OUR_APPROXIMATION"
    return slot

static func expected_path(id: String) -> String:
    var slot: RosterModelSlotDefinition = build(id)
    return slot.preferred_path if slot != null else ""

static func ready(id: String) -> bool:
    var path: String = expected_path(id)
    return not path.is_empty() and ResourceLoader.exists(path)
