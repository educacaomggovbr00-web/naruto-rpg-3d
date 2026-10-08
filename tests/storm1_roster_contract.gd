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
    check(CharacterCatalog.READY.size() == 26, "Storm 1 must expose 25 playable fighters")
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
            check(definition.jutsus.size() >= 2, "Every roster slot must expose two character-owned specials: " + expected_id)
            for jutsu_id: String in definition.jutsus:
                var jutsu: JutsuDefinition = definition.find_jutsu(jutsu_id)
                check(jutsu != null, "Every roster special id must resolve to data: " + expected_id + "/" + jutsu_id)
                if jutsu != null:
                    check(jutsu.tuning_evidence == "OUR_APPROXIMATION", "Development special tuning must disclose approximation: " + expected_id + "/" + jutsu_id)
            check(definition.has_ultimate and definition.has_awakening, "Every roster slot needs its own Ultimate and Awakening capability: " + expected_id)
            check(definition.ultimate_definition != null and definition.awakening_definition != null, "Every non-Naruto slot needs power-mode data: " + expected_id)
            if definition.ultimate_definition != null:
                check(definition.ultimate_definition.evidence == "OUR_APPROXIMATION", "Roster Ultimate must disclose approximation: " + expected_id)
            if definition.awakening_definition != null:
                check(definition.awakening_definition.evidence == "OUR_APPROXIMATION", "Roster Awakening must disclose approximation: " + expected_id)
            check(definition.model_slot != null, "Placeholder needs a dedicated final-model slot: " + expected_id)
            check(definition.model_path == RosterModelSlotFactory.expected_path(expected_id), "Placeholder preferred path must target its own final GLB slot: " + expected_id)
            check(definition.model_fallback_path == RosterModelSlotFactory.SHARED_FALLBACK, "Placeholder must keep shared rig fallback: " + expected_id)
            check(definition.moveset != CharacterCatalog.NARUTO.moveset, "Roster slot must not borrow Naruto combo data: " + expected_id)
            check(definition.moveset.ground.size() == 4 and definition.moveset.aerial.size() == 4, "Roster slot needs full base ground/air chains: " + expected_id)
            check(definition.moveset.ground[0].attack_id.begins_with(expected_id + "_"), "Roster slot attacks must keep character-owned ids: " + expected_id)
            check(definition.moveset.ground[0].evidence == "OUR_APPROXIMATION", "Development roster tuning must disclose approximation: " + expected_id)

    check(seen.size() == 25, "All roster ids must be unique")
    for fighter: CharacterDefinition in CharacterCatalog.READY:
        check(fighter.jutsus.size() >= 2, "All 25 playable fighters need at least two selectable jutsus: " + fighter.character_id)
        for jutsu_id: String in fighter.jutsus:
            check(fighter.find_jutsu(jutsu_id) != null, "Selectable jutsu must resolve for " + fighter.character_id + ": " + jutsu_id)
        check(fighter.has_ultimate, "All 25 playable fighters need an Ultimate: " + fighter.character_id)
        check(fighter.has_awakening, "All 25 playable fighters need an Awakening: " + fighter.character_id)
        if fighter.character_id != "naruto":
            check(fighter.ultimate_definition != null, "Non-Naruto fighter needs generic Ultimate data: " + fighter.character_id)
            check(fighter.awakening_definition != null, "Non-Naruto fighter needs generic Awakening data: " + fighter.character_id)
    check(CharacterCatalog.find("gaara") != null, "Gaara must now be selectable")
    check(CharacterCatalog.find("itachi") != null, "Itachi must now be selectable")
    check(CharacterCatalog.find("kisame") != null, "Kisame must now be selectable")
    check(CharacterCatalog.find("not_in_storm1") == null, "Unknown fighter must stay invalid")

    print("STORM 1 ROSTER CONTRACT: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
    quit(0 if failures == 0 else 1)
