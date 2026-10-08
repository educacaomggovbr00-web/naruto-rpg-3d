extends Node3D
const POINTS_PATH: String = "res://assets/world/village_points.json"
const TARGET_SCALE: Array[float] = [0.75, 0.90, 1.0]
const MIN_ADAPTIVE_SCALE: Array[float] = [0.70, 0.80, 0.90]
var points: Array[Area3D] = []
var nearest: Area3D = null
var scan_timer: float = 0.0
var spawn_checked: bool = false
var checkpoint_timer: float = 0.0
var toast_timer: float = 0.0
var map_open: bool = false
var quality: int = 1
var settings: ConfigFile = ConfigFile.new()
var adaptive_timer: float = 4.0
var render_scale: float = 0.76
var low_fps_streak: int = 0
var recovery_streak: int = 0
var emergency_mode: bool = false
var status_label: Label
var objective_label: Label
var context_label: Label
var message_label: Label
var fps_label: Label
var map_panel: Control
var quality_button: Button
var skill_button: Button
var skill_menu: CanvasLayer
var story_dialogue: CanvasLayer
var pending_story_start: bool = false
@onready var actor: CharacterBody3D = $Player
@onready var controls: Control = $HUD/WorldControls

func _ready() -> void:
    var presentation: Script = preload("res://scripts/anime_presentation.gd")
    $Environment.environment = presentation.environment(false, $Environment.environment)
    presentation.sun($Sun)
    var audio: Node = Node.new()
    audio.name = "AudioManager"
    audio.set_script(preload("res://scripts/audio_manager.gd"))
    add_child.call_deferred(audio)
    actor.global_position = GameFlow.resume_position()
    actor.rotation.y = float(GameFlow.progress.yaw)
    actor.last_safe_position = actor.global_position
    actor.camera_rig.yaw = actor.rotation.y + PI
    actor.camera_rig.focus = actor.global_position + Vector3.UP * 0.8
    actor.camera_rig.global_position = actor.camera_rig.focus
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(POINTS_PATH))
    if not parsed is Dictionary or int(parsed.get("version", -1)) != 1:
        push_error("Village point data missing or incompatible")
        return
    for data: Dictionary in parsed.points:
        var point: Area3D = Area3D.new()
        point.set_script(preload("res://scripts/world/world_point.gd"))
        point.data = data
        point.position = Vector3(float(data.position[0]), float(data.position[1]), float(data.position[2]))
        point.name = data.id
        add_child(point)
        points.append(point)
    _build_hud()
    story_dialogue = CanvasLayer.new()
    story_dialogue.name = "StoryDialogue"
    story_dialogue.set_script(preload("res://scripts/world/story_dialogue.gd"))
    add_child(story_dialogue)
    story_dialogue.finished.connect(_on_story_dialogue_finished)

    skill_menu = CanvasLayer.new()
    skill_menu.name = "SkillMenu"
    skill_menu.set_script(preload("res://scripts/world/skill_menu.gd"))
    add_child(skill_menu)
    skill_menu.closed.connect(_on_skill_menu_closed)

    GameFlow.progress_changed.connect(_refresh_progress)
    _refresh_progress()
    settings.load("user://graphics.cfg")
    apply_quality(clampi(int(settings.get_value("graphics", "quality", 0 if OS.has_feature("android") else 1)), 0, 2), false)
    if not GameFlow.return_message.is_empty():
        toast(GameFlow.return_message)
        GameFlow.return_message = ""
    elif not GameFlow.save_message.is_empty():
        toast(GameFlow.save_message)

func _label(screen_position: Vector2, dimensions: Vector2, font_size: int = 19) -> Label:
    var label: Label = Label.new()
    label.position = screen_position
    label.size = dimensions
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("fff0d5"))
    label.add_theme_color_override("font_shadow_color", Color("24372a"))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $HUD.add_child(label)
    return label

func _panel_style(background: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    return style

func _build_hud() -> void:
    var info_panel: PanelContainer = PanelContainer.new()
    info_panel.position = Vector2(14, 10)
    info_panel.size = Vector2(548, 102)
    info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.045, 0.065, 0.78), Color(0.28, 0.55, 0.61, 0.42)))
    $HUD.add_child(info_panel)
    $HUD.move_child(info_panel, 0)

    status_label = _label(Vector2(28, 18), Vector2(500, 32), 22)
    status_label.add_theme_color_override("font_color", Color("ffd38a"))

    objective_label = _label(Vector2(28, 52), Vector2(510, 52), 15)
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_label.add_theme_color_override("font_color", Color("d7e7e6"))

    message_label = _label(Vector2(290, 118), Vector2(700, 76), 19)
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.add_theme_color_override("font_color", Color("ffe3a8"))

    context_label = _label(Vector2(300, 646), Vector2(650, 48), 17)
    context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    context_label.add_theme_color_override("font_color", Color("fff0d4"))

    fps_label = _label(Vector2(885, 18), Vector2(275, 28), 13)
    fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    fps_label.add_theme_color_override("font_color", Color("c8dde3"))

    quality_button = Button.new()
    quality_button.position = Vector2(580, 14)
    quality_button.custom_minimum_size = Vector2(88, 34)
    quality_button.add_theme_font_size_override("font_size", 13)
    quality_button.add_theme_color_override("font_color", Color("f7ead0"))
    quality_button.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.12, 0.15, 0.88), Color(0.34, 0.66, 0.69, 0.55), 10))
    quality_button.add_theme_stylebox_override("hover", _panel_style(Color(0.05, 0.18, 0.21, 0.94), Color("d9903d"), 10))
    quality_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.02, 0.08, 0.10, 0.94), Color("d9903d"), 10))
    quality_button.pressed.connect(func() -> void: apply_quality((quality + 1) % 3))
    $HUD.add_child(quality_button)

    skill_button = Button.new()
    skill_button.text = "NINJA"
    skill_button.position = Vector2(680, 14)
    skill_button.custom_minimum_size = Vector2(112, 34)
    skill_button.add_theme_font_size_override("font_size", 13)
    skill_button.add_theme_color_override("font_color", Color("f7ead0"))
    skill_button.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.12, 0.15, 0.88), Color(0.34, 0.66, 0.69, 0.55), 10))
    skill_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.02, 0.08, 0.10, 0.94), Color("d9903d"), 10))
    skill_button.pressed.connect(toggle_skills)
    $HUD.add_child(skill_button)

    map_panel = Control.new()
    map_panel.set_script(preload("res://scripts/world/world_map.gd"))
    map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    map_panel.village = self
    map_panel.visible = false
    map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $HUD.add_child(map_panel)

func apply_quality(level: int, save: bool = true) -> void:
    quality = clampi(level, 0, 2)
    $Geometry.set_quality(quality)
    $Environment.environment.fog_enabled = quality > 0
    $Sun.shadow_enabled = quality > 0
    $Sun.directional_shadow_max_distance = [0.0, 18.0, 30.0][quality]
    get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    render_scale = TARGET_SCALE[quality]
    adaptive_timer = 4.0
    low_fps_streak = 0
    recovery_streak = 0
    emergency_mode = false
    get_viewport().scaling_3d_scale = render_scale
    get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][quality]
    quality_button.text = ["LOW", "MED", "HIGH"][quality]
    for point: Area3D in points:
        if point.actor == null or not is_instance_valid(point.actor.rig_adapter.model_instance):
            continue
        var meshes: Array[MeshInstance3D] = []
        point.actor.rig_adapter.call("_collect_mesh_instances", point.actor.rig_adapter.model_instance, meshes)
        for mesh: MeshInstance3D in meshes:
            mesh.visibility_range_end = [24.0, 34.0, 52.0][quality]
            mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if quality == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    if save:
        settings.set_value("graphics", "quality", quality)
        settings.save("user://graphics.cfg")

func _refresh_progress() -> void:
    GameFlow.ensure_rpg_progress()
    var hero_name: String = GameFlow.player_character.display_name.to_upper() if GameFlow.player_character != null else "NARUTO"
    status_label.text = "ALDEIA DA FOLHA  •  %s  •  NV %d %s  •  %d ryō  •  SP %d" % [
        hero_name,
        int(GameFlow.progress.level),
        GameFlow.ninja_rank(),
        int(GameFlow.progress.ryo),
        int(GameFlow.progress.skill_points)
    ]
    if not GameFlow.progress.completed.has("roof_scrolls"):
        if GameFlow.progress.accepted.has("roof_scrolls"):
            var collected: int = 0
            for id: String in GameFlow.MISSIONS.roof_scrolls.required_collectibles:
                if GameFlow.progress.collected.has(id):
                    collected += 1
            objective_label.text = "Pergaminhos nos telhados: %d / 3 — %s" % [collected, "volte ao instrutor" if collected == 3 else "consulte o MAPA"]
        else:
            objective_label.text = "Fale com o instrutor na academia. Depois, o ponto CAMPANHA abre a história principal."
    else:
        objective_label.text = GameFlow.story_objective_text() + "\n" + GameFlow.story_objective_detail()
    if is_instance_valid(map_panel):
        map_panel.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventJoypadButton and event.pressed:
        if event.is_action_pressed("pad_jutsu") and not map_open:
            interact()
        elif event.is_action_pressed("pad_lock"):
            toggle_map()
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_E and not map_open:
            interact()
        elif event.physical_keycode == KEY_M:
            toggle_map()

func _physics_process(delta: float) -> void:
    _update_adaptive_resolution(delta)
    if not spawn_checked:
        spawn_checked = true
        var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
        query.shape = actor.get_node("CollisionShape3D").shape
        query.transform = Transform3D(Basis.IDENTITY, actor.global_position + Vector3.UP * 0.06)
        query.collision_mask = 1
        if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
            actor.global_position = Vector3(0, 0.95, 42)
            actor.last_safe_position = actor.global_position
            actor.velocity = Vector3.ZERO
            actor.camera_rig.focus = actor.global_position + Vector3.UP * 0.8
            actor.camera_rig.global_position = actor.camera_rig.focus
            GameFlow.checkpoint(actor.global_position, actor.rotation.y)
            toast("Retornamos ao portão: o ponto anterior está ocupado.")
    if controls.map_queue > 0:
        controls.map_queue = 0
        if not skill_menu.visible:
            toggle_map()
    if controls.interact_queue > 0:
        controls.interact_queue = 0
        if not map_open and not skill_menu.visible:
            interact()
            if GameFlow.busy or not is_inside_tree():
                return
    toast_timer = maxf(toast_timer - delta, 0)
    message_label.visible = toast_timer > 0 and not map_open
    scan_timer -= delta
    checkpoint_timer -= delta
    if checkpoint_timer <= 0 and actor.is_on_floor():
        checkpoint_timer = 1.0
        GameFlow.checkpoint(actor.global_position, actor.rotation.y)
    if scan_timer <= 0:
        scan_timer = 0.12
        _find_interaction()
        fps_label.text = "%d FPS • %s%s • %.2fx • %d DC" % [
            Engine.get_frames_per_second(),
            ["LOW", "MED", "HIGH"][quality],
            "*" if emergency_mode else "",
            render_scale,
            int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
        ]
        for point: Area3D in points:
            if point.actor != null:
                var active_radius: float = [16.0, 22.0, 30.0][quality] * (0.72 if emergency_mode else 1.0)
                var active: bool = point.global_position.distance_squared_to(actor.global_position) < active_radius * active_radius
                if point.actor.rig_adapter.has_method("set_active"):
                    point.actor.rig_adapter.set_active(active)
                point.actor.rig_adapter.set_physics_process(active)
                point.actor.rig_adapter.set_process(active)
    if map_open:
        map_panel.queue_redraw()

func _update_adaptive_resolution(delta: float) -> void:
    if not _is_mobile_runtime():
        return
    adaptive_timer -= delta
    if adaptive_timer > 0.0:
        return
    adaptive_timer = 1.0
    var fps: float = float(Engine.get_frames_per_second())
    var target: float = TARGET_SCALE[quality]
    var minimum: float = MIN_ADAPTIVE_SCALE[quality]
    var next_scale: float = render_scale
    if fps > 1.0 and fps < 50.0:
        next_scale = maxf(render_scale - 0.06, minimum)
    elif fps >= 57.0:
        next_scale = minf(render_scale + 0.02, target)

    if not is_equal_approx(next_scale, render_scale):
        render_scale = next_scale
        get_viewport().scaling_3d_scale = render_scale

    if fps > 1.0 and fps < 42.0 and render_scale <= minimum + 0.01:
        low_fps_streak += 1
        recovery_streak = 0
    elif fps >= 56.0:
        low_fps_streak = 0
        recovery_streak += 1
    else:
        low_fps_streak = maxi(low_fps_streak - 1, 0)
        recovery_streak = 0

    if low_fps_streak >= 3 and not emergency_mode:
        _set_emergency_mode(true)
    elif emergency_mode and recovery_streak >= 8:
        _set_emergency_mode(false)

func _set_emergency_mode(enabled: bool) -> void:
    emergency_mode = enabled
    low_fps_streak = 0
    recovery_streak = 0

    $Sun.shadow_enabled = quality > 0 and not enabled
    $Sun.directional_shadow_max_distance = 0.0 if enabled else [0.0, 18.0, 30.0][quality]
    $Environment.environment.fog_enabled = quality > 0 and not enabled

    if enabled:
        render_scale = MIN_ADAPTIVE_SCALE[quality]
        get_viewport().scaling_3d_scale = render_scale

    quality_button.text = ["LOW", "MED", "HIGH"][quality] + ("*" if enabled else "")

func _is_mobile_runtime() -> bool:
    return (
        OS.has_feature("android")
        or OS.has_feature("ios")
        or OS.has_feature("web_android")
        or OS.has_feature("web_ios")
    )

func _find_interaction() -> void:
    nearest = null
    var best: float = 3.6 * 3.6
    for point: Area3D in points:
        if point.data.kind == "scroll":
            continue
        var distance: float = actor.global_position.distance_squared_to(point.global_position)
        if distance >= best:
            continue
        var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.4, point.global_position + Vector3.UP * 0.4, 1)
        if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
            continue
        best = distance
        nearest = point
    if nearest != null:
        var kind: String = String(nearest.data.get("kind", "talk"))
        controls.context_label = {
            "story": "MISSÃO",
            "travel": "VIAJAR",
            "shop": "COMPRAR",
            "item_shop": "COMPRAR",
            "battle": "LUTAR"
        }.get(kind, "FALAR")
    else:
        controls.context_label = "AÇÃO"
    controls.queue_redraw()
    context_label.text = "AÇÃO / E: " + String(nearest.data.label) if nearest != null else "PULO duas vezes para saltar entre telhados"
    context_label.visible = not map_open

func interact() -> void:
    _find_interaction()
    if nearest == null:
        toast("Aproxime-se de um morador para conversar.")
        return
    var data: Dictionary = nearest.data
    if data.kind == "quest":
        if GameFlow.claim_collection(data.mission):
            toast("Percurso concluído! +150 ryō. A campanha principal está disponível.")
        elif GameFlow.progress.completed.has(data.mission):
            toast("Bom trabalho. O ponto CAMPANHA perto da torre mostra sua próxima missão.")
        elif GameFlow.accept_mission(data.mission):
            toast("Recolha os três pergaminhos nos telhados e volte aqui. As escadas e o salto duplo ajudam no percurso.")
    elif data.kind == "battle":
        controls.release_all()
        var result: Error = GameFlow.start_battle(data.mission, actor.last_safe_position, actor.rotation.y)
        if result == OK:
            return
        toast("Não foi possível abrir o treino. Tente novamente.")
    elif data.kind == "story":
        var mission: Dictionary = GameFlow.current_story_mission()
        if mission.is_empty():
            toast("Campanha Parte 1 concluída. Continue explorando e treinando.")
        else:
            var region: String = String(mission.get("region", "konoha"))
            controls.release_all()
            if region == "konoha" and not GameFlow.story_dialogue_was_seen("intro"):
                pending_story_start = true
                GameFlow.mark_story_dialogue_seen("intro")
                if story_dialogue.call(
                    "play",
                    GameFlow.story_dialogue("intro"),
                    "CAP. %d • %s" % [int(mission.get("chapter", 1)), String(mission.get("title", "MISSÃO"))]
                ):
                    return
                pending_story_start = false
            var result: Error = (
                GameFlow.start_story_battle(actor.last_safe_position, actor.rotation.y)
                if region == "konoha"
                else GameFlow.enter_region(region)
            )
            if result == OK:
                return
            toast("Não foi possível abrir a próxima missão.")
    elif data.kind == "travel":
        var mission: Dictionary = GameFlow.current_story_mission()
        if mission.is_empty():
            toast("A campanha atual já foi concluída.")
        else:
            var region: String = String(mission.get("region", "konoha"))
            if region == "konoha":
                toast("Sua próxima missão ainda acontece na Aldeia da Folha.")
            else:
                controls.release_all()
                if GameFlow.enter_region(region) == OK:
                    return
                toast("A rota está indisponível agora.")
    elif data.kind == "item_shop":
        var item_id: String = String(data.get("item", "ramen"))
        var price: int = int(data.get("price", 20))
        if GameFlow.buy_item(item_id, price):
            toast("%s comprado. Estoque: %d." % [String(data.label), GameFlow.inventory_count(item_id)])
        else:
            toast(String(data.text) + " Saldo: %d ryō." % int(GameFlow.progress.ryo))
    elif data.kind == "shop":
        toast("Suprimento comprado para o próximo treino." if GameFlow.buy_supplies(int(data.price)) else String(data.text) + " Limite: 3. Saldo: %d ryō." % int(GameFlow.progress.ryo))
    elif data.kind == "talk":
        controls.release_all()
        if nearest.actor != null:
            var facing = actor.global_position - nearest.actor.global_position
            facing.y = 0
            if facing.length_squared() > .01:
                nearest.actor.rotation.y = atan2(facing.x,facing.z)
        var dialogue: Array = [{"speaker":String(data.label),"text":String(data.text)}]
        var mission = GameFlow.current_story_mission()
        if not mission.is_empty():
            dialogue.append({"speaker":String(data.label),"text":"Sua próxima missão é %s. Treine, prepare seus itens e siga o objetivo indicado no mapa." % String(mission.title)})
        else:
            dialogue.append({"speaker":String(data.label),"text":"A aldeia continua aberta para você. Há treino, lojas e desafios esperando."})
        story_dialogue.call("play",dialogue,"CONVERSA NA ALDEIA")
    else:
        toast(String(data.text))
    if not GameFlow.save_message.is_empty():
        toast(GameFlow.save_message)

func _on_story_dialogue_finished() -> void:
    if not pending_story_start:
        return
    pending_story_start = false
    var result: Error = GameFlow.start_story_battle(actor.last_safe_position, actor.rotation.y)
    if result != OK:
        toast("Não foi possível abrir a próxima missão.")

func toast(text: String) -> void:
    message_label.text = text
    toast_timer = 6.0
    message_label.visible = true

func toggle_skills() -> void:
    if skill_menu == null:
        return
    if skill_menu.visible:
        skill_menu.call("close")
        return
    if map_open:
        toggle_map()
    controls.release_all()
    actor.input_enabled = false
    actor.velocity = Vector3.ZERO
    skill_menu.call("open")

func _on_skill_menu_closed() -> void:
    actor.input_enabled = not map_open
    controls.release_all()
    _refresh_progress()

func toggle_map() -> void:
    map_open = not map_open
    controls.release_all()
    actor.input_enabled = not map_open
    actor.velocity = Vector3.ZERO
    map_panel.visible = map_open
    map_panel.queue_redraw()
    context_label.visible = not map_open
