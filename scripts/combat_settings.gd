extends Node
## Local preferences are separate from campaign saves; malformed files are kept.
const PATH: String = "user://combat_settings.json"
const DIFFICULTIES: PackedStringArray = ["Treino", "Normal", "Difícil", "Jounin"]
var difficulty: int = 1
var henrique_outfit: int = 1
var controller_deadzone: float = 0.18
var master_volume: float = 0.8
var writable: bool = true
var touch_layout: Dictionary = {}
const TOUCH_KEYS: PackedStringArray = ["joystick", "attack", "jump", "dash", "jutsu", "substitution", "dodge", "charge", "guard"]

func _ready() -> void:
    _load_preferences()
    _install_controller_actions()
    apply_audio()

func _load_preferences() -> void:
    if not FileAccess.file_exists(PATH):
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    if not parsed is Dictionary:
        writable = false
        return
    var data: Dictionary = parsed
    if int(data.get("version", -1)) != 1 or not data.get("difficulty") is float or not data.get("deadzone") is float or not data.get("volume") is float:
        writable = false
        return
    if float(data.difficulty) != floorf(float(data.difficulty)) or float(data.difficulty) < 0 or float(data.difficulty) > 3 or not is_finite(float(data.deadzone)) or not is_finite(float(data.volume)):
        writable = false
        return
    var layout: Variant = data.get("touch_layout", {})
    if layout is Dictionary:
        for key: String in TOUCH_KEYS:
            var point: Variant = layout.get(key)
            if point is Array and point.size() == 2 and point[0] is float and point[1] is float:
                if is_finite(float(point[0])) and is_finite(float(point[1])) and float(point[0]) >= 0 and float(point[0]) <= 1 and float(point[1]) >= 0 and float(point[1]) <= 1:
                    touch_layout[key] = point.duplicate()
    var outfit: Variant = data.get("henrique_outfit", 1.0)
    if (outfit is float or outfit is int) and is_finite(float(outfit)):
        henrique_outfit = clampi(int(outfit), 0, 2)
    difficulty = int(data.difficulty)
    controller_deadzone = clampf(float(data.deadzone), 0.1, 0.4)
    master_volume = clampf(float(data.volume), 0.0, 1.0)

func save_preferences() -> Error:
    if not writable:
        return ERR_FILE_UNRECOGNIZED
    var file: FileAccess = FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify({"version":1,"difficulty":difficulty,"deadzone":controller_deadzone,"volume":master_volume,"touch_layout":touch_layout,"henrique_outfit":henrique_outfit}))
    file.close()
    return DirAccess.rename_absolute(PATH + ".tmp", PATH)

func apply_audio() -> void:
    AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
    AudioServer.set_bus_mute(0, master_volume <= 0.0)

func profile_for(source: AIProfileDefinition) -> AIProfileDefinition:
    var profile: AIProfileDefinition = source.duplicate(true) as AIProfileDefinition
    # Difficulty changes decisions and reaction frequency, never health/damage.
    var speed: float = [0.65, 1.0, 1.3, 1.6][difficulty]
    var defense: float = [0.35, 1.0, 1.25, 1.5][difficulty]
    profile.decision_speed *= speed
    profile.guard_bias = minf(profile.guard_bias * defense, 0.45)
    profile.dodge_bias = minf(profile.dodge_bias * defense, 0.40)
    profile.jutsu_bias = minf(profile.jutsu_bias * [0.35, 1.0, 1.15, 1.3][difficulty], 0.8)
    profile.aggression = clampf(profile.aggression * [0.55, 1.0, 1.10, 1.18][difficulty], 0.1, 0.95)
    profile.dash_bias *= [0.4, 1.0, 1.1, 1.2][difficulty]
    profile.projectile_reaction = [0.25, 0.70, 0.80, 0.87][difficulty]
    profile.substitution_chance = [0.0, 0.18, 0.25, 0.33][difficulty]
    profile.reaction_delay = [0.28, 0.14, 0.12, 0.10][difficulty]
    return profile

func _install_controller_actions() -> void:
    var buttons: Dictionary = {"pad_attack":JOY_BUTTON_X,"pad_jump":JOY_BUTTON_A,"pad_jutsu":JOY_BUTTON_Y,"pad_dash":JOY_BUTTON_B,"pad_guard":JOY_BUTTON_LEFT_SHOULDER,"pad_charge":JOY_BUTTON_RIGHT_SHOULDER,"pad_substitution":JOY_BUTTON_DPAD_DOWN,"pad_dodge":JOY_BUTTON_DPAD_LEFT,"pad_lock":JOY_BUTTON_RIGHT_STICK,"pad_ultimate":JOY_BUTTON_DPAD_UP,"pad_awakening":JOY_BUTTON_DPAD_RIGHT}
    for action: String in buttons:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            var event: InputEventJoypadButton = InputEventJoypadButton.new()
            event.button_index = buttons[action]
            InputMap.action_add_event(action, event)
    var axes: Dictionary = {"pad_left":[JOY_AXIS_LEFT_X,-1.0],"pad_right":[JOY_AXIS_LEFT_X,1.0],"pad_forward":[JOY_AXIS_LEFT_Y,-1.0],"pad_back":[JOY_AXIS_LEFT_Y,1.0],"pad_camera_left":[JOY_AXIS_RIGHT_X,-1.0],"pad_camera_right":[JOY_AXIS_RIGHT_X,1.0],"pad_camera_up":[JOY_AXIS_RIGHT_Y,-1.0],"pad_camera_down":[JOY_AXIS_RIGHT_Y,1.0]}
    for action: String in axes:
        if not InputMap.has_action(action):
            InputMap.add_action(action, controller_deadzone)
            var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
            event.axis = int(axes[action][0])
            event.axis_value = float(axes[action][1])
            InputMap.action_add_event(action, event)
        InputMap.action_set_deadzone(action, controller_deadzone)

func movement() -> Vector2:
    return Input.get_vector("pad_left", "pad_right", "pad_forward", "pad_back", controller_deadzone)
