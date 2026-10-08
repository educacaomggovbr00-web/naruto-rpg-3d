extends Node
## Small startup journal; no campaign data is removed during recovery.
const MARKER: String = "user://active_session.json"
const TRACE: String = "user://runtime_stability.log"
var recovered_session: bool = false
var exit_dialog: ConfirmationDialog

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().quit_on_go_back = false
    if OS.has_feature("android"):
        var previous_scene: String = "unknown"
        if FileAccess.file_exists(MARKER):
            var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(MARKER))
            if previous is Dictionary and previous.get("scene") is String:
                previous_scene = previous.scene
        recovered_session = recover_graphics(MARKER, "user://graphics.cfg")
        # Bounded log, useful with adb/run-as; never stores personal data.
        var log_file: FileAccess = FileAccess.open(TRACE, FileAccess.WRITE)
        if log_file != null:
            log_file.store_line("Shinobi Clash 0.10.0; interrupted: %s; previous scene: %s" % [recovered_session, previous_scene])
            log_file.store_line("renderer: %s" % RenderingServer.get_video_adapter_name())
        _mark_active()
        get_tree().scene_changed.connect(_scene_changed)

static func recover_graphics(marker_path: String, graphics_path: String) -> bool:
    if not FileAccess.file_exists(marker_path): return false
    var graphics: ConfigFile = ConfigFile.new()
    graphics.load(graphics_path)
    graphics.set_value("graphics", "quality", 0)
    var result: Error = graphics.save(graphics_path)
    if result != OK:
        push_warning("Não foi possível ativar o modo leve: %s" % error_string(result))
    return result == OK

func _mark_active() -> void:
    if not OS.has_feature("android"): return
    var file: FileAccess = FileAccess.open(MARKER, FileAccess.WRITE)
    if file != null:
        var current: Node = get_tree().current_scene
        file.store_string(JSON.stringify({"scene": current.scene_file_path if current != null else "startup"}))

func record_loading(path: String) -> void:
    if not OS.has_feature("android"): return
    var file: FileAccess = FileAccess.open(MARKER, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify({"scene": "loading:" + path}))

func _scene_changed() -> void:
    if GameFlow.busy and GameFlow.loading_screen.active and get_tree().current_scene.scene_file_path != GameFlow.loading_screen.pending_path:
        return
    _mark_active()
    var file: FileAccess = FileAccess.open(TRACE, FileAccess.READ_WRITE)
    if file != null:
        if file.get_length() > 65536:
            file.close()
            file = FileAccess.open(TRACE, FileAccess.WRITE)
            if file == null: return
        file.seek_end()
        file.store_line("scene: %s; static memory: %d" % [get_tree().current_scene.scene_file_path, OS.get_static_memory_usage()])

func _clear_marker() -> void:
    if FileAccess.file_exists(MARKER):
        DirAccess.remove_absolute(MARKER)

func request_back() -> void:
    if GameFlow.busy: return
    var current: Node = get_tree().current_scene
    if current == null: return
    if current.scene_file_path != "res://selection.tscn":
        # Preserve the exploration checkpoint before navigating away.
        GameFlow.notification(NOTIFICATION_APPLICATION_PAUSED)
        get_tree().paused = false
        Engine.time_scale = 1.0
        GameFlow.enter_selection()
        return
    if exit_dialog == null:
        exit_dialog = ConfirmationDialog.new()
        exit_dialog.title = "Sair do Shinobi Clash?"
        exit_dialog.dialog_text = "Seu progresso salvo será mantido."
        exit_dialog.ok_button_text = "SAIR"
        exit_dialog.cancel_button_text = "CONTINUAR"
        add_child(exit_dialog)
        exit_dialog.confirmed.connect(func() -> void:
            _clear_marker()
            get_tree().quit())
    exit_dialog.popup_centered(Vector2i(360, 160))

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        request_back()
    elif what == NOTIFICATION_APPLICATION_PAUSED:
        # Android can legitimately reclaim a background app; do not call that
        # a crash or reset its chosen quality at the next normal launch.
        _clear_marker()
    elif what == NOTIFICATION_APPLICATION_RESUMED:
        _mark_active()

func _exit_tree() -> void:
    _clear_marker()
