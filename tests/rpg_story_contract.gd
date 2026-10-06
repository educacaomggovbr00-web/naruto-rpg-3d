extends SceneTree

var failures: int = 0
var checks: int = 0
var flow: Node

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)

func frames(count: int) -> void:
    for _index: int in range(count):
        await physics_frame

func run() -> void:
    root.size = Vector2i(1280, 720)
    root.content_scale_size = Vector2i(1280, 720)
    flow = root.get_node("GameFlow")
    flow.save_path = "user://rpg_story_contract.json"
    flow.save_writable = true
    flow.progress = {
        "version": 1,
        "ryo": 100,
        "accepted": [],
        "completed": [],
        "collected": [],
        "supplies": 0,
        "position": [0, 0.95, 42],
        "yaw": PI
    }
    flow.ensure_rpg_progress()

    check(StoryCampaign.validate().is_empty(), "Story campaign data must validate")
    check(StoryCampaign.count() == 8, "Part 1 campaign must expose eight ordered story battles")
    check(String(StoryCampaign.mission_at(0).id) == "academy_spar", "Campaign must start at Academy rival battle")
    check(String(StoryCampaign.mission_at(7).id) == "final_valley", "Campaign must end at Final Valley")
    check(int(flow.progress.level) == 1 and flow.progress.inventory is Dictionary, "Legacy v1 save must gain RPG fields without reset")

    var gained: int = flow.add_xp(80, false)
    check(gained == 1 and int(flow.progress.level) == 2 and int(flow.progress.skill_points) == 1, "XP must level the ninja and award a skill point")
    check(flow.ninja_rank() == "GENIN", "Early progression must remain Genin")

    check(flow.buy_item("ramen", 20) and int(flow.progress.ryo) == 80, "RPG shop must spend ryō")
    check(flow.inventory_count("ramen") == 1, "Purchased item must enter persistent inventory")
    check(not flow.buy_item("forbidden", 1), "Unknown inventory items must be rejected")

    flow.world_region = "forest"
    var region: Node3D = load("res://region.tscn").instantiate() as Node3D
    root.add_child(region)
    await frames(10)
    var geometry: Node3D = region.get_node("Geometry")
    var actor: CharacterBody3D = region.get_node("Player")
    check(String(geometry.region_id) == "forest", "Region scene must build the requested map")
    check(int(geometry.draw_instances) <= 10, "External region must keep draw groups bounded for mobile")
    check(int(geometry.collision_count) > 10, "Region must have physical traversal collision")
    check(actor.rig_adapter.rig_loaded and actor.rig_adapter.real_animation_count == 27, "Regions must reuse the animated 3D fighter rig")
    region.queue_free()
    await frames(4)

    flow.progress.story_index = 0
    flow.progress.story_completed = []
    flow.progress.bosses = []
    flow.progress.unlocked_jutsus = ["demon"]
    flow.progress.ryo = 0
    flow.progress.level = 1
    flow.progress.xp = 0
    flow.progress.skill_points = 0
    var reward: Dictionary = flow.call("_complete_story_mission", "academy_spar")
    check(not reward.is_empty(), "Current story mission must complete exactly once")
    check(int(flow.progress.story_index) == 1 and flow.progress.story_completed.has("academy_spar"), "Story completion must advance campaign index")
    check(flow.progress.unlocked_jutsus.has("clones"), "Story reward must persist jutsu unlock")
    check(not flow.call("_complete_story_mission", "academy_spar"), "Story mission reward cannot be duplicated")

    var bell: Dictionary = flow.current_story_mission()
    check(String(bell.id) == "bell_test" and bool(bell.boss), "Second chapter must be marked as a boss encounter")

    flow.world_region = "konoha"
    flow.player_character = CharacterCatalog.NARUTO
    flow.cpu_character = CharacterCatalog.find("kakashi")
    flow.arena_id = "courtyard"
    flow.versus_mode = false
    flow.pending_story_id = "bell_test"
    flow.pending_battle = "story:bell_test"
    flow.battle_finished = false

    var battle: Node3D = load("res://main.tscn").instantiate() as Node3D
    root.add_child(battle)
    await frames(10)
    var bridge: Node = battle.get_node("BattleBridge")
    var cpu: Node = battle.get_node("EnemyDummy")
    var fighter: Node = battle.get_node("Player")
    check(bridge.boss_banner != null and String(bridge.boss_banner.text).begins_with("BOSS"), "Boss story battle must show cinematic boss presentation")
    check(float(cpu.max_health) > float(flow.cpu_character.max_health), "Boss encounter must scale CPU durability")
    check(is_instance_valid(fighter.camera_rig.cinematic_target), "Boss intro must use the existing combat camera sequence")
    battle.queue_free()
    await frames(4)

    check(flow.save_progress() == OK, "RPG progress must remain atomically saveable")
    var saved_level: int = int(flow.progress.level)
    flow.progress.level = 1
    check(flow.load_progress() and int(flow.progress.level) == saved_level, "RPG level must survive save reload")

    DirAccess.remove_absolute(flow.save_path)
    DirAccess.remove_absolute(flow.save_path + ".tmp")

    print("RPG STORY CONTRACT: %s (%d checks, %d failures)" % [
        "PASS" if failures == 0 else "FAIL",
        checks,
        failures
    ])
    quit(1 if failures > 0 else 0)
