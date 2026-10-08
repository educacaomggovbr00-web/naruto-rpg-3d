extends Node
## Bounded SFX voices, preloaded offline; no runtime downloads or node churn.
const BANK: Dictionary = {
    "jutsu_fire": preload("res://assets/audio/original/jutsu_fire.wav"),
    "jutsu_lightning": preload("res://assets/audio/original/jutsu_lightning.wav"),
    "jutsu_water": preload("res://assets/audio/original/jutsu_water.wav"),
    "normal": preload("res://assets/audio/kenney/impactPunch_medium_000.ogg"),
    "heavy": preload("res://assets/audio/kenney/impactPunch_heavy_000.ogg"),
    "guard": preload("res://assets/audio/kenney/impactMetal_light_000.ogg"),
    "step": preload("res://assets/audio/kenney/footstep_concrete_000.ogg"),
    "grass": preload("res://assets/audio/kenney/footstep_grass_000.ogg"),
    "chakra": preload("res://assets/audio/kenney/forceField_000.ogg"),
    "dash": preload("res://assets/audio/kenney/thrusterFire_000.ogg"),
    "smoke": preload("res://assets/audio/kenney/explosionCrunch_000.ogg")
}
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var charge_voice: AudioStreamPlayer
var cursor: int = 0
var last_played: Dictionary = {}
var step_clock: Dictionary = {}
var muted: bool = false
var settings: ConfigFile = ConfigFile.new()
var muted_button: Button = null

func _ready() -> void:
    music = AudioStreamPlayer.new()
    add_child(music)
    var theme: String = "exploration" if get_parent().scene_file_path.ends_with("world.tscn") else "boss" if GameFlow.arcade_mode == "boss" else "battle"
    var track: AudioStreamWAV = load("res://assets/audio/original/" + theme + ".wav").duplicate() as AudioStreamWAV
    track.loop_mode = AudioStreamWAV.LOOP_FORWARD
    track.loop_end = roundi(track.get_length() * track.mix_rate)
    music.stream = track
    music.volume_db = -19.0
    settings.load("user://audio.cfg")
    muted = bool(settings.get_value("audio", "muted", false))
    if not muted and DisplayServer.get_name() != "headless":
        music.play()
    for index: int in range(8):
        var voice: AudioStreamPlayer = AudioStreamPlayer.new()
        voice.max_polyphony = 1
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
    if DisplayServer.get_name() == "headless" or muted or not BANK.has(kind) or voices.is_empty():
        return
    var now: int = Time.get_ticks_msec()
    var minimum: int = 500 if kind == "dash" else 80 if kind == "smoke" else 45
    if now - int(last_played.get(kind, -1000)) < minimum:
        return
    last_played[kind] = now
    var voice: AudioStreamPlayer = voices[cursor]
    cursor = (cursor + 1) % voices.size()
    voice.stop()
    voice.stream = BANK[kind]
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
                play("grass" if get_parent().scene_file_path == "res://world.tscn" else "step", -24.0)
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
    if music != null:
        music.volume_db = -80.0 if muted else -19.0
        if not muted and not music.playing and DisplayServer.get_name() != "headless":
            music.play()
    muted_button.text = "SOM: OFF" if muted else "SOM: ON"

func stop_all() -> void:
    for voice: AudioStreamPlayer in voices:
        voice.stop()
    charge_voice.stop()

func _exit_tree() -> void:
    stop_all()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED and charge_voice != null:
        stop_all()
