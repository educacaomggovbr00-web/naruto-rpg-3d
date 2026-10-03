extends SceneTree

var checks: int = 0
var failures: int = 0

const EXPECTED_IDS: PackedStringArray = [
    "naruto", "sasuke", "sakura", "shikamaru", "choji", "ino",
    "rock_lee", "neji", "tenten", "shino", "kiba", "hinata",
    "gaara", "kankuro", "temari", "kakashi", "might_guy", "jiraiya",
    "tsunade", "hiruzen", "orochimaru", "kabuto", "kimimaro",
    "itachi", "kisame"
]

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func run() -> void:
    CharacterCatalog.initialize()
    check(CharacterCatalog.READY.size() == 25, "Storm 1 must expose 25 playable fighters")
    check(CharacterCatalog.SUPPORT_ONLY.size() == 10, "Storm 1 support-only roster must keep 10 entries")

    var seen: Dictionary = {}
    for index: int in range(EXPECTED_IDS.size()):
        var expected_id: String = EXPECTED_IDS[index]
        var definition: CharacterDefinition = CharacterCatalog.READY[index]
        check(definition.character_id == expected_id, "Roster order mismatch at %d: %s" % [index, expected_id])
        check(not seen.has(definition.character_id), "Duplicate roster id: " + definition.character_id)
        seen[definition.character_id] = true
        check(CharacterCatalog.find(expected_id) == definition, "Catalog lookup must return the same definition: " + expected_id)
        check(definition.moveset != null, "Every selectable fighter needs a combat moveset: " + expected_id)
        check(not definition.model_path.is_empty(), "Every selectable fighter needs a preview/runtime model path: " + expected_id)

        if definition.visual_status == "STORM1_ROSTER_SLOT_SHARED_PLACEHOLDER_RIG":
            check(definition.jutsus.is_empty(), "Placeholder must not inherit Naruto jutsus: " + expected_id)
            check(not definition.has_ultimate and not definition.has_awakening, "Placeholder must not inherit Naruto cinematic modes: " + expected_id)
            check(definition.model_path == "res://assets/characters/rigged.glb", "Placeholder should use shared development rig until replaced: " + expected_id)

    check(seen.size() == 25, "All roster ids must be unique")
    check(CharacterCatalog.find("gaara") != null, "Gaara must now be selectable")
    check(CharacterCatalog.find("itachi") != null, "Itachi must now be selectable")
    check(CharacterCatalog.find("kisame") != null, "Kisame must now be selectable")
    check(CharacterCatalog.find("not_in_storm1") == null, "Unknown fighter must stay invalid")

    print("STORM 1 ROSTER CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
