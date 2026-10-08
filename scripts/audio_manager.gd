extends Node
## Bounded SFX voices, preloaded offline; no runtime downloads or node churn.
const BANK: Dictionary = {
    "normal": preload("res://assets/audio/kenney/impactPunch_medium_000.ogg"),
    "heavy": preload("res://assets/audio/kenney/impactPunch_heavy_000.ogg"),
    "guard": preload("res://assets/audio/kenney/impactMetal_light_000.ogg"),
    "step": preload("res://assets/audio/kenney/footstep_concrete_000.ogg"),
    "grass": preload("res://assets/audio/kenney/footstep_grass_000.ogg"),
    "chakra": preload("res://assets/audio/kenney/forceField_000.ogg"),
    "dash": preload("res://assets/audio/kenney/thrusterFire_000.ogg"),
    "smoke": preload("res://assets/audio/kenney/explosionCrunch_000.ogg")
}
var voices: Array[AudioStreamPlayer3D] = []
var charge_voice: AudioStreamPlayer
var cursor: int = 0
var last_played: Dictionary = {}
var step_clock: Dictionary = {}
var muted: bool = false
var settings: ConfigFile = ConfigFile.new()
var muted_button: Button = null

func _ready() -> void:
    settings.load("user://audio.cfg")
    muted = bool(settings.get_value("audio", "muted", false))
    for index: int in range(8):
        var voice: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
        voice.max_polyphony = 1
        voice.unit_size = 6.0
        voice.max_distance = 45.0
        voice.panning_strength = 0.65
        add_child(voice)
        voices.append(voice)
    charge_voice = AudioStreamPlayer.new()
    var loop: AudioStreamOggVorbis = BANK.chakra.duplicate() as AudioStreamOggVorbis
    loop.loop = true
    charge_voice.stream = loop
    charge_voice.volume_db = -22.0
    add_child(charge_voice)
    var layer: CanvasLayer = CanvasLayer.new()
    layer.layer = 30
    add_child(layer)
    muted_button = Button.new()
    muted_button.position = Vector2(830, 12)
    muted_button.custom_minimum_size = Vector2(115, 46)
    muted_button.pressed.connect(toggle_mute)
    layer.add_child(muted_button)
    _refresh_button()

func play(kind: String, volume: float = -13.0) -> void:
    var actor: Node3D = get_parent().get_node_or_null("Player") as Node3D
    play_at(kind, actor.global_position if actor != null else Vector3.ZERO, volume)

func play_at(kind: String, origin: Vector3, volume: float = -13.0) -> void:
    if DisplayServer.get_name() == "headless" or muted or not BANK.has(kind) or voices.is_empty():
        return
    var now: int = Time.get_ticks_msec()
    var minimum: int = 500 if kind == "dash" else 80 if kind == "smoke" else 45
    if now - int(last_played.get(kind, -1000)) < minimum:
        return
    last_played[kind] = now
    var voice: AudioStreamPlayer3D = voices[cursor]
    cursor = (cursor + 1) % voices.size()
    voice.stop()
    voice.stream = BANK[kind]
    voice.global_position = origin
    voice.volume_db = clampf(volume, -35.0, -6.0)
    voice.pitch_scale = 1.0
    voice.play()

func _physics_process(delta: float) -> void:
    var charge: bool = false
    for title: String in ["Player", "EnemyDummy"]:
        var actor: CharacterBody3D = get_parent().get_node_or_null(title) as CharacterBody3D
        if actor == null:
            continue
        var charging: Variant = actor.get("is_charging_chakra")
        charge = charge or (charging != null and bool(charging))
        var motion: String = actor.call("get_animation_state")
        var clock: float = float(step_clock.get(title, 0.0)) - delta
        if actor.is_on_floor() and motion == "run" and Vector2(actor.velocity.x, actor.velocity.z).length() > 1.5:
            if clock <= 0.0:
                play_at("grass" if get_parent().scene_file_path == "res://world.tscn" else "step", actor.global_position, -24.0)
                clock = 0.29 if actor.velocity.length() > 9.0 else 0.41
        else:
            clock = 0.0
        step_clock[title] = clock
    if charge and not muted and DisplayServer.get_name() != "headless":
        if not charge_voice.playing:
            charge_voice.play()
    else:
        charge_voice.stop()

func toggle_mute() -> void:
    muted = not muted
    if muted:
        stop_all()
    settings.set_value("audio", "muted", muted)
    var result: Error = settings.save("user://audio.cfg")
    if result != OK:
        push_warning("Configuração de áudio não foi salva: " + error_string(result))
    _refresh_button()

func _refresh_button() -> void:
    muted_button.text = "SOM: OFF" if muted else "SOM: ON"

func stop_all() -> void:
    for voice: AudioStreamPlayer3D in voices:
        voice.stop()
    charge_voice.stop()

func _exit_tree() -> void:
    stop_all()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED and charge_voice != null:
        stop_all()
