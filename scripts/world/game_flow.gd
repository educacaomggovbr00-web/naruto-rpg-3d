extends Node
## Shared exploration -> story/mission battle -> result -> exploration lifecycle.

signal progress_changed

const SAVE_VERSION: int = 1
const MAX_LEVEL: int = 50
const MAX_SKILL_RANK: int = 5
const SKILL_IDS: PackedStringArray = ["vitality", "chakra", "power", "agility"]
const VALID_REGIONS: PackedStringArray = ["konoha", "forest", "river", "valley"]
const MISSIONS: Dictionary = {
    "roof_scrolls": preload("res://assets/world/roof_scrolls.tres"),
    "training": preload("res://assets/world/training.tres")
}

var player_character: CharacterDefinition = CharacterCatalog.HENRIQUE
var cpu_character: CharacterDefinition = CharacterCatalog.NARUTO
var arena_id: String = "training"
var versus_mode: bool = false
var world_region: String = "konoha"

var save_path: String = "user://world_save.json"
var progress: Dictionary = {
    "version": SAVE_VERSION,
    "ryo": 0,
    "collected": [],
    "accepted": [],
    "completed": [],
    "supplies": 0,
    "position": [0, 0.95, 42],
    "yaw": PI,
    "level": 1,
    "xp": 0,
    "skill_points": 0,
    "story_index": 0,
    "story_completed": [],
    "bosses": [],
    "unlocked_jutsus": ["demon"],
    "inventory": {"ramen": 0, "food_pill": 0, "bomb": 0, "kunai_pack": 0},
    "skills": {"vitality": 0, "chakra": 0, "power": 0, "agility": 0},
    "dialogue_seen": []
}

var busy: bool = false
var pending_battle: String = ""
var pending_story_id: String = ""
var battle_finished: bool = false
var save_writable: bool = true
var save_message: String = ""
var return_message: String = ""
var result_layer: CanvasLayer = null
var story_dialogue_seen: Dictionary = {}

func _ready() -> void:
    CharacterCatalog.initialize()
    get_tree().scene_changed.connect(_scene_ready)
    load_progress()
    ensure_rpg_progress()

func _scene_ready() -> void:
    busy = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
        enter_world()
        get_viewport().set_input_as_handled()

func ensure_rpg_progress() -> void:
    var defaults: Dictionary = {
        "level": 1,
        "xp": 0,
        "skill_points": 0,
        "story_index": 0,
        "story_completed": [],
        "bosses": [],
        "unlocked_jutsus": ["demon"],
        "inventory": {"ramen": 0, "food_pill": 0, "bomb": 0, "kunai_pack": 0},
        "skills": {"vitality": 0, "chakra": 0, "power": 0, "agility": 0},
        "dialogue_seen": []
    }
    for key: String in defaults:
        if not progress.has(key):
            progress[key] = defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
    if not progress.get("inventory") is Dictionary:
        progress.inventory = defaults.inventory.duplicate(true)
    for item_id: String in defaults.inventory:
        if not progress.inventory.has(item_id):
            progress.inventory[item_id] = 0

    if not progress.get("skills") is Dictionary:
        progress.skills = defaults.skills.duplicate(true)
    for skill_id: String in SKILL_IDS:
        if not progress.skills.has(skill_id):
            progress.skills[skill_id] = 0
        progress.skills[skill_id] = clampi(int(progress.skills[skill_id]), 0, MAX_SKILL_RANK)

    if not progress.get("dialogue_seen") is Array:
        progress.dialogue_seen = []
    story_dialogue_seen.clear()
    for key_value: Variant in progress.dialogue_seen:
        if key_value is String:
            story_dialogue_seen[String(key_value)] = true

    progress.level = clampi(int(progress.get("level", 1)), 1, MAX_LEVEL)
    progress.xp = maxi(int(progress.get("xp", 0)), 0)
    progress.skill_points = maxi(int(progress.get("skill_points", 0)), 0)
    progress.story_index = clampi(int(progress.get("story_index", 0)), 0, StoryCampaign.count())

func xp_to_next(level: int = -1) -> int:
    var current_level: int = int(progress.get("level", 1)) if level < 0 else level
    return 80 + maxi(current_level - 1, 0) * 40

func add_xp(amount: int, persist: bool = true) -> int:
    ensure_rpg_progress()
    if amount <= 0 or int(progress.level) >= MAX_LEVEL:
        return 0
    progress.xp += amount
    var levels_gained: int = 0
    while int(progress.level) < MAX_LEVEL and int(progress.xp) >= xp_to_next():
        progress.xp -= xp_to_next()
        progress.level += 1
        progress.skill_points += 1
        levels_gained += 1
    if int(progress.level) >= MAX_LEVEL:
        progress.level = MAX_LEVEL
        progress.xp = 0
    if persist:
        save_progress()
        progress_changed.emit()
    return levels_gained

func ninja_rank() -> String:
    ensure_rpg_progress()
    var level: int = int(progress.level)
    if level >= 35:
        return "JŌNIN"
    if level >= 20:
        return "CHŪNIN"
    if level >= 8:
        return "GENIN+"
    return "GENIN"

func skill_rank(skill_id: String) -> int:
    ensure_rpg_progress()
    if skill_id not in SKILL_IDS:
        return 0
    return int(progress.skills.get(skill_id, 0))

func upgrade_skill(skill_id: String) -> bool:
    ensure_rpg_progress()
    if skill_id not in SKILL_IDS or int(progress.skill_points) <= 0:
        return false
    var rank: int = skill_rank(skill_id)
    if rank >= MAX_SKILL_RANK:
        return false
    progress.skills[skill_id] = rank + 1
    progress.skill_points -= 1
    save_progress()
    progress_changed.emit()
    return true

func skill_label(skill_id: String) -> String:
    return {
        "vitality": "VIDA",
        "chakra": "CHAKRA",
        "power": "PODER",
        "agility": "AGILIDADE"
    }.get(skill_id, skill_id.to_upper())

func skill_bonus_text(skill_id: String) -> String:
    var rank: int = skill_rank(skill_id)
    match skill_id:
        "vitality":
            return "+%d HP" % (rank * 6)
        "chakra":
            return "+%d chakra" % (rank * 5)
        "power":
            return "+%d%% dano" % (rank * 4)
        "agility":
            return "+%.1f movimento" % (float(rank) * 0.3)
        _:
            return ""

func is_story_jutsu_unlocked(jutsu_id: String) -> bool:
    ensure_rpg_progress()
    return progress.unlocked_jutsus.has(jutsu_id)

func _story_unlock_label(milestone: String) -> String:
    if player_character == CharacterCatalog.HENRIQUE:
        # Later Naruto-only rewards stay recorded for saves/versus; do not show
        # unavailable Naruto moves as Henrique abilities.
        return {"clones": "CHIDORI", "barrage": "CORTE SUSANOO"}.get(milestone, "TREINO UCHIHA")
    return milestone.to_upper()

func buy_item(item_id: String, price: int, max_stock: int = 9) -> bool:
    ensure_rpg_progress()
    if item_id not in ["ramen", "food_pill", "bomb", "kunai_pack"]:
        return false
    if price <= 0 or int(progress.ryo) < price:
        return false
    var stock: int = int(progress.inventory.get(item_id, 0))
    if stock >= max_stock:
        return false
    progress.ryo -= price
    progress.inventory[item_id] = stock + 1
    save_progress()
    progress_changed.emit()
    return true

func inventory_count(item_id: String) -> int:
    ensure_rpg_progress()
    return int(progress.inventory.get(item_id, 0))

func current_story_mission() -> Dictionary:
    ensure_rpg_progress()
    return StoryCampaign.mission_at(int(progress.story_index))

func story_complete() -> bool:
    ensure_rpg_progress()
    return int(progress.story_index) >= StoryCampaign.count()

func story_objective_text() -> String:
    var mission: Dictionary = current_story_mission()
    if mission.is_empty():
        return "Campanha Parte 1 concluída. Continue treinando, explorando e melhorando seu ninja."
    return "Cap. %d — %s • %s" % [
        int(mission.get("chapter", 1)),
        String(mission.get("title", "Missão")),
        StoryCampaign.region_label(String(mission.get("region", "konoha")))
    ]

func story_objective_detail() -> String:
    var mission: Dictionary = current_story_mission()
    if mission.is_empty():
        return "Explore, treine e fortaleça seu ninja."
    return String(mission.get("objective", mission.get("summary", "Siga o objetivo da missão.")))

func story_dialogue(phase: String, mission_id: String = "") -> Array:
    var mission: Dictionary = current_story_mission() if mission_id.is_empty() else StoryCampaign.find(mission_id)
    if mission.is_empty():
        return []
    var key: String = phase + "_dialogue"
    var value: Variant = mission.get(key, [])
    if not value is Array:
        return []
    var lines: Array = (value as Array).duplicate(true)
    for line: Dictionary in lines:
        if line.get("speaker", "") == "Naruto":
            line.speaker = "Henrique Uchiha"
    return lines

func story_dialogue_key(phase: String, mission_id: String = "") -> String:
    var mission: Dictionary = current_story_mission() if mission_id.is_empty() else StoryCampaign.find(mission_id)
    return "" if mission.is_empty() else String(mission.get("id", "")) + ":" + phase

func story_dialogue_was_seen(phase: String, mission_id: String = "") -> bool:
    ensure_rpg_progress()
    var key: String = story_dialogue_key(phase, mission_id)
    return not key.is_empty() and bool(story_dialogue_seen.get(key, false))

func mark_story_dialogue_seen(phase: String, mission_id: String = "") -> void:
    ensure_rpg_progress()
    var key: String = story_dialogue_key(phase, mission_id)
    if key.is_empty():
        return
    story_dialogue_seen[key] = true
    if not progress.dialogue_seen.has(key):
        progress.dialogue_seen.append(key)
        save_progress()

func _transition(path: String) -> Error:
    if busy:
        return ERR_BUSY
    busy = true
    _clear_result()
    var result: Error = get_tree().change_scene_to_file(path)
    if result != OK:
        busy = false
    return result

func _clear_pending_battle() -> void:
    pending_battle = ""
    pending_story_id = ""
    battle_finished = false

func enter_world() -> Error:
    if busy:
        return ERR_BUSY
    versus_mode = false
    world_region = "konoha"
    _clear_pending_battle()
    ensure_rpg_progress()
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://world.tscn":
        return OK
    return _transition("res://world.tscn")

func enter_region(region_id: String) -> Error:
    if busy:
        return ERR_BUSY
    if region_id not in VALID_REGIONS or region_id == "konoha":
        return enter_world() if region_id == "konoha" else ERR_INVALID_PARAMETER
    versus_mode = false
    world_region = region_id
    _clear_pending_battle()
    ensure_rpg_progress()
    return _transition("res://region.tscn")

func return_to_exploration() -> Error:
    if busy:
        return ERR_BUSY
    versus_mode = false
    _clear_pending_battle()
    return _transition("res://world.tscn" if world_region == "konoha" else "res://region.tscn")

func enter_selection() -> Error:
    if busy:
        return ERR_BUSY
    versus_mode = false
    _clear_pending_battle()
    return _transition("res://selection.tscn")

func start_versus(player_id: String, cpu_id: String, stage: String) -> Error:
    if busy:
        return ERR_BUSY
    var selected_player: CharacterDefinition = CharacterCatalog.find(player_id)
    var selected_cpu: CharacterDefinition = CharacterCatalog.find(cpu_id)
    if selected_player == null or selected_cpu == null or stage not in ["training", "courtyard"]:
        return ERR_INVALID_PARAMETER
    player_character = selected_player
    cpu_character = selected_cpu
    arena_id = stage
    versus_mode = true
    pending_story_id = ""
    pending_battle = ""
    battle_finished = false
    return _transition("res://main.tscn")

func checkpoint(position: Vector3, yaw: float) -> void:
    if not position.is_finite() or absf(position.x) > 75.0 or absf(position.z) > 61.0 or position.y < 0.8 or position.y > 25.0:
        return
    progress.position = [position.x, position.y, position.z]
    progress.yaw = yaw

func resume_position() -> Vector3:
    if not progress.get("position", []) is Array or progress.position.size() != 3:
        return Vector3(0, 0.95, 42)
    var value: Array = progress.position
    return Vector3(float(value[0]), float(value[1]), float(value[2]))

func accept_mission(id: String) -> bool:
    if not MISSIONS.has(id) or progress.completed.has(id):
        return false
    if not progress.accepted.has(id):
        progress.accepted.append(id)
        save_progress()
        progress_changed.emit()
    return true

func collect_scroll(id: String, mission_id: String) -> bool:
    if not MISSIONS.has(mission_id) or not progress.accepted.has(mission_id) or progress.collected.has(id):
        return false
    var mission: Resource = MISSIONS[mission_id]
    if mission.kind != "collect" or not mission.required_collectibles.has(id):
        return false
    progress.collected.append(id)
    save_progress()
    progress_changed.emit()
    return true

func claim_collection(id: String) -> bool:
    if not MISSIONS.has(id) or not progress.accepted.has(id) or progress.completed.has(id):
        return false
    var mission: Resource = MISSIONS[id]
    if mission.kind != "collect":
        return false
    for collectible: String in mission.required_collectibles:
        if not progress.collected.has(collectible):
            return false
    _reward(id)
    return true

func _reward(id: String) -> void:
    if progress.completed.has(id):
        return
    progress.completed.append(id)
    progress.ryo += int(MISSIONS[id].reward_ryo)
    save_progress()
    progress_changed.emit()

func buy_supplies(price: int) -> bool:
    if price <= 0 or int(progress.ryo) < price or int(progress.supplies) >= 3:
        return false
    progress.ryo -= price
    progress.supplies += 1
    save_progress()
    progress_changed.emit()
    return true

func start_battle(id: String, position: Vector3, yaw: float) -> Error:
    if busy:
        return ERR_BUSY
    if not MISSIONS.has(id) or MISSIONS[id].kind != "battle":
        return ERR_INVALID_PARAMETER
    versus_mode = false
    pending_story_id = ""
    if player_character == null:
        player_character = CharacterCatalog.HENRIQUE
    cpu_character = CharacterCatalog.NARUTO
    arena_id = "training"
    accept_mission(id)
    checkpoint(position, yaw)
    save_progress()
    pending_battle = id
    battle_finished = false
    var result: Error = _transition("res://main.tscn")
    if result != OK:
        pending_battle = ""
    return result

func start_story_battle(position: Vector3 = Vector3.ZERO, yaw: float = 0.0) -> Error:
    if busy:
        return ERR_BUSY
    ensure_rpg_progress()
    var mission: Dictionary = current_story_mission()
    if mission.is_empty():
        return ERR_DOES_NOT_EXIST
    var opponent: CharacterDefinition = CharacterCatalog.find(String(mission.get("opponent", "")))
    var stage: String = String(mission.get("arena", "training"))
    if opponent == null or stage not in ["training", "courtyard"]:
        return ERR_INVALID_DATA
    versus_mode = false
    player_character = CharacterCatalog.HENRIQUE
    cpu_character = opponent
    arena_id = stage
    pending_story_id = String(mission.id)
    pending_battle = "story:" + pending_story_id
    battle_finished = false
    if world_region == "konoha" and position != Vector3.ZERO:
        checkpoint(position, yaw)
    save_progress()
    var result: Error = _transition("res://main.tscn")
    if result != OK:
        pending_story_id = ""
        pending_battle = ""
    return result

func is_story_battle() -> bool:
    return not pending_story_id.is_empty()

func current_story_battle_data() -> Dictionary:
    return StoryCampaign.find(pending_story_id) if is_story_battle() else {}

func _complete_story_mission(id: String) -> Dictionary:
    ensure_rpg_progress()
    var mission: Dictionary = current_story_mission()
    if mission.is_empty() or String(mission.get("id", "")) != id or progress.story_completed.has(id):
        return {}
    progress.story_completed.append(id)
    progress.ryo += int(mission.get("reward_ryo", 0))
    var levels_gained: int = add_xp(int(mission.get("reward_xp", 0)), false)
    var unlock: String = String(mission.get("unlock_jutsu", ""))
    if not unlock.is_empty() and not progress.unlocked_jutsus.has(unlock):
        progress.unlocked_jutsus.append(unlock)
    if bool(mission.get("boss", false)) and not progress.bosses.has(id):
        progress.bosses.append(id)
    progress.story_index = mini(int(progress.story_index) + 1, StoryCampaign.count())
    save_progress()
    progress_changed.emit()
    return {
        "ryo": int(mission.get("reward_ryo", 0)),
        "xp": int(mission.get("reward_xp", 0)),
        "levels": levels_gained,
        "unlock": unlock
    }

func finish_battle(won: bool) -> bool:
    var story_mode: bool = is_story_battle()
    if (pending_battle.is_empty() and not versus_mode and not story_mode) or battle_finished:
        return false
    if not versus_mode and not story_mode and not MISSIONS.has(pending_battle):
        return false

    battle_finished = true

    if story_mode:
        var mission: Dictionary = current_story_battle_data()
        if mission.is_empty():
            return false
        if won:
            var reward: Dictionary = _complete_story_mission(pending_story_id)
            if reward.is_empty():
                return_message = "Missão concluída; recompensa já registrada."
            else:
                return_message = "%s concluída • +%d ryō • +%d XP%s%s" % [
                    String(mission.get("title", "Missão")),
                    int(reward.ryo),
                    int(reward.xp),
                    " • NÍVEL +%d" % int(reward.levels) if int(reward.levels) > 0 else "",
                    " • JUTSU: " + _story_unlock_label(String(reward.unlock)) if not String(reward.unlock).is_empty() else ""
                ]
        else:
            return_message = "Missão falhou: %s. Você pode tentar novamente." % String(mission.get("title", "Missão"))
    else:
        var first_win: bool = not versus_mode and won and not progress.completed.has(pending_battle)
        if first_win:
            _reward(pending_battle)
        return_message = "Treino concluído: +%d ryō" % int(MISSIONS[pending_battle].reward_ryo) if first_win else "Treino concluído; recompensa já recebida." if won else "Derrota no treino. Tente novamente."
        if versus_mode:
            return_message = "%s vs %s" % [player_character.display_name, cpu_character.display_name]

    var current: Node = get_tree().current_scene
    if current != null:
        var feedback: Node = current.get_node_or_null("CombatFeedback")
        if feedback != null:
            Engine.time_scale = feedback.normal_time_scale
        var player: Node = current.get_node_or_null("Player")
        if player != null and player.has_method("_cancel_jutsu"):
            player.call("_cancel_jutsu")
            player.call("_cancel_attack")
        var audio: Node = current.get_node_or_null("AudioManager")
        if audio != null:
            audio.call("stop_all")
        current.process_mode = Node.PROCESS_MODE_DISABLED
    _show_result(won)
    return true

func _show_result(won: bool) -> void:
    result_layer = CanvasLayer.new()
    result_layer.layer = 80
    add_child(result_layer)

    var completed_story_id: String = pending_story_id
    var victory_dialogue: Array = story_dialogue("victory", completed_story_id) if won and not completed_story_id.is_empty() else []

    var shade: ColorRect = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.02, 0.05, 0.08, 0.88)
    result_layer.add_child(shade)

    var panel: VBoxContainer = VBoxContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-250, -130)
    panel.size = Vector2(500, 260)
    result_layer.add_child(panel)

    var label: Label = Label.new()
    label.text = ("VITÓRIA\n" if won else "DERROTA\n") + return_message
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 22)
    panel.add_child(label)

    if not victory_dialogue.is_empty():
        var story_box: Label = Label.new()
        var dialogue_text: PackedStringArray = PackedStringArray()
        for value: Variant in victory_dialogue:
            if value is Dictionary:
                var line: Dictionary = value
                dialogue_text.append("%s: %s" % [String(line.get("speaker", "")), String(line.get("text", ""))])
        story_box.text = "\n".join(dialogue_text)
        story_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        story_box.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        story_box.add_theme_font_size_override("font_size", 15)
        panel.add_child(story_box)
        mark_story_dialogue_seen("victory", completed_story_id)

    var titles: Array[String] = []
    if versus_mode:
        titles.append("SELEÇÃO")
        titles.append("REVANCHE")
    else:
        titles.append("VOLTAR À REGIÃO" if world_region != "konoha" else "VOLTAR À ALDEIA")
        titles.append("REPETIR MISSÃO" if is_story_battle() else "REPETIR TREINO")
    for title: String in titles:
        var button: Button = Button.new()
        button.text = title
        button.custom_minimum_size = Vector2(480, 62)
        button.pressed.connect(
            enter_selection
            if title == "SELEÇÃO"
            else return_to_exploration
            if title.begins_with("VOLTAR")
            else retry_battle
        )
        panel.add_child(button)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func retry_battle() -> Error:
    if (pending_battle.is_empty() and not versus_mode) or busy:
        return ERR_BUSY
    battle_finished = false
    return _transition("res://main.tscn")

func _clear_result() -> void:
    if is_instance_valid(result_layer):
        result_layer.queue_free()
    result_layer = null

func save_progress() -> Error:
    if not save_writable:
        return ERR_UNAVAILABLE
    ensure_rpg_progress()
    var temporary: String = save_path + ".tmp"
    var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        save_message = "Não foi possível salvar o progresso."
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(progress))
    file.flush()
    file.close()
    var result: Error = DirAccess.rename_absolute(temporary, save_path)
    if result != OK:
        save_message = "Não foi possível finalizar o save."
    return result

func load_progress() -> bool:
    save_writable = true
    save_message = ""
    if not FileAccess.file_exists(save_path):
        ensure_rpg_progress()
        return false

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
    if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION:
        save_writable = false
        save_message = "Save incompatível; arquivo preservado."
        return false

    for key: String in ["accepted", "collected", "completed", "position"]:
        if not parsed.get(key) is Array:
            save_writable = false
            save_message = "Save inválido; arquivo preservado."
            return false

    if parsed.position.size() != 3:
        save_writable = false
        return false
    for component: Variant in parsed.position:
        if not (component is float or component is int) or not is_finite(float(component)):
            save_writable = false
            return false

    for key: String in ["accepted", "collected", "completed"]:
        for id: Variant in parsed[key]:
            if not id is String:
                save_writable = false
                return false

    if not (parsed.get("ryo", 0) is float or parsed.get("ryo", 0) is int) or not (parsed.get("supplies", 0) is float or parsed.get("supplies", 0) is int):
        save_writable = false
        return false
    if not (parsed.get("yaw", 0.0) is float or parsed.get("yaw", 0.0) is int) or not is_finite(float(parsed.get("yaw", 0.0))):
        save_writable = false
        return false

    for optional_array: String in ["story_completed", "bosses", "unlocked_jutsus", "dialogue_seen"]:
        if parsed.has(optional_array) and not parsed[optional_array] is Array:
            save_writable = false
            return false
    if parsed.has("inventory") and not parsed.inventory is Dictionary:
        save_writable = false
        return false
    if parsed.has("skills") and not parsed.skills is Dictionary:
        save_writable = false
        return false

    progress = parsed.duplicate(true)
    progress.ryo = clampi(int(parsed.get("ryo", 0)), 0, 999999)
    progress.supplies = clampi(int(parsed.get("supplies", 0)), 0, 3)
    ensure_rpg_progress()
    checkpoint(
        Vector3(float(parsed.position[0]), float(parsed.position[1]), float(parsed.position[2])),
        float(parsed.get("yaw", 0.0))
    )
    return true

func _notification(what: int) -> void:
    if what != NOTIFICATION_APPLICATION_PAUSED:
        return
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://world.tscn":
        var player: CharacterBody3D = current.get_node("Player")
        checkpoint(player.last_safe_position, player.rotation.y)
        save_progress()
