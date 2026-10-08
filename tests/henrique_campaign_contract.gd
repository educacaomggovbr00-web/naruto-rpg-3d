extends SceneTree
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func run() -> void:
    var flow: Node = root.get_node("GameFlow")
    var saved: Dictionary = flow.progress.duplicate(true)
    var path: String = flow.save_path
    flow.save_path = "user://henrique_campaign_contract.json"
    flow.save_writable = true
    flow.ensure_rpg_progress()
    var classic_index: int = int(flow.progress.story_index)
    var classic_completed: Array = flow.progress.story_completed.duplicate()
    flow.campaign_id = "henrique"
    flow.progress.henrique_story_index = 0
    flow.progress.henrique_story_completed = []
    flow.progress.henrique_choices = {}
    check(HenriqueCampaign.count() == 6, "Original arc contains six chapters")
    for mission: Dictionary in HenriqueCampaign.missions():
        check(CharacterCatalog.find(String(mission.opponent)) != null, "Campaign opponent remains in existing cast")
        check(StoryCampaign.region_is_valid(String(mission.region)), "Campaign uses existing exploration regions")
        check(mission.arena in ["training", "courtyard"], "Chapter arena exists")
    flow.mark_story_dialogue_seen("intro")
    check(not flow.story_dialogue_was_seen("intro"), "Interrupted choice reopens even if intro was marked seen")
    var dialogue: CanvasLayer = CanvasLayer.new()
    dialogue.set_script(load("res://scripts/world/story_dialogue.gd"))
    root.add_child(dialogue)
    dialogue.play(flow.story_dialogue("intro"))
    for index: int in range(3):
        dialogue.body_label.visible_characters = -1 # Finish reveal before moving to the next line.
        dialogue.advance()
    check(dialogue.choice_pending and paused, "Story pauses for a real player choice")
    dialogue.advance()
    check(dialogue.index == 3, "Continue cannot skip unresolved choice")
    dialogue._choose(HenriqueCampaign.mission_at(0).intro_dialogue[3].choices[1])
    check(flow.current_story_mission().opponent == "sasuke", "Rival choice changes chapter's battle opponent")
    check(not flow.record_story_choice("team"), "Saved choice cannot be overwritten")
    dialogue.close()
    dialogue.queue_free()
    check(not paused, "Dialogue returns to exploration")
    for index: int in range(6):
        var mission: Dictionary = flow.current_story_mission()
        var reward: Dictionary = flow._complete_story_mission(String(mission.id))
        check(not reward.is_empty(), "Chapter awards existing RPG progression")
        check(flow._complete_story_mission(String(mission.id)).is_empty(), "Chapter reward cannot be duplicated")
    check(flow.story_complete() and flow.progress.henrique_story_completed.size() == 6, "Henrique arc completes independently")
    check(flow.progress.story_index == classic_index and flow.progress.story_completed == classic_completed, "Legacy campaign progression is preserved")
    check(flow.load_progress(), "Extended version-1 save reloads")
    check(flow.progress.henrique_choices.get("hc_signal") == "rival" and flow.progress.henrique_story_index == 6, "Choice and chapters survive reload")
    flow.campaign_id = "classic"
    check(flow.current_story_mission() == StoryCampaign.mission_at(classic_index), "Legacy campaign remains accessible")
    flow.progress = saved
    flow.save_path = path
    flow.ensure_rpg_progress()
    DirAccess.remove_absolute("user://henrique_campaign_contract.json")
    await process_frame
    print("HENRIQUE CAMPAIGN CONTRACT: " + ("PASS" if failures == 0 else "FAIL"))
    quit(0 if failures == 0 else 1)
