extends Node
## No alternative combat controller: missions use main.tscn unchanged.
var finished: bool = false
var boss_intro_timer: float = 0.0
var boss_banner: Label = null

func _ready() -> void:
    var audio: Node = Node.new()
    audio.name = "AudioManager"
    audio.set_script(preload("res://scripts/audio_manager.gd"))
    get_parent().add_child.call_deferred(audio)
    var layer: CanvasLayer = CanvasLayer.new()
    layer.layer = 30
    var button: Button = Button.new()
    button.text = "ALDEIA"
    button.position = Vector2(515, 12)
    button.custom_minimum_size = Vector2(155, 46)
    button.pressed.connect(GameFlow.enter_world)
    layer.add_child(button)
    add_child(layer)
    var versus: Button = Button.new()
    versus.text = "VERSUS"
    versus.position = Vector2(680, 12)
    versus.custom_minimum_size = Vector2(140, 46)
    versus.pressed.connect(GameFlow.enter_selection)
    layer.add_child(versus)
    if not GameFlow.pending_battle.is_empty() and int(GameFlow.progress.supplies) > 0:
        var fighter: Node = get_parent().get_node("Player")
        fighter.ninja_tools.stock.bomb += 1
        fighter.ninja_tools.stock.food_pills += 1
        GameFlow.progress.supplies -= 1
        GameFlow.save_progress()
    call_deferred("_apply_rpg_battle_setup")

func _apply_rpg_battle_setup() -> void:
    if GameFlow.versus_mode:
        return
    GameFlow.ensure_rpg_progress()
    var fighter: Node = get_parent().get_node("Player")
    var cpu: Node = get_parent().get_node("EnemyDummy")
    var level: int = int(GameFlow.progress.level)

    # Small persistent bonuses: progression matters without invalidating character kits.
    fighter.max_health += float(maxi(level - 1, 0)) * 2.0
    fighter.health = fighter.max_health
    fighter.max_chakra += float(maxi(level - 1, 0)) * 1.25
    fighter.chakra = fighter.max_chakra

    var inventory: Dictionary = GameFlow.progress.inventory
    var stock_map: Dictionary = {
        "ramen": "ramen",
        "food_pill": "food_pills",
        "bomb": "bomb",
        "kunai_pack": "kunai_rain"
    }
    var consumed: bool = false
    for inventory_id: String in stock_map:
        if int(inventory.get(inventory_id, 0)) <= 0:
            continue
        var stock_id: String = String(stock_map[inventory_id])
        fighter.ninja_tools.stock[stock_id] = int(fighter.ninja_tools.stock.get(stock_id, 0)) + 1
        inventory[inventory_id] = int(inventory[inventory_id]) - 1
        consumed = true
    if consumed:
        GameFlow.save_progress()

    if not GameFlow.is_story_battle():
        return

    var mission: Dictionary = GameFlow.current_story_battle_data()
    if mission.is_empty():
        return

    if bool(mission.get("boss", false)):
        var chapter: int = int(mission.get("chapter", 1))
        var boss_multiplier: float = 1.22 + minf(float(chapter) * 0.025, 0.18)
        cpu.max_health *= boss_multiplier
        cpu.health = cpu.max_health
        cpu.max_chakra *= 1.10
        cpu.chakra = cpu.max_chakra
        boss_intro_timer = 1.15
        _show_boss_intro(String(mission.get("title", "BOSS")), cpu)
    else:
        _show_story_intro(String(mission.get("title", "MISSÃO")))

func _show_story_intro(title: String) -> void:
    var layer: CanvasLayer = get_child(0) as CanvasLayer
    boss_banner = Label.new()
    boss_banner.text = "MISSÃO • " + title.to_upper()
    boss_banner.position = Vector2(320, 92)
    boss_banner.size = Vector2(640, 50)
    boss_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_banner.add_theme_font_size_override("font_size", 24)
    layer.add_child(boss_banner)
    boss_intro_timer = 0.85

func _show_boss_intro(title: String, cpu: Node) -> void:
    var layer: CanvasLayer = get_child(0) as CanvasLayer
    boss_banner = Label.new()
    boss_banner.text = "BOSS • " + title.to_upper()
    boss_banner.position = Vector2(260, 86)
    boss_banner.size = Vector2(760, 58)
    boss_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_banner.add_theme_font_size_override("font_size", 30)
    boss_banner.add_theme_color_override("font_color", Color("ffd089"))
    layer.add_child(boss_banner)
    var fighter: Node = get_parent().get_node("Player")
    if fighter.camera_rig.has_method("begin_sequence"):
        fighter.camera_rig.call("begin_sequence", cpu, 1.05)
        fighter.camera_rig.call("set_sequence_shot", "clash")

func _physics_process(_delta: float) -> void:
    if boss_intro_timer > 0.0:
        boss_intro_timer = maxf(boss_intro_timer - _delta, 0.0)
        if boss_intro_timer <= 0.0 and is_instance_valid(boss_banner):
            boss_banner.queue_free()
            boss_banner = null

    if finished or (GameFlow.pending_battle.is_empty() and not GameFlow.versus_mode):
        return
    var fighter: Node = get_parent().get_node("Player")
    var cpu: Node = get_parent().get_node("EnemyDummy")
    if fighter.defeated or not cpu.targetable:
        finished = true
        GameFlow.finish_battle(not cpu.targetable and not fighter.defeated)
