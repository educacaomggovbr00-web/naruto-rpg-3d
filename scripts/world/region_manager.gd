extends Node3D

var quality: int = 1
var status_label: Label
var mission_label: Label
var fps_label: Label
var mission_button: Button
var back_button: Button
var quality_button: Button
var toast_label: Label
var toast_timer: float = 0.0
var settings: ConfigFile = ConfigFile.new()

@onready var actor: CharacterBody3D = $Player
@onready var controls: Control = $HUD/WorldControls
@onready var geometry: Node3D = $Geometry

func _ready() -> void:
    var presentation: Script = preload("res://scripts/anime_presentation.gd")
    $Environment.environment = presentation.environment(false, $Environment.environment)
    presentation.sun($Sun)
    actor.global_position = _spawn_for_region(GameFlow.world_region)
    actor.rotation.y = PI
    actor.last_safe_position = actor.global_position
    actor.camera_rig.yaw = actor.rotation.y + PI
    actor.camera_rig.focus = actor.global_position + Vector3.UP * 0.8
    actor.camera_rig.global_position = actor.camera_rig.focus
    _build_hud()
    GameFlow.progress_changed.connect(_refresh_hud)
    settings.load("user://graphics.cfg")
    apply_quality(clampi(int(settings.get_value("graphics", "quality", 1)), 0, 2), false)
    _refresh_hud()

func _spawn_for_region(region_id: String) -> Vector3:
    match region_id:
        "river":
            return Vector3(-20, 0.95, 34)
        "valley":
            return Vector3(0, 0.95, 36)
        _:
            return Vector3(0, 0.95, 36)

func _panel_style(background: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    return style

func _make_button(title: String, position: Vector2, width: float) -> Button:
    var button: Button = Button.new()
    button.text = title
    button.position = position
    button.custom_minimum_size = Vector2(width, 44)
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.10, 0.13, 0.90), Color(0.35, 0.68, 0.70, 0.65)))
    button.add_theme_stylebox_override("pressed", _panel_style(Color(0.04, 0.16, 0.19, 0.96), Color("d9903d")))
    $HUD.add_child(button)
    return button

func _build_hud() -> void:
    status_label = Label.new()
    status_label.position = Vector2(18, 14)
    status_label.size = Vector2(720, 32)
    status_label.add_theme_font_size_override("font_size", 22)
    status_label.add_theme_color_override("font_color", Color("ffe0a0"))
    $HUD.add_child(status_label)

    mission_label = Label.new()
    mission_label.position = Vector2(18, 48)
    mission_label.size = Vector2(760, 54)
    mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mission_label.add_theme_font_size_override("font_size", 15)
    mission_label.add_theme_color_override("font_color", Color("e4eeee"))
    $HUD.add_child(mission_label)

    mission_button = _make_button("MISSÃO", Vector2(18, 108), 180)
    mission_button.pressed.connect(start_story)

    back_button = _make_button("VOLTAR À FOLHA", Vector2(208, 108), 190)
    back_button.pressed.connect(GameFlow.enter_world)

    quality_button = _make_button("MED", Vector2(408, 108), 90)
    quality_button.pressed.connect(func() -> void: apply_quality((quality + 1) % 3))

    fps_label = Label.new()
    fps_label.position = Vector2(920, 18)
    fps_label.size = Vector2(240, 28)
    fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    fps_label.add_theme_font_size_override("font_size", 13)
    fps_label.add_theme_color_override("font_color", Color("c8dde3"))
    $HUD.add_child(fps_label)

    toast_label = Label.new()
    toast_label.position = Vector2(260, 590)
    toast_label.size = Vector2(760, 70)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast_label.add_theme_font_size_override("font_size", 18)
    toast_label.add_theme_color_override("font_color", Color("ffe3a8"))
    $HUD.add_child(toast_label)

func _refresh_hud() -> void:
    GameFlow.ensure_rpg_progress()
    status_label.text = "%s • NÍVEL %d • %s • %d ryō" % [
        StoryCampaign.region_label(GameFlow.world_region).to_upper(),
        int(GameFlow.progress.level),
        GameFlow.ninja_rank(),
        int(GameFlow.progress.ryo)
    ]
    var mission: Dictionary = GameFlow.current_story_mission()
    if mission.is_empty():
        mission_label.text = "Campanha Parte 1 concluída. Explore, treine ou retorne à Folha."
        mission_button.disabled = true
        mission_button.text = "CONCLUÍDO"
        return
    var target_region: String = String(mission.get("region", "konoha"))
    mission_label.text = GameFlow.story_objective_text() + "\n" + String(mission.get("summary", ""))
    mission_button.disabled = target_region != GameFlow.world_region
    mission_button.text = "INICIAR MISSÃO" if not mission_button.disabled else "MISSÃO EM " + StoryCampaign.region_label(target_region).to_upper()

func start_story() -> void:
    var mission: Dictionary = GameFlow.current_story_mission()
    if mission.is_empty():
        toast("A campanha Parte 1 já foi concluída.")
        return
    var target_region: String = String(mission.get("region", "konoha"))
    if target_region != GameFlow.world_region:
        toast("Esta missão começa em " + StoryCampaign.region_label(target_region) + ".")
        return
    controls.release_all()
    var result: Error = GameFlow.start_story_battle()
    if result != OK:
        toast("Não foi possível abrir a missão.")

func apply_quality(level: int, save: bool = true) -> void:
    quality = clampi(level, 0, 2)
    get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
    get_viewport().scaling_3d_scale = [0.58, 0.74, 0.90][quality]
    $Sun.shadow_enabled = quality > 0
    $Sun.directional_shadow_max_distance = [0.0, 18.0, 28.0][quality]
    $Environment.environment.fog_enabled = quality > 0
    geometry.call("set_quality", quality)
    quality_button.text = ["LOW", "MED", "HIGH"][quality]
    if save:
        settings.set_value("graphics", "quality", quality)
        settings.save("user://graphics.cfg")

func _physics_process(delta: float) -> void:
    toast_timer = maxf(toast_timer - delta, 0.0)
    toast_label.visible = toast_timer > 0.0
    fps_label.text = "%d FPS • %s • %d DC" % [
        Engine.get_frames_per_second(),
        ["LOW", "MED", "HIGH"][quality],
        int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    ]

    if controls.map_queue > 0:
        controls.map_queue = 0
        GameFlow.enter_world()
        return
    if controls.interact_queue > 0:
        controls.interact_queue = 0
        start_story()

func toast(message: String) -> void:
    toast_label.text = message
    toast_timer = 5.0
    toast_label.visible = true
