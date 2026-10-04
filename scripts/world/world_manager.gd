extends Node3D
const POINTS_PATH: String = "res://assets/world/village_points.json"
const TARGET_SCALE: Array[float] = [0.70, 0.85, 1.0]
const MIN_ADAPTIVE_SCALE: Array[float] = [0.58, 0.68, 0.78]
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
var render_scale: float = 0.85
var status_label: Label
var objective_label: Label
var context_label: Label
var message_label: Label
var fps_label: Label
var map_panel: Control
var quality_button: Button
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
    GameFlow.progress_changed.connect(_refresh_progress)
    _refresh_progress()
    settings.load("user://graphics.cfg")
    apply_quality(clampi(int(settings.get_value("graphics", "quality", 1)), 0, 2), false)
    if not GameFlow.return_message.is_empty():
        toast(GameFlow.return_message)
        GameFlow.return_message = ""
    elif not GameFlow.save_message.is_empty():
        toast(GameFlow.save_message)

func _label(position: Vector2, dimensions: Vector2, font_size: int = 19) -> Label:
    var label: Label = Label.new()
    label.position = position
    label.size = dimensions
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color("fff0d5"))
    label.add_theme_color_override("font_shadow_color", Color("24372a"))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $HUD.add_child(label)
    return label

func _build_hud() -> void:
    status_label = _label(Vector2(20, 16), Vector2(530, 35), 24)
    objective_label = _label(Vector2(20, 54), Vector2(790, 55), 18)
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label = _label(Vector2(280, 116), Vector2(720, 80), 20)
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    context_label = _label(Vector2(300, 645), Vector2(650, 55), 18)
    context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    fps_label = _label(Vector2(1040, 14), Vector2(110, 30), 16)
    quality_button = Button.new()
    quality_button.position = Vector2(570, 12)
    quality_button.custom_minimum_size = Vector2(95, 36)
    quality_button.pressed.connect(func() -> void: apply_quality((quality + 1) % 3))
    $HUD.add_child(quality_button)
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
    $Sun.directional_shadow_max_distance = [0.0, 24.0, 40.0][quality]
    get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    render_scale = TARGET_SCALE[quality]
    adaptive_timer = 4.0
    get_viewport().scaling_3d_scale = render_scale
    quality_button.text = ["LOW", "MED", "HIGH"][quality]
    for point: Area3D in points:
        if point.actor == null or not is_instance_valid(point.actor.rig_adapter.model_instance):
            continue
        var meshes: Array[MeshInstance3D] = []
        point.actor.rig_adapter.call("_collect_mesh_instances", point.actor.rig_adapter.model_instance, meshes)
        for mesh: MeshInstance3D in meshes:
            mesh.visibility_range_end = [28.0, 42.0, 65.0][quality]
            mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if quality == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    if save:
        settings.set_value("graphics", "quality", quality)
        settings.save("user://graphics.cfg")

func _refresh_progress() -> void:
    status_label.text = "ALDEIA DA FOLHA | %d ryō" % int(GameFlow.progress.ryo)
    if GameFlow.progress.completed.has("roof_scrolls"):
        objective_label.text = "Percurso concluído. Treine na praça ou visite a loja de ferramentas."
    elif GameFlow.progress.accepted.has("roof_scrolls"):
        var collected: int = 0
        for id: String in GameFlow.MISSIONS.roof_scrolls.required_collectibles:
            if GameFlow.progress.collected.has(id):
                collected += 1
        objective_label.text = "Pergaminhos nos telhados: %d / 3 — %s" % [collected, "volte ao instrutor" if collected == 3 else "consulte o MAPA"]
    else:
        objective_label.text = "Fale com o instrutor na academia ao norte. MAPA mostra os pontos da aldeia."
    if is_instance_valid(map_panel):
        map_panel.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
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
        toggle_map()
    if controls.interact_queue > 0:
        controls.interact_queue = 0
        if not map_open:
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
        fps_label.text = "%d FPS" % Engine.get_frames_per_second()
        for point: Area3D in points:
            if point.actor != null:
                point.actor.rig_adapter.set_physics_process(point.global_position.distance_squared_to(actor.global_position) < pow([18.0, 25.0, 35.0][quality], 2.0))
    if map_open:
        map_panel.queue_redraw()

func _update_adaptive_resolution(delta: float) -> void:
    if not _is_mobile_runtime():
        return
    adaptive_timer -= delta
    if adaptive_timer > 0.0:
        return
    adaptive_timer = 1.25
    var fps: float = float(Engine.get_frames_per_second())
    var target: float = TARGET_SCALE[quality]
    var minimum: float = MIN_ADAPTIVE_SCALE[quality]
    var next_scale: float = render_scale
    if fps > 1.0 and fps < 48.0:
        next_scale = maxf(render_scale - 0.05, minimum)
    elif fps >= 57.0:
        next_scale = minf(render_scale + 0.025, target)
    if not is_equal_approx(next_scale, render_scale):
        render_scale = next_scale
        get_viewport().scaling_3d_scale = render_scale

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
    controls.context_label = "FALAR" if nearest != null else "AÇÃO"
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
            toast("Percurso concluído! +150 ryō.")
        elif GameFlow.progress.completed.has(data.mission):
            toast("Bom trabalho. O treinador na praça tem um desafio para você.")
        elif GameFlow.accept_mission(data.mission):
            toast("Recolha os três pergaminhos nos telhados e volte aqui. As escadas e o salto duplo ajudam no percurso.")
    elif data.kind == "battle":
        controls.release_all()
        var result: Error = GameFlow.start_battle(data.mission, actor.last_safe_position, actor.rotation.y)
        if result == OK:
            return
        toast("Não foi possível abrir o treino. Tente novamente.")
    elif data.kind == "shop":
        toast("Suprimento comprado para o próximo treino." if GameFlow.buy_supplies(int(data.price)) else String(data.text) + " Limite: 3. Saldo: %d ryō." % int(GameFlow.progress.ryo))
    else:
        toast(String(data.text))
    if not GameFlow.save_message.is_empty():
        toast(GameFlow.save_message)

func toast(text: String) -> void:
    message_label.text = text
    toast_timer = 6.0
    message_label.visible = true

func toggle_map() -> void:
    map_open = not map_open
    controls.release_all()
    actor.input_enabled = not map_open
    actor.velocity = Vector3.ZERO
    map_panel.visible = map_open
    map_panel.queue_redraw()
    context_label.visible = not map_open
