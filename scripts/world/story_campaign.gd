class_name StoryCampaign
extends RefCounted

const DATA_PATH: String = "res://assets/world/story_campaign.json"

static var _cache: Dictionary = {}

static func data() -> Dictionary:
    if not _cache.is_empty():
        return _cache
    if not FileAccess.file_exists(DATA_PATH):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    if not parsed is Dictionary:
        return {}
    var root: Dictionary = parsed
    if int(root.get("version", -1)) != 1 or not root.get("missions", []) is Array:
        return {}
    _cache = root
    return _cache

static func missions() -> Array:
    return data().get("missions", []) as Array

static func mission_at(index: int) -> Dictionary:
    var list: Array = missions()
    if index < 0 or index >= list.size():
        return {}
    var value: Variant = list[index]
    return value as Dictionary if value is Dictionary else {}

static func find(id: String) -> Dictionary:
    for value: Variant in missions():
        if value is Dictionary and String(value.get("id", "")) == id:
            return value as Dictionary
    return {}

static func count() -> int:
    return missions().size()

static func region_is_valid(region_id: String) -> bool:
    return region_id in ["konoha", "forest", "river", "valley"]

static func region_label(region_id: String) -> String:
    return {
        "konoha": "Aldeia da Folha",
        "forest": "Floresta de Treino",
        "river": "Fronteira do Rio",
        "valley": "Vale do Fim"
    }.get(region_id, "Região")

static func validate() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    var root: Dictionary = data()
    if root.is_empty():
        errors.append("campaign data missing")
        return errors
    var seen: Dictionary = {}
    var index: int = 0
    for value: Variant in missions():
        if not value is Dictionary:
            errors.append("mission %d is not a dictionary" % index)
            index += 1
            continue
        var mission: Dictionary = value
        var id: String = String(mission.get("id", ""))
        if id.is_empty() or seen.has(id):
            errors.append("invalid or duplicate mission id: " + id)
        seen[id] = true
        if CharacterCatalog.find(String(mission.get("opponent", ""))) == null:
            errors.append("unknown opponent: " + String(mission.get("opponent", "")))
        if String(mission.get("arena", "")) not in ["training", "courtyard"]:
            errors.append("invalid arena for " + id)
        if not region_is_valid(String(mission.get("region", ""))):
            errors.append("invalid region for " + id)
        if int(mission.get("reward_ryo", 0)) < 0 or int(mission.get("reward_xp", 0)) < 0:
            errors.append("negative reward for " + id)
        if int(mission.get("chapter", 0)) != index + 1:
            errors.append("chapter order mismatch for " + id)
        index += 1
    return errors
