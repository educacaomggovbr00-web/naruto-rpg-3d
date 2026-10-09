class_name HenriqueCampaign
extends RefCounted
## Separate original arc: legacy campaign and its save indices remain intact.
const PATH: String = "res://assets/world/henrique_campaign.json"
static var _cache: Dictionary = {}
static func missions() -> Array:
    if _cache.is_empty():
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
        if parsed is Dictionary:
            _cache = parsed
    return _cache.get("missions", [])
static func count() -> int:
    return missions().size()
static func mission_at(index: int) -> Dictionary:
    var list: Array = missions()
    return list[index] as Dictionary if index >= 0 and index < list.size() else {}
static func find(id: String) -> Dictionary:
    for mission: Dictionary in missions():
        if mission.id == id:
            return mission
    return {}
