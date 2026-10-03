extends Node
## Shared exploration -> existing battle -> result -> exploration lifecycle.
signal progress_changed
const SAVE_VERSION: int = 1
const MISSIONS: Dictionary = {
    "roof_scrolls": preload("res://assets/world/roof_scrolls.tres"),
    "training": preload("res://assets/world/training.tres")
}
var player_character: CharacterDefinition = CharacterCatalog.NARUTO
var cpu_character: CharacterDefinition = CharacterCatalog.NARUTO
var arena_id: String = "training"
var versus_mode: bool = false

var save_path: String = "user://world_save.json"
var progress: Dictionary = {"version": SAVE_VERSION, "ryo": 0, "collected": [], "accepted": [], "completed": [], "supplies": 0, "position": [0, 0.95, 42], "yaw": PI}
var busy: bool = false
var pending_battle: String = ""
var battle_finished: bool = false
var save_writable: bool = true
var save_message: String = ""
var return_message: String = ""
var result_layer: CanvasLayer = null

func _ready() -> void:
    get_tree().scene_changed.connect(_scene_ready)
    load_progress()

func _scene_ready() -> void:
    busy = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
        enter_world()
        get_viewport().set_input_as_handled()

func _transition(path: String) -> Error:
    if busy:
        return ERR_BUSY
    busy = true
    _clear_result()
    var result: Error = get_tree().change_scene_to_file(path)
    if result != OK:
        busy = false
    return result

func enter_world() -> Error:
    if busy:
        return ERR_BUSY
    versus_mode = false
    pending_battle = ""
    battle_finished = false
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://world.tscn":
        return OK
    return _transition("res://world.tscn")

func enter_selection() -> Error:
    if busy:
        return ERR_BUSY
    versus_mode = false
    pending_battle = ""
    battle_finished = false
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
    pending_battle = ""
    battle_finished = false
    return _transition("res://main.tscn")

func checkpoint(position: Vector3, yaw: float) -> void:
    if not position.is_finite() or absf(position.x) > 75.0 or absf(position.z) > 61.0 or position.y < 0.8 or position.y > 25.0:
        return
    progress.position = [position.x, position.y, position.z]
    progress.yaw = yaw

func resume_position() -> Vector3:
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
    player_character = CharacterCatalog.NARUTO
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

func finish_battle(won: bool) -> bool:
    if (pending_battle.is_empty() and not versus_mode) or battle_finished or (not versus_mode and not MISSIONS.has(pending_battle)):
        return false
    battle_finished = true
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
    var shade: ColorRect = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.02, 0.05, 0.08, 0.88)
    result_layer.add_child(shade)
    var panel: VBoxContainer = VBoxContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-250, -110)
    panel.size = Vector2(500, 220)
    result_layer.add_child(panel)
    var label: Label = Label.new()
    label.text = ("VITÓRIA\n" if won else "DERROTA\n") + return_message
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 24)
    panel.add_child(label)
    for title: String in (["SELEÇÃO", "REVANCHE"] if versus_mode else ["VOLTAR À ALDEIA", "REPETIR TREINO"]):
        var button: Button = Button.new()
        button.text = title
        button.custom_minimum_size = Vector2(480, 62)
        button.pressed.connect(enter_selection if title == "SELEÇÃO" else enter_world if title == "VOLTAR À ALDEIA" else retry_battle)
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
    progress.ryo = clampi(int(parsed.get("ryo", 0)), 0, 999999)
    progress.supplies = clampi(int(parsed.get("supplies", 0)), 0, 3)
    progress.accepted = parsed.accepted
    progress.collected = parsed.collected
    progress.completed = parsed.completed
    checkpoint(Vector3(float(parsed.position[0]), float(parsed.position[1]), float(parsed.position[2])), float(parsed.get("yaw", 0.0)))
    return true

func _notification(what: int) -> void:
    if what != NOTIFICATION_APPLICATION_PAUSED:
        return
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://world.tscn":
        var player: CharacterBody3D = current.get_node("Player")
        checkpoint(player.last_safe_position, player.rotation.y)
        save_progress()
