class_name GraphicsPreferences
extends RefCounted
## One persisted render preference for selection, combat and every exploration region.
const PATH: String = "user://graphics.cfg"
const LABELS: PackedStringArray = ["Leve", "Equilibrada", "Alta"]

static func default_level() -> int:
    return 0 if OS.has_feature("android") else 1

static func read_quality(config: ConfigFile = null) -> int:
    var settings: ConfigFile = config if config != null else ConfigFile.new()
    if config == null: settings.load(PATH)
    var value: Variant = settings.get_value("graphics", "quality", default_level())
    if not (value is int or value is float): return default_level()
    if not is_finite(float(value)): return default_level()
    return clampi(int(value), 0, 2)

static func save_quality(level: int) -> Error:
    if level < 0 or level > 2: return ERR_INVALID_PARAMETER
    var settings: ConfigFile = ConfigFile.new()
    settings.load(PATH)
    settings.set_value("graphics", "quality", level)
    var result: Error = settings.save(PATH + ".tmp")
    if result != OK: return result
    return DirAccess.rename_absolute(PATH + ".tmp", PATH)
