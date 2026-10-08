extends Node
## Preferences are separate from campaign saves; changing them never resets progress.
signal changed

const PATH: String = "user://controls.cfg"
const DIFFICULTIES: PackedStringArray = ["FÁCIL", "NORMAL", "DIFÍCIL"]
var camera_sensitivity: float = 1.0
var controls_scale: float = 1.0
var controls_opacity: float = 1.0
var camera_shake: bool = true
var difficulty: int = 1
var training_behavior: int = 0
var config_path: String = PATH

func _ready() -> void:
    load_preferences()
    _register_gamepad()
    if FileAccess.file_exists(PATH) and not FileAccess.file_exists(CombatSettings.PATH):
        CombatSettings.camera_sensitivity = camera_sensitivity
        CombatSettings.camera_shake = 1.0 if camera_shake else 0.0
        CombatSettings.difficulty = difficulty

func load_preferences() -> void:
    var config: ConfigFile = ConfigFile.new()
    if config.load(config_path) != OK:
        return
    camera_sensitivity = _bounded(config.get_value("controls", "sensitivity", 1.0), 0.5, 2.0)
    controls_scale = _bounded(config.get_value("controls", "scale", 1.0), 0.8, 1.15)
    controls_opacity = _bounded(config.get_value("controls", "opacity", 1.0), 0.4, 1.0)
    camera_shake = bool(config.get_value("controls", "shake", true))
    difficulty = clampi(int(config.get_value("battle", "difficulty", 1)), 0, 2)
    training_behavior = clampi(int(config.get_value("battle", "training", 0)), 0, 2)

func _bounded(value: Variant, low: float, high: float) -> float:
    if not (value is float or value is int) or not is_finite(float(value)):
        return 1.0
    return clampf(float(value), low, high)

func save_preferences() -> Error:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("controls", "sensitivity", camera_sensitivity)
    config.set_value("controls", "scale", controls_scale)
    config.set_value("controls", "opacity", controls_opacity)
    config.set_value("controls", "shake", camera_shake)
    config.set_value("battle", "difficulty", difficulty)
    config.set_value("battle", "training", training_behavior)
    var result: Error = config.save(config_path)
    if config_path == PATH:
        CombatSettings.camera_sensitivity = camera_sensitivity
        CombatSettings.camera_shake = 1.0 if camera_shake else 0.0
        CombatSettings.save_preferences()
    changed.emit()
    return result

func cpu_profile(base: AIProfileDefinition) -> AIProfileDefinition:
    var profile: AIProfileDefinition = base.duplicate() as AIProfileDefinition
    var speed: float = [0.65, 1.0, 1.30][difficulty]
    profile.decision_speed *= speed
    profile.aggression = clampf(profile.aggression * [0.65, 1.0, 1.18][difficulty], 0.1, 0.95)
    profile.jutsu_bias = clampf(profile.jutsu_bias * [0.55, 1.0, 1.25][difficulty], 0.0, 0.9)
    profile.dash_bias = clampf(profile.dash_bias * [0.55, 1.0, 1.25][difficulty], 0.0, 0.9)
    profile.ultimate_bias *= [0.4, 1.0, 1.4][difficulty]
    return profile

func gamepad_move() -> Vector2:
    return CombatSettings.movement()

func gamepad_camera() -> Vector2:
    return Input.get_vector("pad_camera_left", "pad_camera_right", "pad_camera_up", "pad_camera_down")

func _register_gamepad() -> void:
    # CombatSettings installs the canonical team-compatible button mappings.
    if not InputMap.has_action("pad_run"):
        InputMap.add_action("pad_run", .18)
        var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
        event.axis = JOY_AXIS_TRIGGER_RIGHT
        event.axis_value = 1.0
        InputMap.action_add_event("pad_run", event)
