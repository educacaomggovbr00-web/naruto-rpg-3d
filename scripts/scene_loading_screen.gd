extends CanvasLayer
## Owns only a 2D loading screen. Releases the old scene before loading its replacement.
signal resources_requested(path: String)
signal failed(path: String, error: Error)
signal retry_requested(path: String)
signal menu_requested
var generation: int = 0
var active: bool = false
var pending_path: String = ""
var backdrop: ColorRect
var heading: Label
var phase_label: Label
var progress_bar: ProgressBar
var tip: Label
var actions: HBoxContainer

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 100
    backdrop = ColorRect.new()
    backdrop.color = Color("07121e")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(backdrop)
    var center: CenterContainer = CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.add_child(center)
    var panel: PanelContainer = PanelContainer.new()
    panel.custom_minimum_size = Vector2(540, 0)
    center.add_child(panel)
    var margin: MarginContainer = MarginContainer.new()
    for side: String in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 24)
    panel.add_child(margin)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 16)
    margin.add_child(column)
    var brand: Label = Label.new()
    brand.text = "SHINOBI CLASH"
    brand.add_theme_font_size_override("font_size", 30)
    brand.add_theme_color_override("font_color", Color("ffd27a"))
    column.add_child(brand)
    heading = Label.new()
    heading.add_theme_font_size_override("font_size", 22)
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(heading)
    phase_label = Label.new()
    phase_label.add_theme_font_size_override("font_size", 14)
    column.add_child(phase_label)
    progress_bar = ProgressBar.new()
    progress_bar.custom_minimum_size.y = 12
    progress_bar.show_percentage = false
    var fill: StyleBoxFlat = StyleBoxFlat.new()
    fill.bg_color = Color("e8ad50")
    fill.set_corner_radius_all(6)
    progress_bar.add_theme_stylebox_override("fill", fill)
    var track: StyleBoxFlat = StyleBoxFlat.new()
    track.bg_color = Color("102737")
    track.set_corner_radius_all(6)
    progress_bar.add_theme_stylebox_override("background", track)
    column.add_child(progress_bar)
    tip = Label.new()
    tip.custom_minimum_size.x = 490
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tip.add_theme_font_size_override("font_size", 14)
    tip.add_theme_color_override("font_color", Color("98b9cb"))
    column.add_child(tip)
    actions = HBoxContainer.new()
    actions.add_theme_constant_override("separation", 12)
    column.add_child(actions)
    var retry: Button = Button.new()
    retry.text = "TENTAR NOVAMENTE"
    retry.pressed.connect(func() -> void: retry_requested.emit(pending_path))
    actions.add_child(retry)
    var menu: Button = Button.new()
    menu.text = "VOLTAR AO MENU"
    menu.pressed.connect(func() -> void: menu_requested.emit())
    actions.add_child(menu)
    hide()

func begin(path: String, title: String) -> void:
    generation += 1
    active = true
    pending_path = path
    heading.text = title
    phase_label.text = "Preparando sua jornada…"
    tip.text = "Defenda para abrir espaço. Use chakra dash para encurtar a distância."
    progress_bar.value = 0
    actions.hide()
    show()
    call_deferred("_load_scene", path, generation)

func _load_scene(path: String, request: int) -> void:
    # Let the overlay draw first; never delete the node whose input/physics
    # callback requested the transition on that callback's own stack.
    await get_tree().process_frame
    if request != generation: return
    var previous: Node = get_tree().current_scene
    if previous != null:
        previous.process_mode = Node.PROCESS_MODE_DISABLED
        previous.queue_free()
    previous = null
    await get_tree().process_frame
    await get_tree().process_frame
    if request != generation: return
    # Deferred renderer cleanup must finish before allocating the replacement.
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
    phase_label.text = "Carregando o cenário…"
    resources_requested.emit(path)
    progress_bar.value = 25
    await get_tree().process_frame
    var scene: PackedScene = ResourceLoader.load(path, "PackedScene") as PackedScene
    if scene == null:
        _fail(path, ERR_CANT_OPEN, request)
        return
    progress_bar.value = 75
    phase_label.text = "Preparando os personagens…"
    await get_tree().process_frame
    var result: Error = get_tree().change_scene_to_packed(scene)
    if result != OK: _fail(path, result, request)

func finish() -> void:
    progress_bar.value = 100
    var request: int = generation
    await get_tree().physics_frame
    await get_tree().process_frame
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
    await get_tree().process_frame
    if request != generation: return
    active = false
    hide()

func _fail(path: String, error: Error, request: int) -> void:
    if request != generation: return
    active = false
    heading.text = "Não foi possível abrir o cenário"
    phase_label.text = "Você pode tentar novamente ou voltar ao menu."
    tip.text = "Seu progresso salvo foi mantido."
    actions.show()
    failed.emit(path, error)
